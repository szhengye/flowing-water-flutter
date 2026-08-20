import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/crypto/aes_gcm.dart';
import 'package:flowing_water/core/crypto/identity_controller.dart';
import 'package:flowing_water/core/crypto/identity_store.dart';
import 'package:flowing_water/core/crypto/secure_vault.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/providers.dart';

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

// 已知合法助记词(10 向量)——派生地址确定,便于断言身份落地。
const _kMnemonic =
    'legal winner thank year wave sausage worth useful legal winner thank yellow';

ProviderContainer _container({required AppDatabase db, required SecureVault vault}) {
  final c = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(db),
    secureVaultProvider.overrideWithValue(vault),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  late AppDatabase db;
  late _FakeVault vault;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    vault = _FakeVault();
  });
  tearDown(() => db.close());

  // 状态机是「首次 modal / 解锁屏 / 正常后台」三态切换的权威。任一转移出错都会让
  // 供应商要么被逼重生成身份(丢链上地址),要么明文/密钥在不该在的时机驻留。
  group('bootstrap(冷启动)', () {
    test('无身份 → none', () async {
      final c = _container(db: db, vault: vault);

      final state = await c.read(identityControllerProvider.future);

      expect(state.status, IdentityStatus.none);
    });

    test('有身份且 Keychain 存了解锁凭证 → 自动恢复为 unlocked', () async {
      // 预置身份 + 自动恢复凭证(模拟上一次会话已设过)
      final seed = IdentityStore(db, vault);
      await seed.saveIdentity(
        encryptedMnemonic: encryptSecret(_kMnemonic, 'pw'),
        addressEip55: '0x58A57ed9d8d624cBD12e2C467D34787555bB1b25',
      );
      await seed.writeUnlockPassword('pw');

      final c = _container(db: db, vault: vault);

      final state = await c.read(identityControllerProvider.future);

      expect(state.status, IdentityStatus.unlocked);
      expect(state.keypair, isNotNull);
      expect(state.addressEip55, '0x58A57ed9d8d624cBD12e2C467D34787555bB1b25');
    });

    test('有身份但无自动恢复凭证 → locked(等待手输密码)', () async {
      final seed = IdentityStore(db, vault);
      await seed.saveIdentity(
        encryptedMnemonic: encryptSecret(_kMnemonic, 'pw'),
        addressEip55: '0x58A57ed9d8d624cBD12e2C467D34787555bB1b25',
      );
      // 故意不写解锁凭证

      final c = _container(db: db, vault: vault);

      final state = await c.read(identityControllerProvider.future);

      expect(state.status, IdentityStatus.locked);
      expect(state.keypair, isNull);
      expect(state.addressEip55, '0x58A57ed9d8d624cBD12e2C467D34787555bB1b25');
    });
  });

  group('生成 / 恢复 / 解锁 转移', () {
    test('generate 生成新身份 → unlocked 且落盘,密钥仅在内存', () async {
      final c = _container(db: db, vault: vault);
      await c.read(identityControllerProvider.future); // bootstrap(none)

      await c.read(identityControllerProvider.notifier).generate(
            password: 'pw',
            autoRecover: true,
          );

      final s = c.read(identityControllerProvider).requireValue;
      expect(s.status, IdentityStatus.unlocked);
      expect(s.addressEip55, isNotEmpty);
      expect(s.keypair, isNotNull);

      // 身份已落盘;且自动恢复凭证已写 Keychain
      final store = IdentityStore(db, vault);
      expect(await store.hasIdentity(), isTrue);
      expect(await store.readUnlockPassword(), 'pw');
    });

    test('recover 用既有助记词导入 → unlocked 且地址与派生一致', () async {
      final c = _container(db: db, vault: vault);
      await c.read(identityControllerProvider.future);

      await c.read(identityControllerProvider.notifier).recover(
            mnemonic: _kMnemonic,
            password: 'pw',
            autoRecover: false,
          );

      final s = c.read(identityControllerProvider).requireValue;
      expect(s.status, IdentityStatus.unlocked);
      expect(s.addressEip55, '0x58A57ed9d8d624cBD12e2C467D34787555bB1b25');
    });

    test('recover 拒绝非法助记词(不落盘,不留半截身份)', () async {
      final c = _container(db: db, vault: vault);
      await c.read(identityControllerProvider.future);

      await expectLater(
        c.read(identityControllerProvider.notifier).recover(
              mnemonic: 'not a valid mnemonic at all',
              password: 'pw',
            ),
        throwsA(isA<ArgumentError>()),
      );

      expect(await IdentityStore(db, vault).hasIdentity(), isFalse);
    });

    test('lock 后 unlock:错密码抛 DecryptionException,正确密码转 unlocked', () async {
      final c = _container(db: db, vault: vault);
      await c.read(identityControllerProvider.future);
      await c
          .read(identityControllerProvider.notifier)
          .generate(password: 'correct', autoRecover: false);

      await c.read(identityControllerProvider.notifier).lock();
      expect(c.read(identityControllerProvider).requireValue.status,
          IdentityStatus.locked);

      // 错密码:状态保持 locked,抛 DecryptionException
      await expectLater(
        c.read(identityControllerProvider.notifier).unlock(password: 'wrong'),
        throwsA(isA<DecryptionException>()),
      );
      expect(c.read(identityControllerProvider).requireValue.status,
          IdentityStatus.locked);

      // 正确密码
      await c.read(identityControllerProvider.notifier).unlock(password: 'correct');
      expect(c.read(identityControllerProvider).requireValue.status,
          IdentityStatus.unlocked);
    });
  });
}
