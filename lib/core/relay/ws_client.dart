import 'dart:async';
import 'dart:math';

import 'messages.dart';
import '../log/node_logger.dart';
import 'relay_channel.dart';

/// WsClient 连接生命周期相位(粗粒度,供 NodeService 映射成对外状态)。
enum WsPhase {
  idle, // 未启动
  connecting, // 正在打开通道
  authenticating, // 已收 challenge、已发 auth,等 auth_ack
  connected, // 鉴权通过,业务中
  reconnecting, // 瞬态断开后退避中
  authFailed, // 中转站拒绝鉴权(终态,不重连)
  stopped, // 主动停止(终态)
}

typedef ChallengeSigner = String Function(String challenge);
typedef ProviderInfoSupplier = ProviderInfo Function();
typedef RelayChannelFactory = RelayChannel Function(Uri url);
typedef Backoff = Duration Function(int attempt);

/// relay 反查端口(06 链上对账):按 (tx, logIndex) 查归属本 settle 的 relay_log。
/// [WsClient] 实现真实 WS 请求/响应;测试可注入伪实现(不建真实 socket)。
abstract class RelayQueryClient {
  Future<List<Map<String, dynamic>>> queryRelayRecordsByTxLogindex(
    String tx,
    int logIndex,
  );

  /// 同步 relay 模型目录(`query_model_params` → `relay_models` 行数组)。
  /// [q] 模糊匹配;空 = 全量目录。失败(未连接/超时/ok=false)抛 [RelayQueryException]。
  Future<List<Map<String, dynamic>>> queryModelParams({String? q});
}

/// relay 反查失败(ok=false / 超时 / 未连接 / 断连)。
class RelayQueryException implements Exception {
  const RelayQueryException(this.message);
  final String message;
  @override
  String toString() => 'RelayQueryException: $message';
}

/// 供应商节点传输层:连中转站 → SIWE/EIP-191 握手 → 心跳 → 断线重连。
///
/// 职责边界:只管传输 + 握手 + 心跳 + 重连的「机械动作」。身份(地址/签名)、
/// provider_info 内容、对外状态机、何时启停,都由 NodeService(Slice C)注入与决策。
/// 时间相关参数([providerInfoDelay]/[heartbeatInterval]/[backoff])可注入,便于测试。
///
/// 协议时序:connect → relay 推 auth_ack{success:false,challenge} → 签 challenge
/// → 发 auth → relay 回 auth_ack{success:true} → 500ms 后发 provider_info + 启心跳。
/// 重连用 full-jitter 指数退避(优于 Node 的无 jitter);auth 被拒为终态不重连。
class WsClient implements RelayQueryClient {
  WsClient({
    required this.url,
    required this.openChannel,
    required this.address,
    required this.paymentAddress,
    required this.sign,
    required this.providerInfo,
    this.providerInfoDelay = const Duration(milliseconds: 500),
    this.heartbeatInterval = const Duration(seconds: 15),
    this.backoff = fullJitterBackoff,
  });

  final Uri url;
  final RelayChannelFactory openChannel;
  final String address;
  final String paymentAddress;
  final ChallengeSigner sign;
  final ProviderInfoSupplier providerInfo;
  final Duration providerInfoDelay;
  final Duration heartbeatInterval;
  final Backoff backoff;

  final StreamController<RelayMessage> _inbound =
      StreamController<RelayMessage>.broadcast();
  final StreamController<WsPhase> _phase =
      StreamController<WsPhase>.broadcast();

  /// 心跳 RTT(04 pill):发心跳记时间戳、收回包算往返延迟。null = 未测到
  /// (连接中 / 未连 / 首个心跳回包前 / 断连后清零)。
  final StreamController<int?> _latency = StreamController<int?>.broadcast();

  /// 握手后转发过来的入站业务消息(心跳回包、握手消息已被本层消费)。
  Stream<RelayMessage> get inbound => _inbound.stream;

  /// 连接相位事件流。
  Stream<WsPhase> get phase => _phase.stream;

  /// 心跳往返延迟流(RTT 毫秒;04 pill 接此)。
  Stream<int?> get latency => _latency.stream;

