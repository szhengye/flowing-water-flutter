import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/crypto/aes_gcm.dart';
import 'package:flowing_water/core/crypto/identity_controller.dart';
import 'package:flowing_water/core/crypto/identity_store.dart';
import 'package:flowing_water/core/crypto/secure_vault.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/providers.dart';
import 'package:flowing_water/core/relay/messages.dart';
import 'package:flowing_water/core/relay/node_service.dart';
import 'package:flowing_water/core/relay/ws_client.dart';

import 'fake_relay_channel.dart';

class _FakeVault implements SecureVault {
  final Map<String, String> _m = {};
  @override
  Future<void> write({required String key, required String value}) async =>
      _m[key] = value;
  @override
  Future<String?> read({required String key}) async => _m[key];
  @override
  Future<void> delete({required String key}) async => _m.remove(key);
}

const _kMnemonic =
    'legal winner thank year wave sausage worth useful legal winner thank yellow';
const _kAddress = '0x58A57ed9d8d624cBD12e2C467D34787555bB1b25';

const _challengeFrame =
    '{"type":"auth_ack","payload":{"success":false,"challenge":"c1"}}';
String _authAckSuccess() =>
    jsonEncode({'type': 'auth_ack', 'payload': {'success': true}});

void main() {
  group('nodeStatusFromPhase 映射', () {
    test('7 个 WsPhase 映射到 6 个 NodeStatus', () {
      expect(nodeStatusFromPhase(WsPhase.idle), NodeStatus.stopped);
      expect(nodeStatusFromPhase(WsPhase.stopped), NodeStatus.stopped);
      expect(nodeStatusFromPhase(WsPhase.connecting), NodeStatus.connecting);
      expect(
          nodeStatusFromPhase(WsPhase.authenticating), NodeStatus.authenticating);
      expect(nodeStatusFromPhase(WsPhase.connected), NodeStatus.connected);
      expect(nodeStatusFromPhase(WsPhase.reconnecting), NodeStatus.reconnecting);
      expect(nodeStatusFromPhase(WsPhase.authFailed), NodeStatus.failed);
    });
  });

  group('NodeService 身份门禁 + 握手 + provider_info', () {
    late AppDatabase db;
    late _FakeVault vault;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      vault = _FakeVault();
    });
    tearDown(() => db.close());

    test('unlocked → 起客户端握手;provider_info 含 provider_quotation 模型', () async {
      // 预置身份(自动恢复 → unlocked)+ 两行报价。
      final store = IdentityStore(db, vault);
      await store.saveIdentity(
        encryptedMnemonic: encryptSecret(_kMnemonic, 'pw'),
        addressEip55: _kAddress,
      );
      await store.writeUnlockPassword('pw');
      await db.into(db.providerQuotations).insert(
            ProviderQuotationsCompanion(
              relayModelName: const Value('m1'),
              inputPricePer1k: const Value(1),
              outputPricePer1k: const Value(2),
            ),
          );
      await db.into(db.providerQuotations).insert(
            ProviderQuotationsCompanion(
              relayModelName: const Value('m2'),
              inputPricePer1k: const Value(3),
              outputPricePer1k: const Value(4),
            ),
          );

      final fakes = <FakeRelayChannel>[];
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        secureVaultProvider.overrideWithValue(vault),
        relayChannelFactoryProvider.overrideWithValue((_) {
          final f = FakeRelayChannel();
          fakes.add(f);
          return f;
        }),
      ]);
      addTearDown(container.dispose);

      // 身份 bootstrap → unlocked;然后激活 NodeService。
      await container.read(identityControllerProvider.future);
      container.read(nodeServiceProvider);
      // _start 异步加载模型 + 建客户端:给事件循环一点时间。
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(fakes, hasLength(1), reason: 'unlocked 应起一个客户端');

      final fake = fakes.single;
      // 驱动握手:challenge → auth → success。
      fake.receive(_challengeFrame);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fake.sent.any((s) => s.contains('"type":"auth"')), isTrue);

      fake.receive(_authAckSuccess());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(container.read(nodeStatusProvider), NodeStatus.connected);

      // provider_info 在握手成功后 500ms 发出(WS 默认延迟)。
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final info = fake.sent
          .map(decodeMessage)
          .whereType<ProviderInfo>()
          .single;
      expect(info.models.map((m) => m.relayModel), ['m1', 'm2']);
      expect(info.models.first.inputPricePer1k, 1);
    });

    test('locked → 不起客户端(stopped)', () async {
      // 无身份 → bootstrap 为 none(非 unlocked)。
      final fakes = <FakeRelayChannel>[];
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        secureVaultProvider.overrideWithValue(vault),
        relayChannelFactoryProvider.overrideWithValue((_) {
          final f = FakeRelayChannel();
          fakes.add(f);
          return f;
        }),
      ]);
      addTearDown(container.dispose);

      await container.read(identityControllerProvider.future); // → none
      expect(container.read(nodeServiceProvider).status, NodeStatus.stopped);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(fakes, isEmpty, reason: '身份未解锁不应连接中转站');
    });
  });
}
