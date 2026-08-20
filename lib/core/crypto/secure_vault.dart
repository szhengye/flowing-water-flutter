import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// OS 级安全存储抽象(macOS Keychain / Windows Credential 等)。
///
/// 唯一用途:存「自动恢复」所需的**解锁凭证** —— **永不存助记词明文**。
/// 抽象出来是为了在测试中注入内存 fake(真实 Keychain 需平台环境,单元测试不可达)。
abstract class SecureVault {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
}

/// 基于 flutter_secure_storage 的实现(macOS = Keychain)。
class KeychainVault implements SecureVault {
  const KeychainVault([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);
}
