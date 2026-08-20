import 'dart:async';

import 'package:flowing_water/core/relay/relay_channel.dart';

/// 测试用假 relay channel —— 手动推进入站消息、记录出站、模拟服务端关闭。
///
/// 配合 [WsClient] 测试:测试代码用 [receive] 推入站握手/业务消息,用 [sent] 观察
/// 出站(auth / provider_info / heartbeat),用 [closeFromServer] 模拟断连。
class FakeRelayChannel implements RelayChannel {
  final StreamController<String> _inbound = StreamController<String>();
  final List<String> sent = [];
  bool closed = false;

  @override
  Stream<String> get messages => _inbound.stream;

  @override
  void send(String data) => sent.add(data);

  @override
  Future<void> close() async {
    closed = true;
    await _inbound.close();
  }

  /// 推一条入站原始 JSON(握手或业务消息)。
  void receive(String raw) {
    if (!_inbound.isClosed) _inbound.add(raw);
  }

  /// 模拟服务端断开连接(stream done)。
  void closeFromServer() => _inbound.close();
}
