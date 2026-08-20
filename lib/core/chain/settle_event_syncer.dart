import 'dart:async';

import '../db/provider_log_dao.dart';
import '../db/unmatched_settled_event_dao.dart';
import '../relay/ws_client.dart';
import 'abi/relay_station.dart';

/// 取当前 relay 反查 client(随 NodeService 连通/断开实时取;null = 未连接)。
typedef RelayQueryClientSupplier = RelayQueryClient? Function();

/// 注入的 sleep;测试传 no-op 跳过真实 2s 等待。
typedef Sleep = Future<void> Function(Duration);

/// settle-event-syncer 对账结果(对齐上游 SyncSettledEventResult)。
class SyncResult {
  const SyncResult({
    required this.matched,
    required this.matchedRequestIds,
    required this.recordedToUnmatched,
    this.lastError,
  });
  final int matched;
  final List<String> matchedRequestIds;
  final bool recordedToUnmatched;
  final String? lastError;
}

/// 把一笔链上 Settled(tx, logIndex)经 relay WS 反查对账(06,移植上游
/// settle-event-syncer.ts)。
///
/// 反查命中 → 回填 provider_log(chain_status **强制** on_chain_settled + settle_tx +
/// log_index;relay 的 3-state 不穿透,bi-state);反查 0 行 / 失败耗尽重试 / relay
/// 未连接 → 写 unmatched_settled_events 待 operator 重试。**永不走 ±时间窗 fallback**
/// (会误匹配其他未结算 record,失去 WS 时宁可漏记不误记)。retry 重试的是 WS 查询本身
/// (网络错或空响应都重试,给 relay reconcile 时间)。
class SettleEventSyncer {
  SettleEventSyncer({
    required this.relayQueryClient,
    required this.providerLogDao,
    required this.unmatchedDao,
    this.maxRetry = 5,
    this.retryDelay = const Duration(seconds: 2),
    this.sleep = _defaultSleep,
    this.log,
  });

  final RelayQueryClientSupplier relayQueryClient;
  final ProviderLogDao providerLogDao;
  final UnmatchedSettledEventDao unmatchedDao;
  final int maxRetry;
  final Duration retryDelay;
  final Sleep sleep;
  final void Function(String)? log;

  /// 对账一笔 Settled。watcher 用 `unawaited(syncer.sync(...))` 调用。
  Future<SyncResult> sync({
    required String tx,
    required int logIndex,
    required SettledEventArgs event,
  }) async {
    final vendorHex = event.vendor.hexEip55;

    // relay 未连接 → 无从反查,直接落 unmatched(operator 后续重试)。
    final client = relayQueryClient();
    if (client == null) {
      await _recordUnmatched(tx, logIndex, vendorHex, event);
      log?.call('sync: relay 未连接 → unmatched(tx=$tx)');
      return const SyncResult(
        matched: 0,
        matchedRequestIds: [],
        recordedToUnmatched: true,
        lastError: 'relay 未连接',
      );
    }

    var requestIds = const <String>[];
    Object? lastErr;
    var attempt = 0;
    // WS 重试:给 relay reconcile 时间把 relay_log.log_index 写好(可能竞态)。
    while (attempt < maxRetry) {
      try {
        final records = await client.queryRelayRecordsByTxLogindex(tx, logIndex);
        requestIds = [
          for (final r in records)
            if (r['request_id'] is String) r['request_id'] as String,
        ];
        if (requestIds.isNotEmpty) break;
        attempt++;
        if (attempt < maxRetry) {
          log?.call('sync: 反查空(relay reconcile 竞态?),'
              '$attempt/$maxRetry 重试');
          await sleep(retryDelay);
        }
      } catch (err) {
        lastErr = err;
        attempt++;
        if (attempt < maxRetry) {
          log?.call('sync: 反查失败 $attempt/$maxRetry: $err,重试');
          await sleep(retryDelay);
        }
      }
    }

    if (requestIds.isNotEmpty) {
      // 命中:回填 provider_log。chain_status 强制 on_chain_settled(bi-state);
      // WHERE 三态 → 终态 on_chain_settled 重复写幂等。
      for (final requestId in requestIds) {
        await providerLogDao.updateChainStatus(
          requestId: requestId,
          chainStatus: 'on_chain_settled',
          settleTx: tx,
          logIndex: logIndex,
        );
      }
      log?.call('sync: 命中 ${requestIds.length} 笔 '
          '(tx=$tx logIndex=$logIndex)');
      return SyncResult(
        matched: requestIds.length,
        matchedRequestIds: requestIds,
        recordedToUnmatched: false,
      );
    }

    // 0 行或重试耗尽:落 unmatched。
    final isNew = await _recordUnmatched(tx, logIndex, vendorHex, event);
    log?.call('sync: 反查 0 行/$maxRetry 次重试耗尽 → unmatched '
        '(tx=$tx logIndex=$logIndex${isNew ? ' 新' : ' 已跟踪'}'
        '${lastErr != null ? ' lastErr=$lastErr' : ''})');
    return SyncResult(
      matched: 0,
      matchedRequestIds: const [],
      recordedToUnmatched: true,
      lastError: lastErr?.toString(),
    );
  }

  Future<bool> _recordUnmatched(
    String tx,
    int logIndex,
    String vendorHex,
    SettledEventArgs event,
  ) =>
      unmatchedDao.insert(
        tx: tx,
        logIndex: logIndex,
        providerAddress: vendorHex,
        receivedUsdt: event.amount.toString(),
        settledCount: event.successCount.toInt(),
        settledAmount: event.amount.toString(),
        notSettledCount: event.notSuccessCount.toInt(),
        notSettledAmount: event.notSuccessAmount.toString(),
        blockTimestamp: event.timestamp.toInt(),
      );
}

Future<void> _defaultSleep(Duration d) => Future.delayed(d);
