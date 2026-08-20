import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web3dart/web3dart.dart';

import '../config/app_config.dart';
import '../crypto/identity_controller.dart';
import '../db/chain_sync_cursor_dao.dart';
import '../db/provider_chain_settlement_dao.dart';
import '../db/provider_log_dao.dart';
import '../db/unmatched_settled_event_dao.dart';
import '../log/node_logger.dart';
import '../providers.dart';
import '../relay/node_service.dart';
import 'chain_client.dart';
import 'polygon_event_watcher.dart';
import 'settle_event_syncer.dart';

/// 链监听可观测状态。
enum ChainWatcherStatus { stopped, running, reconnecting, disabled }

class ChainWatcherState {
  const ChainWatcherState({required this.status, this.reason});
  final ChainWatcherStatus status;
  final String? reason; // disabled 时的原因
  bool get isRunning => status == ChainWatcherStatus.running;
}

/// 链上事件监听编排:按身份启停 [PolygonEventWatcher](镜像 NodeService 范式)。
///
/// - 身份 **unlocked** 且 Polygon 配置齐全 → 起 watcher 监听 Settled。
/// - 身份 **locked / none** → 停 watcher。
/// - Polygon RPC/合约未配置(dev 默认空)→ **disabled**(不重连)。
///
/// keepAlive;身份变化触发重建,旧 watcher 随 [ref.onDispose] 释放。[_gen] 守卫
/// 防止「加载期间身份又变」的旧启动落地。AppShell watch [chainWatcherStatusProvider]
/// 即激活本服务(用户进后台才开始监听链)。
class ChainWatcherService extends Notifier<ChainWatcherState> {
  PolygonEventWatcher? _watcher;
  int _gen = 0;

  @override
  ChainWatcherState build() {
    ref.keepAlive();
    _gen++;
    final myGen = _gen;
    ref.onDispose(() => unawaited(_watcher?.dispose()));

    final identity = ref.watch(identityControllerProvider).valueOrNull;
    // 身份未解锁(或加载中)→ 停(也停掉上一 unlocked 态建的 watcher)。
    if (identity == null || !identity.isUnlocked) {
      unawaited(_stop(myGen));
      return const ChainWatcherState(status: ChainWatcherStatus.stopped);
    }
    // 配置缺失(dev 默认空)→ disabled:不建 client、不重连。
    // 在 build 同步判定,避免 _start 的同步段与 build 的 return 竞态覆盖。
    final cfg = ref.read(appConfigProvider);
    if (cfg.polygonRpcUrl.isEmpty || cfg.polygonContractAddress.isEmpty) {
      return const ChainWatcherState(
        status: ChainWatcherStatus.disabled,
        reason: 'Polygon RPC / 合约未配置',
      );
    }
    unawaited(_start(identity, cfg, myGen));
    return const ChainWatcherState(status: ChainWatcherStatus.running);
  }

  Future<void> _start(IdentityState identity, AppConfig cfg, int gen) async {
    if (gen != _gen) return;
    final db = ref.read(appDatabaseProvider);
    final buildClient = ref.read(chainClientFactoryProvider);
    final addressHex = identity.addressEip55!;
    final syncer = SettleEventSyncer(
      // 实时取 relay 反查 client(随 NodeService 连通/断开);未连接 → null → unmatched。
      relayQueryClient: () =>
          ref.read(nodeServiceProvider.notifier).relayQueryClient,
      providerLogDao: ProviderLogDao(db),
      unmatchedDao: UnmatchedSettledEventDao(db),
      log: (m) => nodeLog.info('[chain-syncer] $m'),
    );
    _watcher = PolygonEventWatcher(
      clientFactory: () => buildClient(cfg),
      settlementDao: ProviderChainSettlementDao(db),
      cursorDao: ChainSyncCursorDao(db),
      providerAddress: () => EthereumAddress.fromHex(addressHex),
      contractAddress: EthereumAddress.fromHex(cfg.polygonContractAddress),
      deployBlock: cfg.polygonDeployBlock,
      onPhase: _onPhase(gen),
      syncer: syncer,
    );
    await _watcher!.start();
  }

  /// 相位 → 状态映射(带 gen 守卫:旧启动的回调不污染当前状态)。
  void Function(ChainWatchPhase) _onPhase(int gen) => (p) {
        if (gen != _gen) return;
        state = ChainWatcherState(
          status: switch (p) {
            ChainWatchPhase.started => ChainWatcherStatus.running,
            ChainWatchPhase.reconnecting => ChainWatcherStatus.reconnecting,
            ChainWatchPhase.stopped => ChainWatcherStatus.stopped,
          },
        );
      };

  Future<void> _stop(int gen) async {
    if (gen != _gen) return;
    _watcher?.stop();
    state = const ChainWatcherState(status: ChainWatcherStatus.stopped);
  }

  /// 手动触发链上对账扫描(07 Settlements 页「全量同步」;对齐上游
  /// `/sync-chain-status`)。[full]=true 重置游标全量重扫;false 增量。
  /// watcher 未运行(disabled / stopped / 身份未解锁)→ 返回 0
  /// (UI 应按 [chainWatcherStatusProvider] 门禁按钮)。
  Future<int> syncSettlements({bool full = false}) async {
    final w = _watcher;
    if (w == null) return 0;
    return w.sync(full: full);
  }
}

/// 链客户端工厂(测试可 override 成伪实现,避免真实 socket)。
/// **HTTP-only**:不传 socketConnector → web3dart `events()` 走 getLogs 轮询(非 eth_subscribe)。
/// 实测 Alchemy 免费层下 WS 握手 + 重连风暴会触 429(CU/s 上限);轮询更稳。WS 待付费 RPC 再启。
final chainClientFactoryProvider = Provider<ChainClient Function(AppConfig)>(
  (ref) => (cfg) => Web3ChainClient(cfg.polygonRpcUrl),
);

final chainWatcherServiceProvider =
    NotifierProvider<ChainWatcherService, ChainWatcherState>(
  ChainWatcherService.new,
);

/// 便捷派生:仅取状态(供 UI watch,避免重建整个 state)。
final chainWatcherStatusProvider = Provider<ChainWatcherStatus>(
  (ref) => ref.watch(chainWatcherServiceProvider.select((s) => s.status)),
);
