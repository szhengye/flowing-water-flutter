import 'package:drift/drift.dart';

import 'database.dart';

/// provider_log 计费插桩 DAO —— wayfinder 09:dispatcher 层调用(forwarder 本身不碰 DB)。
///
/// 不用 `@DriftAccessor`(免 codegen 改 database.dart),直接持 [AppDatabase] 用 table
/// API。三段插桩对应一次转发生命周期:insert(pending+时点价) → complete(落 amount)
/// 或 fail(落 error_message)。amount 公式与上游 relay-records 一致(时点价防结算时
/// 报价已变)。
class ProviderLogDao {
  ProviderLogDao(this.db);
  final AppDatabase db;

  /// 转发开始:插一条 pending + 时点价快照(amount/latency 待 complete 填)。
  Future<void> insertRecord({
    required String requestId,
    required String modelName,
    required int inputPricePer1k,
    required int outputPricePer1k,
  }) async {
    await db.into(db.providerLogs).insert(
      ProviderLogsCompanion.insert(
        requestId: requestId,
        modelName: modelName,
        providerInputPrice: Value(inputPricePer1k),
        providerOutputPrice: Value(outputPricePer1k),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      ),
    );
  }

  /// 转发成功:落 token 用量 / amount / latency,置 `completed`。
  Future<void> completeRecord({
    required String requestId,
    required int promptTokens,
    required int completionTokens,
    required int amount,
    required int latencyMs,
  }) async {
    await (db.update(db.providerLogs)
          ..where((t) => t.requestId.equals(requestId)))
        .write(ProviderLogsCompanion(
      processingStatus: const Value('completed'),
      inputTokens: Value(promptTokens),
      outputTokens: Value(completionTokens),
      amount: Value(amount),
      latencyMs: Value(latencyMs),
    ));
  }

  /// 转发失败:置 `failed` + error_message。
  Future<void> failRecord({
    required String requestId,
    required String errorMessage,
  }) async {
    await (db.update(db.providerLogs)
          ..where((t) => t.requestId.equals(requestId)))
        .write(ProviderLogsCompanion(
      processingStatus: const Value('failed'),
      errorMessage: Value(errorMessage),
    ));
  }

  /// 链上对账回填(06):把一笔 provider_log 标为已上链结算。
  ///
  /// chain_status 强制写上游 bi-state(本 app 只记 not_on_chain / on_chain_settled;
  /// relay 的 3-state 不穿透)。WHERE 限三态 → 允许 not_on_chain /
  /// on_chain_not_settled 正向转 on_chain_settled(终态,重复写幂等)。返回受影响行数
  /// (0 = 无此 requestId 或已处终态之外)。对齐上游 relay-records.ts updateRecordChainStatus。
  Future<int> updateChainStatus({
    required String requestId,
    required String chainStatus,
    required String settleTx,
    required int logIndex,
  }) async {
    return (db.update(db.providerLogs)
          ..where(
            (t) =>
                t.requestId.equals(requestId) &
                t.chainStatus.isIn(
                    ['not_on_chain', 'on_chain_settled', 'on_chain_not_settled']),
          ))
        .write(ProviderLogsCompanion(
      chainStatus: Value(chainStatus),
      settleTx: Value(settleTx),
      logIndex: Value(logIndex),
    ));
  }

  /// nUSD 计费公式(上游 round((in×prompt + out×completion)/1000))。
  static int computeAmount(
    int inputPricePer1k,
    int outputPricePer1k,
    int promptTokens,
    int completionTokens,
  ) =>
      ((inputPricePer1k * promptTokens + outputPricePer1k * completionTokens) / 1000)
          .round();

