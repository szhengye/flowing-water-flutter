import 'dart:async';

import 'package:web3dart/web3dart.dart';

import '../db/chain_sync_cursor_dao.dart';
import '../db/provider_chain_settlement_dao.dart';
import 'abi/relay_station.dart';
import 'backfill_math.dart';
import 'chain_client.dart';
import 'settle_event_syncer.dart';

/// watcher 生命周期相位(供 ChainWatcherService 映射成可观测状态)。
enum ChainWatchPhase { started, reconnecting, stopped }

/// 监听 Polygon 上 RelayStationPolygon.Settled 事件(vendor = 本供应商地址),
/// 幂等写入 provider_chain_settlement,并按三层 floor backfill 跨重启续点。
///
/// **范围(03a):仅采集** —— detect → decode → vendor 过滤 → 去重落地 → 推进游标。
/// 对账(provider_log 回填 / unmatched)在 03b;链上读/页面在 03c。
///
/// 镜像上游 provider-server/chain/polygon-event-watcher.ts(三层 backfill +
/// 全程成功才推进游标 + 重连退避);重连用 full-jitter(对齐 relay ws_client,优于上游无 jitter)。
class PolygonEventWatcher {
  PolygonEventWatcher({
    required ChainClientFactory clientFactory,
    required this.settlementDao,
    required this.cursorDao,
    required this.providerAddress,
    required this.contractAddress,
    this.deployBlock = 0,
    this.recentWindowHours = 72,
    BackoffSchedule? backoff,
    void Function(String)? log,
    this.onPhase,
    this.syncer,
  })  : _clientFactory = clientFactory,
        _contract = relayStationContract(contractAddress),
        _backoff = backoff ?? fullJitterDelaySeconds,
        _log = log ?? ((_) {});

  final ChainClientFactory _clientFactory;
  final ProviderChainSettlementDao settlementDao;
  final ChainSyncCursorDao cursorDao;
  final EthereumAddress Function() providerAddress;
  final EthereumAddress contractAddress;
  final int deployBlock;
  final int recentWindowHours;
  final BackoffSchedule _backoff;
  final void Function(String) _log;

  /// 生命周期相位回调(可选);供编排层暴露可观测状态。
  final void Function(ChainWatchPhase)? onPhase;

  /// 06 链上对账:采集后反查 relay 回填 provider_log;null = 仅采集(05 行为,测试用)。
  final SettleEventSyncer? syncer;

  final DeployedContract _contract;
  late final ContractEvent _settled = _contract.event('Settled');

  ChainClient? _client;
  StreamSubscription<FilterEvent>? _sub;
  Timer? _reconnectTimer;
  bool _running = false;
  bool _disposed = false;
  int _attempt = 0;

  /// 当前是否在订阅中(健康)。
  bool get isActive => _running && _sub != null;

  /// 启动:校验身份 → 建 client → 订阅 Settled(live)→ 触发 backfill。
  /// 身份未就绪返回 false 且**不重连**(caller 应在解锁后重 invoke);其余失败退避重连。
  Future<bool> start() async {
    if (_disposed) return false;
    if (_currentVendor() == null) {
      _log('provider 地址未就绪,跳过启动');
      return false;
    }
    _running = true;
    try {
      await _client?.dispose();
      final client = _clientFactory();
      _client = client;
      _sub = client
          .events(FilterOptions.events(contract: _contract, event: _settled))
          .listen(
            handleSettledEvent,
            onError: (Object e) {
              _log('events 流错误: $e');
              _scheduleReconnect();
            },
          );
      _attempt = 0;
      _log('已启动,监听 Settled(vendor=${_currentVendor()})');
      onPhase?.call(ChainWatchPhase.started);
      // fire-and-forget:幂等,失败仅留游标不进,下次 start/reconnect 重试。
      unawaited(
        backfillWith(client).then<void>(
          (_) {},
          onError: (Object e) => _log('backfill 失败(游标未推进): $e'),
        ),
      );
      return true;
    } catch (e) {
      _log('启动失败: $e');
      _scheduleReconnect();
      return false;
    }
  }

  /// 停止订阅与重连定时器(幂等,可重复调用)。
  void stop() {
    _running = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _sub?.cancel();
    _sub = null;
    _log('已停止');
    onPhase?.call(ChainWatchPhase.stopped);
  }