  RelayChannel? _channel;
  StreamSubscription<String>? _sub;
  Timer? _heartbeat;
  int? _heartbeatSentMs; // 最近一次心跳发送时间(算 RTT 用;04)
  WsPhase _p = WsPhase.idle;
  int _attempt = 0;
  bool _handshakeDone = false;
  bool _stopping = false;

  /// 06 对账:待响应的 query_relay_records_by_tx_logindex,按 requestId 关联。
  final Map<String, Completer<QueryResponse>> _queries = {};

  /// 启动连接(握手 + 心跳 + provider_info;断线自动重连)。幂等。
  Future<void> start() async {
    _stopping = false;
    _connect();
  }

  /// 主动停止:不再重连,关闭通道,置 [WsPhase.stopped]。
  Future<void> stop() async {
    _stopping = true;
    _failPendingQueries(const RelayQueryException('relay 连接已停止'));
    _heartbeat?.cancel();
    _heartbeat = null;
    _heartbeatSentMs = null;
    _latency.add(null); // 停止:无延迟
    await _sub?.cancel();
    _sub = null;
    await _channel?.close();
    _setPhase(WsPhase.stopped);
  }

  /// 发一条出站业务消息(仅握手完成后有效;入站型消息 encode 会抛 [UnsupportedError])。
  void send(RelayMessage msg) {
    if (_handshakeDone && !_stopping) {
      _channel?.send(encodeMessage(msg));
    }
  }

