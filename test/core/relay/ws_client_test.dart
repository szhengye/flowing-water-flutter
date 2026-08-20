import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/relay/messages.dart';
import 'package:flowing_water/core/relay/ws_client.dart';

import 'fake_relay_channel.dart';

/// WsClient 行为测试 —— 握手 / 心跳 / 重连 / 入站转发 / 停止。
///
/// 时间依赖(provider_info 延迟 / 心跳间隔 / 退避)全部注入为极小值,用真实定时器,
/// 不依赖 FakeAsync。退避注入固定 Duration.zero,握手延迟 Duration.zero。
void main() {
  WsClient newClient({
    required FakeRelayChannel Function() openChannel,
    String Function(String)? sign,
    List<WsPhase>? phases,
    Duration providerInfoDelay = Duration.zero,
    Duration heartbeatInterval = const Duration(milliseconds: 4),
    Duration Function(int)? backoff,
  }) {
    return WsClient(
      url: Uri.parse('ws://relay'),
      openChannel: (_) => openChannel(),
      address: '0xOwner',
      paymentAddress: '0xPayee',
      sign: sign ?? ((c) => '0xSig($c)'),
      providerInfo: () => const ProviderInfo(
        address: '0xOwner',
        paymentAddress: '0xPayee',
        models: [],
      ),
      providerInfoDelay: providerInfoDelay,
      heartbeatInterval: heartbeatInterval,
      backoff: backoff ?? ((_) => Duration.zero),
    )..phase.listen(phases?.add);
  }

  /// auth_ack challenge(success:false + challenge)。
  const challengeFrame =
      '{"type":"auth_ack","payload":{"success":false,"challenge":"c1"}}';
  String authAckSuccess() =>
      jsonEncode({'type': 'auth_ack', 'payload': {'success': true}});
  String authAckError(String e) =>
      jsonEncode({'type': 'auth_ack', 'payload': {'success': false, 'error': e}});

  test('握手成功:challenge → 发 auth(带签名)→ success → provider_info', () async {
    final fake = FakeRelayChannel();
    final client = newClient(openChannel: () => fake);

    client.start();
    await pump;

    fake.receive(challengeFrame);
    await pump;
    // challenge 到达 → 发 auth,签名 = sign(challenge)。
    final auth = decodeMessage(fake.sent.single) as Auth;
    expect(auth.address, '0xOwner');
    expect(auth.paymentAddress, '0xPayee');
    expect(auth.signature, '0xSig(c1)');

    fake.receive(authAckSuccess());
    await pump;
    await pump; // provider_info 经 Future.delayed(0) 发出,需多泵一轮
    // 成功后发 provider_info(延迟注入为 0)。
    final info = decodeMessage(fake.sent.last) as ProviderInfo;
    expect(info.address, '0xOwner');
  });

  test('auth 失败:auth_ack error → authFailed,不发 provider_info,不重连', () async {
    final fake = FakeRelayChannel();
    final phases = <WsPhase>[];
    final client = newClient(
      openChannel: () => fake,
      sign: (c) => '0xSig($c)',
      phases: phases,
    );

    client.start();
    await pump;
    fake.receive(challengeFrame);
    await pump;
    expect(fake.sent.single, contains('"type":"auth"'));
    fake.sent.clear();

    fake.receive(authAckError('bad signature'));
    await pump;
    expect(phases, contains(WsPhase.authFailed));
    expect(fake.sent, isEmpty, reason: 'auth 失败不应再发 provider_info');
  });

  test('心跳:connected 后按 interval 发 heartbeat', () async {
    final fake = FakeRelayChannel();
    final client = newClient(
      openChannel: () => fake,
      heartbeatInterval: const Duration(milliseconds: 4),
    );

    client.start();
    await pump;
    fake.receive(challengeFrame);
    await pump;
    fake.receive(authAckSuccess());
    await pump;

    // 等待超过若干个心跳周期。
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final heartbeats = fake.sent
        .map(decodeMessage)
        .whereType<Heartbeat>()
        .toList();
    expect(heartbeats, isNotEmpty, reason: '连接成功后应周期发心跳');
  });

  test('入站转发:connected 后的非心跳消息转发到 inbound', () async {
    final fake = FakeRelayChannel();
    final client = newClient(openChannel: () => fake);
    final inbound = <RelayMessage>[];
    client.inbound.listen(inbound.add);

    client.start();
    await pump;
    fake.receive(challengeFrame);
    await pump;
    fake.receive(authAckSuccess());
    await pump;

    // 一条 LLM 业务消息(02 已把 llm_request 提升为强类型 LlmRequestMessage,验证转发通路)。
    fake.receive(
      '{"type":"llm_request","payload":{"requestId":"r1",'
      '"request":{"model":"m","messages":[]}}}',
    );
    await pump;

    expect(inbound, hasLength(1));
    expect((inbound.single as LlmRequestMessage).requestId, 'r1');
  });

  test('重连:服务端断开 → reconnecting → 退避后开新通道重新握手', () async {
    final fakes = <FakeRelayChannel>[];
    final phases = <WsPhase>[];
    final client = newClient(
      openChannel: () {
        final f = FakeRelayChannel();
        fakes.add(f);
        return f;
      },
      phases: phases,
      heartbeatInterval: const Duration(minutes: 1), // 避免噪音
    );

    client.start();
    await pump;
    fakes.single.receive(challengeFrame);
    await pump;
    fakes.single.receive(authAckSuccess());
    await pump;
    expect(phases, contains(WsPhase.connected));

    // 服务端断开。
    fakes.single.closeFromServer();
    await pump; // 触发 onDone → 调度重连
    await pump; // 退避(注入 0)后 _connect 执行

    expect(phases, containsAll([WsPhase.reconnecting, WsPhase.connecting]));
    expect(fakes, hasLength(2), reason: '重连应打开一个新通道');
  });

  test('停止:主动 stop → stopped,断开后不重连', () async {
    final fakes = <FakeRelayChannel>[];
    final phases = <WsPhase>[];
    final client = newClient(
      openChannel: () {
        final f = FakeRelayChannel();
        fakes.add(f);
        return f;
      },
      phases: phases,
    );

    client.start();
    await pump;
    await client.stop();
    await pump;

    expect(phases, contains(WsPhase.stopped));
    final countAfterStop = fakes.length;
    // 停止后再等一会儿,不应再开新通道。
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(fakes.length, countAfterStop);
  });

  test('心跳 RTT(04):发心跳后收回包 → latency 发非负;停止清零', () async {
    final fake = FakeRelayChannel();
    final client = newClient(openChannel: () => fake);
    final latencies = <int?>[];
    client.latency.listen(latencies.add);

    client.start();
    await pump;
    fake.receive(challengeFrame);
    await pump;
    fake.receive(authAckSuccess());
    await pump;
    await pump;
    // 等心跳发出(4ms 周期)——发送时置 _heartbeatSentMs。
    await Future<void>.delayed(const Duration(milliseconds: 12));
    final sentHb = fake.sent
        .map((s) {
          try {
            return decodeMessage(s);
          } catch (_) {
            return null;
          }
        })
        .whereType<Heartbeat>()
        .toList();
    expect(sentHb, isNotEmpty, reason: '连接后应发心跳');

    // 回一个 heartbeat 包 → 按 now - 发送时刻 算 RTT。
    fake.receive(encodeMessage(Heartbeat(0)));
    await pump;
    expect(latencies.whereType<int>(), isNotEmpty);
    expect(latencies.whereType<int>().last, greaterThanOrEqualTo(0));

    // 停止 → latency 发 null(pill 回到无延迟)。
    await client.stop();
    await pump;
    expect(latencies, contains(null));

    client.dispose();
  });
}

/// 泵一轮微任务/零延迟定时器。
Future<void> get pump => Future<void>.delayed(Duration.zero);
