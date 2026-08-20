import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/crypto/identity_store.dart';
import 'package:flowing_water/core/crypto/secure_vault.dart';
import 'package:flowing_water/core/db/database.dart';

/// 内存 fake Keychain —— 让 IdentityStore 的持久化逻辑脱离真实平台可测。
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

void main() {
  late AppDatabase db;
  late IdentityStore store;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = IdentityStore(db, _FakeVault());
  });
  tearDown(() => db.close());

  // 身份存在的判定决定「首次 modal 是否触发」,读错会让已有供应商被逼重新生成身份
  // (丢失链上地址)——这是不可逆的,所以持久化往返必须被钉死。
  group('身份持久化', () {
    test('初始无身份 → hasIdentity 为 false', () async {
      expect(await store.hasIdentity(), isFalse);
    });

    test('保存身份后 hasIdentity 为 true,且可读地址与密文', () async {
      await store.saveIdentity(
        encryptedMnemonic: 'CIPHERTEXT_BLOB',
        addressEip55: '0x58A57ed9d8d624cBD12e2C467D34787555bB1b25',
      );

      expect(await store.hasIdentity(), isTrue);
      expect(
        await store.readAddress(),
        '0x58A57ed9d8d624cBD12e2C467D34787555bB1b25',
      );
      expect(await store.readEncryptedMnemonic(), 'CIPHERTEXT_BLOB');
    });

    test('再次保存覆盖旧身份(同一供应商重设密码)', () async {
      await store.saveIdentity(
          encryptedMnemonic: 'OLD', addressEip55: '0x58A57ed9d8d624cBD12e2C467D34787555bB1b25');
      await store.saveIdentity(
          encryptedMnemonic: 'NEW', addressEip55: '0x58A57ed9d8d624cBD12e2C467D34787555bB1b25');

      expect(await store.readEncryptedMnemonic(), 'NEW');
    });

    test('清除身份后回到无身份状态', () async {
      await store.saveIdentity(
          encryptedMnemonic: 'X', addressEip55: '0x58A57ed9d8d624cBD12e2C467D34787555bB1b25');

      await store.clear();

      expect(await store.hasIdentity(), isFalse);
      expect(await store.readAddress(), isNull);
      expect(await store.readEncryptedMnemonic(), isNull);
    });
  });

  // 解锁凭证存 Keychain 是「自动恢复」的唯一来源;存取必须可靠,否则桌面默认开启的
  // 自动恢复会静默失效,用户每次冷启动都被迫手输密码。
  group('Keychain 解锁凭证', () {
    test('写入 / 读取 / 删除', () async {
      await store.writeUnlockPassword('pw123');

      expect(await store.readUnlockPassword(), 'pw123');

      await store.deleteUnlockPassword();

      expect(await store.readUnlockPassword(), isNull);
    });

    test('清除身份同时清除解锁凭证(重置干净)', () async {
      await store.saveIdentity(
          encryptedMnemonic: 'X', addressEip55: '0x58A57ed9d8d624cBD12e2C467D34787555bB1b25');
      await store.writeUnlockPassword('pw');

      await store.clear();

      expect(await store.readUnlockPassword(), isNull);
    });
  });
}
