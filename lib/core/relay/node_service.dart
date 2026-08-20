import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../crypto/identity_controller.dart';
import '../crypto/signing.dart';
import '../db/database.dart';
import '../db/provider_log_dao.dart';
import '../db/provider_models_dao.dart';
import '../forwarder/model_mapping.dart';
import '../forwarder/stream_dispatcher.dart';
import '../forwarder/stream_http.dart';
import '../log/node_logger.dart';
import '../providers.dart';
import 'messages.dart';
import 'relay_channel.dart';
import 'ws_client.dart';

/// 对外暴露的节点连接状态(wayfinder 01:6 态 enum,供 UI 状态 pill 用)。
enum NodeStatus {
  stopped,
  connecting,
  authenticating,
  connected,
  reconnecting,
  failed,
}

class NodeState {
  const NodeState({required this.status});
  final NodeStatus status;
}

/// WsPhase → NodeStatus 映射(纯函数,便于单测)。
NodeStatus nodeStatusFromPhase(WsPhase p) => switch (p) {
      WsPhase.idle || WsPhase.stopped => NodeStatus.stopped,
      WsPhase.connecting => NodeStatus.connecting,
      WsPhase.authenticating => NodeStatus.authenticating,
      WsPhase.connected => NodeStatus.connected,
      WsPhase.reconnecting => NodeStatus.reconnecting,
      WsPhase.authFailed => NodeStatus.failed,
    };

/// 真实 relay 通道工厂(测试可 override 成假实现,避免真实 socket)。
final relayChannelFactoryProvider = Provider<RelayChannelFactory>(
  (ref) => (url) => WebSocketRelayChannel.connect(url),
);

/// 供应商节点编排:按身份启停 [WsClient],把 WsPhase 映射成 [NodeState]。
///
/// - 身份 **unlocked** → 起客户端(签名/地址/keypair 来自身份;provider_info 模型
///   来自 drift `provider_quotation`),连中转站、鉴权、上报、心跳、断线重连。
/// - 身份 **locked / none** → 停客户端。
/// - keepAlive:进后台即常驻(AppShell watch 它)。身份变化触发重建,旧客户端随
///   [ref.onDispose] 释放。[_gen] 守卫防止「加载期间身份又变」的旧启动落地。
///
/// supervisor(WsClient 内置无限退避重连)即 ticket 所述 in-app supervisor;仅
/// auth 被拒映射为 [NodeStatus.failed](终态),其余瞬态断开自动 reconnecting。
class NodeService extends Notifier<NodeState> {
  WsClient? _client;
  StreamSubscription<WsPhase>? _phaseSub;
  StreamSubscription<RelayMessage>? _inboundSub;
  StreamSubscription<int?>? _latencySub;
  StreamDispatcher? _dispatcher;
  int _gen = 0;

  /// 心跳 RTT 流(04 pill);连接重建时新 client 的 RTT 续接同一流,UI 无感。
  final StreamController<int?> _latency = StreamController<int?>.broadcast();
  Stream<int?> get latencyStream => _latency.stream;

  @override
  NodeState build() {
    ref.keepAlive();
    _gen++;
    final myGen = _gen;
    ref.onDispose(() {
      _phaseSub?.cancel();
      _inboundSub?.cancel();
      _latencySub?.cancel();
      _dispatcher?.abortAll();
      _client?.dispose();
      _latency.close();
    });

    final identity = ref.watch(identityControllerProvider).valueOrNull;
    if (identity != null && identity.isUnlocked) {
      unawaited(_start(identity, myGen));
      return const NodeState(status: NodeStatus.connecting);
    }
    unawaited(_stop(myGen));
    return const NodeState(status: NodeStatus.stopped);
  }

  /// 入站业务消息流(forwarder 在 02 消费;当前暴露供后续接线)。
  Stream<RelayMessage>? get inbound => _client?.inbound;

  /// 06 链上对账:暴露 relay 反查能力给 SettleEventSyncer(经 ChainWatcherService)。
  /// 未连接 / 未解锁时为 null(syncer 据此落 unmatched)。
  RelayQueryClient? get relayQueryClient => _client;

