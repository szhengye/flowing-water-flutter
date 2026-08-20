import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chain/unmatched_retry_service.dart';
import 'config/app_config.dart';
import 'crypto/secure_vault.dart';
import 'db/database.dart';
import 'db/provider_chain_settlement_dao.dart';
import 'db/provider_log_dao.dart';
import 'db/quotation_dao.dart';
import 'db/unmatched_settled_event_dao.dart';
import 'log/node_logger.dart';
import 'relay/node_service.dart';

/// 全局配置 —— `--dart-define` 注入(wayfinder 07:网络选择器 + 可编辑 RPC)。
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

/// 应用数据库单例 —— 自动 close on dispose。各阶段 DAO/查询经此 provider 取库。
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// OS 安全存储(macOS Keychain)—— 存身份自动恢复的解锁凭证(wayfinder 07)。
/// 测试可 override 为内存 fake(SecureVault)。
final secureVaultProvider = Provider<SecureVault>((ref) => const KeychainVault());

/// provider_log DAO(07:关联流水 sheet 跨 Settlements/Wallet 复用)。
final providerLogDaoProvider = Provider<ProviderLogDao>(
  (ref) => ProviderLogDao(ref.watch(appDatabaseProvider)),
);

/// provider_chain_settlement DAO(07:Settlements 页)。
final providerChainSettlementDaoProvider = Provider<ProviderChainSettlementDao>(
  (ref) => ProviderChainSettlementDao(ref.watch(appDatabaseProvider)),
);

// ───────── 04 Dashboard / Records ─────────

/// Dashboard 周期(24h/7d/30d/lifetime);切换驱动 metrics 重算。
enum DashboardPeriod {
  day(Duration(hours: 24), '24h'),
  week(Duration(days: 7), '7d'),
  month(Duration(days: 30), '30d'),
  lifetime(Duration.zero, '累计');

  const DashboardPeriod(this.window, this.label);
  final Duration window;
  final String label;

  /// createdAt 下界(epoch 秒);lifetime → 0。
  int since(int nowEpochSec) =>
      this == DashboardPeriod.lifetime ? 0 : nowEpochSec - window.inSeconds;
}

final dashboardPeriodProvider = StateProvider<DashboardPeriod>(
  (ref) => DashboardPeriod.day,
);

/// Dashboard LLM 指标(04):周期内 provider_log 聚合,drift watch 反应式刷新。
final dashboardMetricsProvider = StreamProvider<LlmMetrics>((ref) {
  final period = ref.watch(dashboardPeriodProvider);
  final since = period.since(DateTime.now().millisecondsSinceEpoch ~/ 1000);
  return ref
      .watch(providerLogDaoProvider)
      .watchRecordsSince(since)
      .map(computeLlmMetrics);
});

/// Records 筛选(04):null = 该维度全部。
final recordsProcessingStatusProvider = StateProvider<String?>((ref) => null);
final recordsChainStatusProvider = StateProvider<String?>((ref) => null);

/// Records 流水列表(04):按筛选反应式(createdAt 倒序)。
final recordsListProvider = StreamProvider<List<ProviderLogRow>>((ref) {
  return ref.watch(providerLogDaoProvider).watchRecords(
        processingStatus: ref.watch(recordsProcessingStatusProvider),
        chainStatus: ref.watch(recordsChainStatusProvider),
      );
});

/// 链上结算汇总(04 Dashboard 链上面板):累计笔数 + 累计应收 USDT(raw 6-dec)。
class ChainSummary {
  const ChainSummary({required this.count, required this.receivedUsdtRaw});
  final int count;
  final int receivedUsdtRaw;
  static const ChainSummary empty = ChainSummary(count: 0, receivedUsdtRaw: 0);
}

final chainSettlementSummaryProvider = StreamProvider<ChainSummary>((ref) {
  return ref.watch(providerChainSettlementDaoProvider).watchAll().map((rows) {
    var total = 0;
    for (final r in rows) {
      total += int.tryParse(r.receivedUsdt) ?? 0;
    }
    return ChainSummary(count: rows.length, receivedUsdtRaw: total);
  });
});

/// provider_quotation DAO(12 厂商汇总 join 用)。
final quotationDaoProvider = Provider<QuotationDao>(
  (ref) => QuotationDao(ref.watch(appDatabaseProvider)),
);

/// Dashboard 厂商明细(12):周期内按上游厂商聚合收益/调用。先取 relayModel→vendor
/// 映射(quotation+vendor join),再 map 行流;provider 重建(周期变)时重取映射。
final dashboardVendorBreakdownProvider =
    StreamProvider<List<VendorBreakdown>>((ref) async* {
  final period = ref.watch(dashboardPeriodProvider);
  final since = period.since(DateTime.now().millisecondsSinceEpoch ~/ 1000);
  final map = await ref.watch(quotationDaoProvider).relayModelToVendorMap();
  yield* ref
      .watch(providerLogDaoProvider)
      .watchRecordsSince(since)
      .map((rows) => computeVendorBreakdown(rows, map));
});

// ───────── 09 unmatched Settled 事件 operator 重试 ─────────

/// unmatched_settled_events DAO(09:Settings 未匹配事件区)。
final unmatchedSettledEventDaoProvider = Provider<UnmatchedSettledEventDao>(
  (ref) => UnmatchedSettledEventDao(ref.watch(appDatabaseProvider)),
);

/// operator 手动重试编排(09)。relay client supplier 实时取自 NodeService
/// (与 ChainWatcherService._start 的 syncer 同源);未连接 → null → 整体跳过。
final unmatchedRetryServiceProvider = Provider<UnmatchedRetryService>((ref) {
  return UnmatchedRetryService(
    unmatchedDao: ref.watch(unmatchedSettledEventDaoProvider),
    providerLogDao: ref.watch(providerLogDaoProvider),
    relayQueryClient: () => ref.read(nodeServiceProvider.notifier).relayQueryClient,
    log: (m) => nodeLog.info('[unmatched-retry] $m'),
  );
});
