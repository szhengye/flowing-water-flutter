import 'package:web_socket_channel/web_socket_channel.dart';

/// relay WS 传输通道抽象 —— wayfinder ticket 01 / Slice B。
///
/// 把 [WebSocketChannel] 的 API 收窄成 WsClient 依赖的最小面(`messages` 入站文本流、
/// `send` 出站、`close`),使 WsClient 可在测试中用假实现驱动握手/心跳/重连,
/// 而非真实 socket。
abstract class RelayChannel {
  /// 入站文本帧流(relay 发来的 JSON 字符串)。
  Stream<String> get messages;

  /// 发一条出站文本帧。
  void send(String data);

  /// 关闭通道。
  Future<void> close();
}

/// 基于 `web_socket_channel` 的真实实现。
class WebSocketRelayChannel implements RelayChannel {
  WebSocketRelayChannel(this._channel);
  final WebSocketChannel _channel;

  factory WebSocketRelayChannel.connect(Uri url) =>
      WebSocketRelayChannel(WebSocketChannel.connect(url));

  @override
  Stream<String> get messages =>
      _channel.stream.map((dynamic e) => e.toString());

  @override
  void send(String data) => _channel.sink.add(data);

  @override
  Future<void> close() => _channel.sink.close();
}
