// relay WS 握手冒烟 spike — wayfinder ticket 04。
//
// 对本地中转站(relay-server)做一次完整 WS 握手:
//   连上 → 收 auth_ack{success:false, challenge} → EIP-191 签 challenge 原文
//   → 发 auth{address, paymentAddress, signature} → 等 auth_ack{success:true}。
//
// 测试供应商 keypair 每次随机生成(BIP-39 12 词 → m/44'/60'/0'/0/0)。
// 加密栈与 viem 互通已由 ticket 10 实测;本 spike 验证真实握手链路。
//
// 协议权威:web3-api/packages/shared/src/protocol/messages.ts
// 时序/字段坑:见 .scratch/supplier-portal/assets/03-dart-ws-protocol-findings.md §A。
//
// 用法:
//   dart pub get
//   dart run bin/handshake.dart                      # 默认 ws://localhost:3003
//   dart run bin/handshake.dart ws://localhost:4000  # 指定 URL
//
// 退出码:0 = 握手成功;1 = 失败/超时。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 握手必须在 30s 内拿到 auth_ack{success:true}(challenge TTL 60s,留余量)。
const Duration _authTimeout = Duration(seconds: 30);

Future<void> main(List<String> args) async {
  final wsUrl = args.isNotEmpty ? args.first : 'ws://localhost:3003';

  // 1. 随机测试供应商 keypair:BIP-39 12 词 → BIP-32 m/44'/60'/0'/0/0。
  final mnemonic = bip39.generateMnemonic(); // 128bit = 12 词
  final seed = bip39.mnemonicToSeed(mnemonic);
  final child = bip32.BIP32.fromSeed(seed).derivePath("m/44'/60'/0'/0/0");
  final pkBytes = Uint8List.fromList(child.privateKey!);
  final credentials = EthPrivateKey.fromHex(_to0xHex(pkBytes));
  final addressEip55 = credentials.address.hexEip55;

  print('━━━ WS 握手冒烟 (ticket 04) ━━━');
  print('relay WS URL     : $wsUrl');
  print('mnemonic (测试用) : $mnemonic');
  print('  ↳ 仅本次冒烟生成,勿复用为真实供应商身份');
  print('address (EIP-55) : $addressEip55');
  print('────────────────────────────────────────');

  // 2. 连 WS。连接建立后服务端会主动推 auth_ack{success:false, challenge}。
  final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
  print('[connect] WS 已发起,等待 challenge…');

  final result = Completer<_Outcome>();
  var authed = false;
  late StreamSubscription sub;

  void fail(String reason) {
    if (!result.isCompleted) result.complete(_Outcome(false, reason));
  }

  final authTimer = Timer(_authTimeout, () {
    if (!authed) fail('auth 超时(${_authTimeout.inSeconds}s 内未收到 auth_ack{success:true})');
  });

  sub = channel.stream.listen(
    (raw) {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = msg['type'] as String?;
      if (type != 'auth_ack') {
        // auth 之后可能收到心跳回包等;本冒烟只验握手,记录即忽略。
        print('[recv] $type (auth 后消息,本冒烟忽略)');
        return;
      }
      final p =
          (msg['payload'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
      final success = p['success'] == true;
      final challenge = p['challenge'] as String?;
      final error = p['error'] as String?;

      // 3-4. challenge 阶段:收明文 SIWE 字符串 → 对 UTF-8 字节 EIP-191 签名。
      if (!authed && challenge != null && !success) {
        _printChallenge(challenge);
        final sig = _ensure0x(EthSigUtil.signPersonalMessage(
          message: Uint8List.fromList(utf8.encode(challenge)),
          privateKeyInBytes: pkBytes,
        ));
        // 5. 发 auth。paymentAddress 缺省回退到 address(findings A.4 / F.5 #13)。
        print('[send] auth{address=$addressEip55, signature=${_short(sig)}}');
        channel.sink.add(jsonEncode({
          'type': 'auth',
          'payload': {
            'address': addressEip55,
            'paymentAddress': addressEip55,
            'signature': sig,
          },
        }));
        return;
      }

      // 6a. 成功。
      if (success) {
        authed = true;
        print('[recv] auth_ack{success:true} ✅  鉴权通过');
        // post-auth 探活:发 provider_info + 心跳,证明已认证通道可用。
        // 服务端对 provider_info 不回 ack(findings B.3);心跳会原样回一条。
        _sendProviderInfo(channel, addressEip55);
        _sendHeartbeat(channel);
        if (!result.isCompleted) result.complete(_Outcome(true, 'auth_ack{success:true}'));
        return;
      }

      // 6b. 失败。
      if (error != null) {
        print('[recv] auth_ack{success:false, error="$error"}');
        fail('中转站拒绝鉴权: $error');
        return;
      }
      fail('auth_ack 异常状态: ${jsonEncode(msg)}');
    },
    onError: (Object e) => fail('stream error: $e'),
    onDone: () {
      if (!authed) fail('连接在握手完成前关闭(对端关闭/拒绝/端口不通)');
    },
    cancelOnError: true,
  );

  final outcome = await result.future;
  authTimer.cancel();

  // 握手成功则多留 2.5s 观察心跳回包(证明双向通道),然后关闭。
  if (outcome.ok) {
    print('[probe] 等待 2.5s 观察心跳回包(可选)…');
    await Future<void>.delayed(const Duration(milliseconds: 2500));
  }
  await sub.cancel();
  await channel.sink.close();

  print('────────────────────────────────────────');
  if (outcome.ok) {
    print('✅ 握手成功 — connect → challenge → EIP-191 sign → auth → auth_ack{success:true}');
    exit(0);
  } else {
    print('❌ 握手失败 — ${outcome.reason}');
    exit(1);
  }
}

void _sendProviderInfo(WebSocketChannel channel, String addressEip55) {
  channel.sink.add(jsonEncode({
    'type': 'provider_info',
    'payload': {
      'address': addressEip55,
      'paymentAddress': addressEip55,
      // 字段名只发 relayModel(服务端只读它,TS 多发的 name 被忽略 — findings A.5/F.5 #2)。
      'models': [
        {
          'relayModel': 'gpt-4o-mini-smoke',
          'inputPricePer1k': 1,
          'outputPricePer1k': 2,
        },
      ],
      'supportsStream': true,
    },
  }));
  print('[send] provider_info{gpt-4o-mini-smoke} — 服务端无 ack 属正常');
}

void _sendHeartbeat(WebSocketChannel channel) {
  channel.sink.add(jsonEncode({
    'type': 'heartbeat',
    'payload': {'timestamp': DateTime.now().millisecondsSinceEpoch},
  }));
  print('[send] heartbeat');
}

void _printChallenge(String challenge) {
  print('[recv] auth_ack challenge(${challenge.length} 字符):');
  final top = '┌${'─' * 60}';
  final bot = '└${'─' * 60}';
  print('       $top');
  for (final line in challenge.split('\n')) {
    print('       │ $line');
  }
  print('       $bot');
}

String _short(String hex) {
  if (hex.length <= 18) return hex;
  return '${hex.substring(0, 10)}…${hex.substring(hex.length - 8)}';
}

String _ensure0x(String hex) => hex.startsWith('0x') ? hex : '0x$hex';

String _to0xHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

class _Outcome {
  const _Outcome(this.ok, this.reason);
  final bool ok;
  final String reason;
}