  /// 按 settle tx 查关联中转流水(07;对齐上游 `getRecordsBySettleTx`,
  /// `WHERE settle_tx = ? ORDER BY created_at ASC`)。供 Settlements 行点击 /
  /// Wallet USDT 交易钻取「关联流水」明细。
  Future<List<ProviderLogRow>> getBySettleTx(String settleTx) {
    return (db.select(db.providerLogs)
          ..where((t) => t.settleTx.equals(settleTx))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Records 页(04):按处理状态 / 链态筛选的只读流水(createdAt 倒序,最新在前)。
  /// `null` = 该维度不过滤(全部)。drift watch → 新流水落地自动刷新。
  Stream<List<ProviderLogRow>> watchRecords({
    String? processingStatus,
    String? chainStatus,
  }) {
    final q = db.select(db.providerLogs)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (processingStatus != null || chainStatus != null) {
      q.where((t) {
        Expression<bool> e = const Constant<bool>(true);
        if (processingStatus != null) {
          e = t.processingStatus.equals(processingStatus) & e;
        }
        if (chainStatus != null) {
          e = t.chainStatus.equals(chainStatus) & e;
        }
        return e;
      });
    }
    return q.watch();
  }

  /// Dashboard 看板(04):某时点以来的全部流水,供 [computeLlmMetrics] 聚合。
  /// `sinceEpochSec = 0` 即 lifetime。drift watch → 周期内新流水自动重算指标。
  Stream<List<ProviderLogRow>> watchRecordsSince(int sinceEpochSec) {
    return (db.select(db.providerLogs)
          ..where((t) => t.createdAt.isBiggerOrEqualValue(sinceEpochSec))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }
}

/// 模型维度明细(Dashboard 模型明细表的一行)。
class ModelBreakdown {
  const ModelBreakdown(this.modelName, this.calls, this.completed, this.amountNusd);
  final String modelName;
  final int calls; // 总调用(含失败/pending)
  final int completed;
  final int amountNusd; // 仅 completed 累计(scheme 注释:nUSD)
}

/// LLM 看板聚合(04 Dashboard)。由纯函数 [computeLlmMetrics] 从一段流水算出。
class LlmMetrics {
  const LlmMetrics({
    required this.total,
    required this.completed,
    required this.failed,
    required this.pending,
    required this.amountNusd,
    required this.inputTokens,
    required this.outputTokens,
    required this.avgLatencyMs,
    required this.byModel,
  });

  final int total;
  final int completed;
  final int failed;
  final int pending;
  final int amountNusd; // 累计计费额(completed;单位 nUSD,见 tables.dart)
  final int inputTokens;
  final int outputTokens;
  final int avgLatencyMs; // completed 且 latency>0 的均值;无则 0
  final List<ModelBreakdown> byModel; // 按 amountNusd 倒序

  double get completionRate => total == 0 ? 0 : completed / total;
  double get failureRate => total == 0 ? 0 : failed / total;

  static const LlmMetrics empty = LlmMetrics(
    total: 0,
    completed: 0,
    failed: 0,
    pending: 0,
    amountNusd: 0,
    inputTokens: 0,
    outputTokens: 0,
    avgLatencyMs: 0,
    byModel: <ModelBreakdown>[],
  );
}

/// 把一段 provider_log 流水聚合成看板指标(纯函数,便于单测锁定业务含义)。
///
/// 计费额/用量只统计 `completed`(pending/failed 无最终用量);调用数含全部状态,
/// 故完成率 = completed/total 反映「请求最终成功落地」这一业务意图。
LlmMetrics computeLlmMetrics(List<ProviderLogRow> rows) {
  if (rows.isEmpty) return LlmMetrics.empty;
  var completed = 0, failed = 0, pending = 0;
  var amount = 0, inTok = 0, outTok = 0, latSum = 0, latN = 0;
  final byModel = <String, ModelBreakdown>{};
  for (final r in rows) {
    final isCompleted = r.processingStatus == 'completed';
    switch (r.processingStatus) {
      case 'completed':
        completed++;
      case 'failed':
        failed++;
      case 'pending':
        pending++;
      default:
        break;
    }
    if (isCompleted) {
      amount += r.amount;
      inTok += r.inputTokens;
      outTok += r.outputTokens;
      if (r.latencyMs > 0) {
        latSum += r.latencyMs;
        latN++;
      }
    }
    final prev = byModel[r.modelName] ?? ModelBreakdown(r.modelName, 0, 0, 0);
    byModel[r.modelName] = ModelBreakdown(
      prev.modelName,
      prev.calls + 1,
      prev.completed + (isCompleted ? 1 : 0),
      prev.amountNusd + (isCompleted ? r.amount : 0),
    );
  }
  final models = byModel.values.toList()
    ..sort((a, b) => b.amountNusd.compareTo(a.amountNusd));
  return LlmMetrics(
    total: rows.length,
    completed: completed,
    failed: failed,
    pending: pending,
    amountNusd: amount,
    inputTokens: inTok,
    outputTokens: outTok,
    avgLatencyMs: latN == 0 ? 0 : latSum ~/ latN,
    byModel: models,
  );
}

/// 厂商维度明细(12 Dashboard 厂商汇总的一行)。
class VendorBreakdown {
  const VendorBreakdown(this.vendor, this.calls, this.amountNusd);
  final String vendor; // 上游厂商名;未映射模型归「未知」
  final int calls; // completed 调用数
  final int amountNusd; // completed 收益累计(nUSD)
}

/// 按上游厂商聚合一段 provider_log 流水(12)。`modelToVendor`: relayModelName →
/// vendorName(来自 [QuotationDao.relayModelToVendorMap]);未映射归「未知」。
/// 与 [computeLlmMetrics] 同口径:收益/调用只计 `completed`。纯函数,便于单测。
List<VendorBreakdown> computeVendorBreakdown(
  List<ProviderLogRow> rows,
  Map<String, String> modelToVendor,
) {
  final amount = <String, int>{};
  final calls = <String, int>{};
  for (final r in rows) {
    if (r.processingStatus != 'completed') continue;
    final vendor = modelToVendor[r.modelName] ?? '未知';
    amount[vendor] = (amount[vendor] ?? 0) + r.amount;
    calls[vendor] = (calls[vendor] ?? 0) + 1;
  }
  return [
    for (final e in amount.entries)
      VendorBreakdown(e.key, calls[e.key] ?? 0, e.value),
  ]..sort((a, b) => b.amountNusd.compareTo(a.amountNusd));
}
