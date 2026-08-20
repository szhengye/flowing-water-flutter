import 'dart:async';

import 'package:web3dart/web3dart.dart';

import '../db/database.dart';
import '../db/provider_log_dao.dart';
import '../db/unmatched_settled_event_dao.dart';
import '../relay/ws_client.dart';
import 'abi/relay_station.dart';
import 'settle_event_syncer.dart';

/// 取当前 relay 反查 client(随 NodeService 连通/断开实时取;null = 未连接)。
/// 与 [SettleEventSyncer.relayQueryClient] 同源。
typedef RelayQueryClientSupplier = RelayQueryClient? Function();

/// 注入的 sleep;测试传 no-op 跳过真实等待(轮询 + syncer 内部重试共用)。
typedef RetrySleep = Future<void> Function(Duration);

/// 单笔未匹配事件的重试结果(对齐上游 retry-all summary 条目)。
class RetryEventResult {
  const RetryEventResult({
    required this.tx,
    required this.logIndex,
    required this.matched,
    this.error,
  });
  final String tx;
  final int logIndex;
  final int matched; // >0 = 命中回填;0 = 仍无匹配
  final String? error;
}

/// retry-all 汇总(对齐上游 `POST /unmatched-settled-events/retry-all` 响应)。
class RetrySummary {
  const RetrySummary({
    required this.retried,
    required this.matched,
    required this.stillUnmatched,
    required this.notConnected,
    required this.results,
  });
  final int retried; // 本次尝试的事件笔数
  final int matched; // 命中回填的总 request 笔数(跨事件累加)
  final int stillUnmatched; // 仍 0 匹配、累加了 retry 计数的事件笔数
  final bool notConnected; // relay 超时未连 → 整体跳过(未动 DAO)
  final List<RetryEventResult> results;

  /// relay 未连接的短路结果(对齐上游 retry-all 的 502 早退)。
  const RetrySummary.notConnected()
      : retried = 0,
        matched = 0,
        stillUnmatched = 0,
        notConnected = true,
        results = const [];
}

/// operator 手动重试 unmatched Settled 事件(09,移植上游 retry-all)。
///
/// 复用 06 的 [SettleEventSyncer.sync] —— watcher(自动采集)与 operator(手动重试)
/// 共用同一对账原语,与上游 `syncSettledEventToProviderLog` 被 watcher + admin 路由
/// 共享同构。重试前先 [waitForConnected] 确保 relay WS 已连(上游 20s),未连则整体
/// 跳过(不盲重试、不误删)。命中 → 从未匹配表移除;仍 0 匹配 → 累加 retry 计数。
///
/// 构造注入全部协作者,便于无 Riverpod 单测(伪 client supplier + 内存库 + no-op sleep)。
class UnmatchedRetryService {
  UnmatchedRetryService({
    required this.unmatchedDao,
    required this.providerLogDao,
    required this.relayQueryClient,
    this.waitForConnectedTimeout = const Duration(seconds: 20),
    this.pollInterval = const Duration(milliseconds: 200),
    this.syncerRetryDelay = const Duration(seconds: 2),
    this.sleep = _defaultSleep,
    this.log,
  });

  final UnmatchedSettledEventDao unmatchedDao;
  final ProviderLogDao providerLogDao;
  final RelayQueryClientSupplier relayQueryClient;
  final Duration waitForConnectedTimeout;
  final Duration pollInterval;
  final Duration syncerRetryDelay; // 透传 syncer(对齐 watcher 默认 2s;测试传 0)
  final RetrySleep sleep;
  final void Function(String)? log;

  /// 重试全部未匹配事件。relay 超时未连 → 返回 [RetrySummary.notConnected],**不动 DAO**。
  Future<RetrySummary> retryAll() async {
    if (!await _waitForConnected()) {
      log?.call('retryAll: relay 未连接'
          '(${waitForConnectedTimeout.inSeconds}s 超时)→ 整体跳过');
      return const RetrySummary.notConnected();
    }

    final events = await unmatchedDao.list();
    if (events.isEmpty) {
      return const RetrySummary(
        retried: 0,
        matched: 0,
        stillUnmatched: 0,
        notConnected: false,
        results: [],
      );
    }

    // 同构 ChainWatcherService._start 的 syncer 构造:同 supplier + 同 DAO。
    final syncer = SettleEventSyncer(
      relayQueryClient: relayQueryClient,
      providerLogDao: providerLogDao,
      unmatchedDao: unmatchedDao,
      retryDelay: syncerRetryDelay,
      sleep: sleep,
      log: log == null ? null : (m) => log!('  syncer: $m'),
    );

    final results = <RetryEventResult>[];
    var matchedTotal = 0;
    var stillUnmatched = 0;
    for (final ev in events) {
      final r = await syncer.sync(
        tx: ev.tx,
        logIndex: ev.logIndex,
        event: _eventFromRow(ev),
      );
      if (r.matched > 0) {
        await unmatchedDao.remove(tx: ev.tx, logIndex: ev.logIndex);
        matchedTotal += r.matched;
        results.add(RetryEventResult(
          tx: ev.tx,
          logIndex: ev.logIndex,
          matched: r.matched,
        ));
      } else {
        await unmatchedDao.recordRetry(tx: ev.tx, logIndex: ev.logIndex);
        stillUnmatched++;
        results.add(RetryEventResult(
          tx: ev.tx,
          logIndex: ev.logIndex,
          matched: 0,
          error: r.lastError,
        ));
      }
    }
    log?.call('retryAll: ${events.length} 笔 → 匹配 $matchedTotal,'
        ' 仍未匹配 $stillUnmatched');
    return RetrySummary(
      retried: events.length,
      matched: matchedTotal,
      stillUnmatched: stillUnmatched,
      notConnected: false,
      results: results,
    );
  }

  /// 轮询 relay client 直到非 null 或超时(对齐上游 `waitForConnected(20000)`)。
  Future<bool> _waitForConnected() async {
    final deadline = DateTime.now().add(waitForConnectedTimeout);
    while (DateTime.now().isBefore(deadline)) {
      if (relayQueryClient() != null) return true;
      await sleep(pollInterval);
    }
    return relayQueryClient() != null;
  }

  /// 从未匹配表行重建 [SettledEventArgs](对齐上游 retry-all 行 672-678 的重建)。
  /// amount 取 settledAmount(采集时 = 事件 amount);vendor 取 providerAddress。
  static SettledEventArgs _eventFromRow(UnmatchedSettledEventRow r) =>
      SettledEventArgs(
        vendor: EthereumAddress.fromHex(r.providerAddress),
        successCount: BigInt.from(r.settledCount),
        amount: BigInt.parse(r.settledAmount),
        notSuccessCount: BigInt.from(r.notSettledCount),
        notSuccessAmount: BigInt.parse(r.notSettledAmount),
        timestamp: BigInt.from(r.blockTimestamp),
      );
}

Future<void> _defaultSleep(Duration d) => Future<void>.delayed(d);