  /// 释放底层 client(幂等:dispose 后再调用为 no-op)。
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    stop();
    await _client?.dispose();
    _client = null;
  }

  EthereumAddress? _currentVendor() {
    try {
      return providerAddress();
    } catch (_) {
      return null;
    }
  }

  /// 处理一条 Settled(live 或 backfill 共用):解码 → vendor 过滤 → 幂等落地。
  /// 公开供测试直接喂构造好的 FilterEvent(无需真实链)。
  Future<void> handleSettledEvent(FilterEvent log) async {
    if (_disposed) return;
    final vendor = _currentVendor();
    if (vendor == null) return;
    final tx = log.transactionHash;
    if (tx == null) return;
    final args = SettledEventArgs.fromEvent(_settled, log);
    if (args.vendor != vendor) return; // 客户端兜底过滤
    final logIdx = log.logIndex;
    await _persist(tx, logIdx, args);
    // 06 对账:采集后 fire-and-forget 反查 relay 回填 provider_log(对齐本文件
    // backfill 的 unawaited 约定;syncer 内部 retry,relay 未连接则落 unmatched)。
    final s = syncer;
    if (s != null && logIdx != null) {
      unawaited(s.sync(tx: tx, logIndex: logIdx, event: args));
    }
  }

  Future<void> _persist(String tx, int? logIndex, SettledEventArgs args) async {
    if (await settlementDao.exists(tx)) {
      if (logIndex != null) await settlementDao.setLogIndex(tx, logIndex);
      return;
    }
    await settlementDao.insert(
      tx: tx,
      providerAddress: args.vendor.hexEip55,
      relayStationAddress: contractAddress.hexEip55,
      receivedUsdt: args.amount.toString(),
      settledCount: args.successCount.toInt(),
      settledAmount: args.amount.toString(),
      notSettledCount: args.notSuccessCount.toInt(),
      notSettledAmount: args.notSuccessAmount.toString(),
      createdAtMs: args.timestamp.toInt() * 1000,
      logIndex: logIndex,
    );
    _log('settled: tx=$tx amount=${args.amount} success=${args.successCount}');
  }

  /// 三层 floor backfill:getLogs 分页回补至最新,**全程成功才推进游标**。
  /// 任一页抛错 → 游标不动 → 下次 start/reconnect 重试。返回处理的 Settled 数。
  /// 公开供测试注入伪 [ChainClient] 直接驱动(跳过 start 的真实建连)。
  Future<int> backfillWith(ChainClient client) async {
    final vendor = _currentVendor();
    if (vendor == null) return 0;

    final latest = await client.getBlockNumber();
    final cursor = await cursorDao.get(kProviderSettledScope);
    final fromBlock = backfillFloor(
      latest: latest,
      cursor: cursor,
      deployBlock: deployBlock,
      recentWindowHours: recentWindowHours,
    );
    if (latest < fromBlock) return 0;

    var processed = 0;
    final pages = logPages(fromBlock, latest);
    for (var i = 0; i < pages.length; i++) {
      // 节流:Alchemy 免费层 compute units/sec 紧,逐页间留 300ms 防 429(08 smoke 实测)。
      if (i > 0) await Future.delayed(const Duration(milliseconds: 300));
      final page = pages[i];
      final logs = await client.getLogs(
        FilterOptions.events(
          contract: _contract,
          event: _settled,
          fromBlock: BlockNum.exact(page.from),
          toBlock: BlockNum.exact(page.to),
        ),
      );
      for (final log in logs) {
        if (log.transactionHash == null) continue;
        final args = SettledEventArgs.fromEvent(_settled, log);
        if (args.vendor != vendor) continue;
        await _persist(log.transactionHash!, log.logIndex, args);
        processed++;
      }
    }
    // 全程成功才推进(任一页抛错 → 不执行此行)。
    await cursorDao.set(kProviderSettledScope, latest);
    if (processed > 0) _log('backfill: 补回 $processed 笔 Settled(至块 $latest)');
    return processed;
  }

  /// 手动触发一次对账扫描(07 Settlements 页「全量同步」;对齐上游
  /// `/sync-chain-status`)。
  ///
  /// - [full]=false(增量):直接 [backfillWith],从 cursor 扫到 latest。
  /// - [full]=true(全量):先把 cursor 重置到 floor-1(deployBlock-1;deployBlock
  ///   缺省则置 0,让 [backfillFloor] 回退到 recent window),再 [backfillWith]
  ///   强制重扫部署/window 以来的全部事件(按 tx 幂等去重)。
  ///
  /// 需已 [start](`_client` 就绪);未启动返回 0。测试可经 [client] 注入伪客户端。
  Future<int> sync({bool full = false, ChainClient? client}) async {
    final c = client ?? _client;
    if (c == null) {
      _log('sync: watcher 未启动,跳过');
      return 0;
    }
    if (full) {
      final floor = deployBlock > 0 ? deployBlock - 1 : 0;
      await cursorDao.set(kProviderSettledScope, floor);
      _log('sync: 全量重扫,游标重置到 $floor');
    }
    return backfillWith(c);
  }

  /// 失败后 full-jitter 退避重连。
  void _scheduleReconnect() {
    _sub?.cancel();
    _sub = null;
    if (!_running || _disposed) return;
    final secs = _backoff(_attempt);
    _attempt++;
    _log('$secs s 后重连');
    onPhase?.call(ChainWatchPhase.reconnecting);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: secs), start);
  }
}