  /// relay 反查(06 对账):按 (tx, logIndex) 查归属本 settle 的 relay_log 记录。
  /// 按 requestId 请求/响应关联;未连接 / 超时 / ok=false 抛 [RelayQueryException]。
  /// 连接断开时 [_onClose]/[stop] 会 fail 掉 pending 反查(触发上层 syncer 重试)。
  @override
  Future<List<Map<String, dynamic>>> queryRelayRecordsByTxLogindex(
    String tx,
    int logIndex, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!_handshakeDone || _stopping) {
      throw const RelayQueryException('relay 未连接,无法反查');
    }
    final requestId = _genRequestId();
    final completer = Completer<QueryResponse>();
    _queries[requestId] = completer;
    try {
      send(QueryRelayRecordsByTxLogindex(
        requestId: requestId,
        tx: tx,
        logindex: logIndex,
      ));
      final resp = await completer.future.timeout(
        timeout,
        onTimeout: () => throw const RelayQueryException('relay 反查超时'),
      );
      if (!resp.ok) {
        throw RelayQueryException(resp.error ?? 'relay 反查失败');
      }
      return resp.data;
    } finally {
      _queries.remove(requestId);
    }
  }

  /// 同步 relay 模型目录(`query_model_params`)——复用 [queryRelayRecordsByTxLogindex]
  /// 的 requestId→Completer 关联;响应 [QueryResponse].data = relay_models 行数组。
  @override
  Future<List<Map<String, dynamic>>> queryModelParams({
    String? q,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (!_handshakeDone || _stopping) {
      throw const RelayQueryException('relay 未连接,无法同步模型');
    }
    final requestId = _genRequestId();
    final completer = Completer<QueryResponse>();
    _queries[requestId] = completer;
    try {
      send(QueryModelParams(requestId: requestId, q: q));
      final resp = await completer.future.timeout(
        timeout,
        onTimeout: () => throw const RelayQueryException('同步模型超时'),
      );
      if (!resp.ok) {
        throw RelayQueryException(resp.error ?? '同步模型失败');
      }
      return resp.data;
    } finally {
      _queries.remove(requestId);
    }
  }

  /// `q_{ts}_{rand8}`(对齐上游 ws/client.ts)。
  String _genRequestId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return 'q_${ts}_$rand';
  }

  void _completeQuery(QueryResponse resp) {
    final c = _queries.remove(resp.requestId);
    if (c != null && !c.isCompleted) c.complete(resp);
  }

  void _failPendingQueries(Object error) {
    if (_queries.isEmpty) return;
    for (final c in _queries.values) {
      if (!c.isCompleted) c.completeError(error);
    }
    _queries.clear();
  }

  /// 释放资源(关闭流控制器)。NodeService dispose 时调用。
  void dispose() {
    _heartbeat?.cancel();
    _sub?.cancel();
    _channel?.close();
    _inbound.close();
    _phase.close();
    _latency.close();
  }

  // ───────── 内部 ─────────

  void _setPhase(WsPhase p) {
    _p = p;
    nodeLog.info('ws → $p');
    _phase.add(p);
  }

  void _connect() {
    _setPhase(WsPhase.connecting);
    _handshakeDone = false;
    final ch = openChannel(url);
    _channel = ch;
    _sub?.cancel();
    _sub = ch.messages.listen(_onMessage, onDone: _onClose);
  }

  void _onMessage(String raw) {
    final RelayMessage msg;
    try {
      msg = decodeMessage(raw);
    } catch (_) {
      return; // 畸形帧:忽略,不让坏消息打掉连接
    }

    if (!_handshakeDone) {
      if (msg is AuthAck) _handleHandshakeAck(msg);
      return;
    }
    // 握手后:心跳回包消费掉(顺带算 RTT),其余转发给上层。
    if (msg is Heartbeat) {
      final sent = _heartbeatSentMs;
      if (sent != null) {
        _latency.add(DateTime.now().millisecondsSinceEpoch - sent);
        _heartbeatSentMs = null;
      }
      return;
    }
    // 06 对账:query_response 按 requestId 派发给 pending 反查,不转发上层。
    if (msg is QueryResponse) {
      _completeQuery(msg);
      return;
    }
    _inbound.add(msg);
  }

  void _handleHandshakeAck(AuthAck ack) {
    if (!ack.success && ack.challenge != null) {
      // challenge 相位:签名 + 发 auth。
      _setPhase(WsPhase.authenticating);
      _channel?.send(encodeMessage(Auth(
        address: address,
        paymentAddress: paymentAddress,
        signature: sign(ack.challenge!),
      )));
    } else if (ack.success) {
      // 鉴权通过:上报 provider_info + 启心跳。
      _handshakeDone = true;
      _attempt = 0;
      _setPhase(WsPhase.connected);
      _startHeartbeat();
      _scheduleProviderInfo();
    } else if (ack.error != null) {
      // 中转站拒绝:终态,不重连。close 触发 onDone;_onClose 见 authFailed 即返回。
      _setPhase(WsPhase.authFailed);
      _stopping = true;
      _channel?.close();
    }
    // 其余畸形 auth_ack:忽略,留待重试或人工介入。
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(heartbeatInterval, (_) {
      if (_handshakeDone && !_stopping) {
        _heartbeatSentMs = DateTime.now().millisecondsSinceEpoch;
        _channel?.send(
            encodeMessage(Heartbeat(DateTime.now().millisecondsSinceEpoch)));
      }
    });
  }

  void _scheduleProviderInfo() {
    Future<void>.delayed(providerInfoDelay, () {
      if (_handshakeDone && !_stopping) {
        _channel?.send(encodeMessage(providerInfo()));
      }
    });
  }

  void _onClose() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _heartbeatSentMs = null;
    _latency.add(null); // 断连:延迟无效
    // 连接断开:pending 反查永无响应,fail 掉触发上层 syncer 重试或落 unmatched。
    _failPendingQueries(const RelayQueryException('relay 连接断开'));
    if (_p == WsPhase.authFailed) return; // 终态
    if (_stopping) {
      _setPhase(WsPhase.stopped);
      return;
    }
    // 瞬态断开:退避后重连。
    _setPhase(WsPhase.reconnecting);
    final delay = backoff(_attempt);
    _attempt++;
    Future<void>.delayed(delay, () {
      if (!_stopping) _connect();
    });
  }
}

/// full-jitter 指数退避(wayfinder 01 择定,优于 Node 的无 jitter):
/// delay = random[0, min(cap, base·2^attempt)],base 1s、cap 60s。
Duration fullJitterBackoff(int attempt, {Random? random}) {
  final r = random ?? Random();
  final exp = 1 << attempt.clamp(0, 6); // 1,2,4,…,64;更大已封顶
  final upperMs = (1000 * exp).clamp(0, 60000);
  return Duration(milliseconds: (upperMs * r.nextDouble()).floor());
}
