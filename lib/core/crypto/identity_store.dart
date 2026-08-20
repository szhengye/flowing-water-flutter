import 'package:drift/drift.dart';

import 'package:flowing_water/core/crypto/secure_vault.dart';
import 'package:flowing_water/core/db/database.dart';

/// 供应商身份的持久化仓库。
///
/// drift `settings` K-V 表存「AES 加密助记词密文 + 派生地址」;
/// Keychain([SecureVault])存「解锁凭证」(自动恢复用,桌面默认开启)。
///
/// **永不持久化助记词明文** —— 落盘的只有密文;明文仅在不解锁时的内存中短暂存在。
/// 身份存在的判定(`hasIdentity`)决定「首次强制 modal」是否触发,读错会让已有供应商
/// 被逼重新生成身份 → 丢失链上地址(不可逆),故往返必须可靠。
class IdentityStore {
  IdentityStore(this._db, this._vault);

  final AppDatabase _db;
  final SecureVault _vault;

  static const _kEncryptedMnemonic = 'encrypted_mnemonic';
  static const _kProviderAddress = 'provider_address';
  static const _kUnlockPassword = 'unlock_password';

  /// 是否已存在供应商身份(密文已落盘)。
  Future<bool> hasIdentity() async =>
      (await readEncryptedMnemonic()) != null;

  /// 保存(或覆盖)身份。重置密码场景下会覆盖同地址的旧密文。
  Future<void> saveIdentity({
    required String encryptedMnemonic,
    required String addressEip55,
  }) async {
    await _write(_kEncryptedMnemonic, encryptedMnemonic);
    await _write(_kProviderAddress, addressEip55);
  }

  Future<String?> readEncryptedMnemonic() => _read(_kEncryptedMnemonic);
  Future<String?> readAddress() => _read(_kProviderAddress);

  Future<void> writeUnlockPassword(String password) =>
      _vault.write(key: _kUnlockPassword, value: password);
  Future<String?> readUnlockPassword() => _vault.read(key: _kUnlockPassword);
  Future<void> deleteUnlockPassword() => _vault.delete(key: _kUnlockPassword);

  /// 清除身份 + 解锁凭证(完全重置)。
  Future<void> clear() async {
    await _delete(_kEncryptedMnemonic);
    await _delete(_kProviderAddress);
    await deleteUnlockPassword();
  }

  // --- drift settings K-V helpers ---

  Future<String?> _read(String key) async {
    final row = await (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> _write(String key, String value) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion(key: Value(key), value: Value(value)),
        );
  }

  Future<void> _delete(String key) async {
    await (_db.delete(_db.appSettings)..where((t) => t.key.equals(key))).go();
  }
}