  Future<void> _start(IdentityState identity, int gen) async {
    if (gen != _gen) return;
    final cfg = ref.read(appConfigProvider);
    final db = ref.read(appDatabaseProvider);
    final models = await _loadModels(db);
    if (gen != _gen) return; // 加载期间身份变了:放弃本次启动
    final address = identity.addressEip55!;
    final keypair = identity.keypair!;
    final client = WsClient(
      url: Uri.parse(cfg.relayWsUrl),
      openChannel: ref.read(relayChannelFactoryProvider),
      address: address,
      paymentAddress: address, // 缺省回退 owner 地址(ticket;Settings D 可改)
      sign: (challenge) => signPersonalMessage(challenge, keypair.credentials),
      providerInfo: () => ProviderInfo(
        address: address,
        paymentAddress: address,
        models: models,
      ),
    );
    _client = client;
    _latencySub = client.latency.listen(_latency.add);
    _phaseSub = client.phase.listen((p) {
      if (gen != _gen) return;
      // 断开/鉴权失败/停止:中止所有在飞流(防孤立流挂在已死连接上,姊妹 09 §5)。
      if (p == WsPhase.reconnecting ||
          p == WsPhase.authFailed ||
          p == WsPhase.stopped) {
        _dispatcher?.abortAll();
      }
      if (p == WsPhase.connected) unawaited(syncModels()); // 连上后同步 relay 模型目录
      state = NodeState(status: nodeStatusFromPhase(p));
    });
    // forwarder 桥接(client 已建,send=client.send 自然可得,避免 Riverpod 循环)。
    _dispatcher = StreamDispatcher(
      send: client.send,
      dao: ProviderLogDao(db),
      resolveMapping: (m) => resolveProviderMapping(db, m),
      streamHttp: dioStreamHttp(Dio()),
    );
    _inboundSub = client.inbound.listen(_onInbound);
    await client.start();
  }

  Future<void> _stop(int gen) async {
    if (gen != _gen) return;
    await _phaseSub?.cancel();
    _phaseSub = null;
    await _inboundSub?.cancel();
    _inboundSub = null;
    await _latencySub?.cancel();
    _latencySub = null;
    _dispatcher?.abortAll();
    await _client?.stop();
  }

  /// 入站业务消息派发:llm_request → 转发;llm_stream_cancel → 取消;其余忽略。
  void _onInbound(RelayMessage msg) {
    final d = _dispatcher;
    if (d == null) return;
    switch (msg) {
      case LlmRequestMessage():
        unawaited(d.handleLlmRequest(msg)); // 后台转发,不阻塞 WS 读循环
      case LlmStreamCancelMessage():
        d.handleStreamCancel(msg.requestId);
      default:
        break; // query_settlement* 等暂不由 dispatcher 处理
    }
  }

  /// 从 relay 同步模型目录(`query_model_params` → `provider_models`)。
  /// 连上 relay 自动触发一次;Models 页「同步」按钮也可手动调。返回写入行数。
  /// 未连接/失败返回 0(同步是 best-effort,不影响节点)。
  Future<int> syncModels() async {
    final client = _client;
    if (client == null) return 0;
    try {
      final rows = await client.queryModelParams();
      return ProviderModelsDao(ref.read(appDatabaseProvider)).upsertAll(rows);
    } catch (e) {
      nodeLog.warn('syncModels failed: $e');
      return 0;
    }
  }

  /// 重新上报 provider_info 给 relay(02 Models 页 CRUD 报价后调用,即时同步)。
  /// 未连接 / 未解锁身份时 no-op;WsClient.send 在握手前也会自检 no-op。
  Future<void> reportProviderInfo() async {
    final client = _client;
    if (client == null) return;
    final identity = ref.read(identityControllerProvider).valueOrNull;
    if (identity == null || !identity.isUnlocked) return;
    final address = identity.addressEip55!;
    final db = ref.read(appDatabaseProvider);
    final models = await _loadModels(db);
    client.send(ProviderInfo(
      address: address,
      paymentAddress: address,
      models: models,
    ));
  }

  Future<List<ProviderModel>> _loadModels(AppDatabase db) async {
    final rows = await db.select(db.providerQuotations).get();
    return [
      for (final r in rows)
        ProviderModel(
          relayModel: r.relayModelName,
          inputPricePer1k: r.inputPricePer1k,
          outputPricePer1k: r.outputPricePer1k,
        ),
    ];
  }
}

final nodeServiceProvider =
    NotifierProvider<NodeService, NodeState>(NodeService.new);

/// UI 只关心状态时用(避免无关字段变化触发重建)。
final nodeStatusProvider = Provider<NodeStatus>(
  (ref) => ref.watch(nodeServiceProvider.select((s) => s.status)),
);

/// 心跳 RTT(04 pill)。null = 未测到(连接中 / 未连 / 首心跳回包前 / 断连)。
final nodeLatencyProvider = StreamProvider<int?>(
  (ref) => ref.watch(nodeServiceProvider.notifier).latencyStream,
);
