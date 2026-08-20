import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// 本地机密(供应商助记词)的 AES-256-GCM 加密。
///
/// 格式(wayfinder 01):`base64( salt(16) + iv(12) + ciphertext + tag(16) )`。
/// key 由 password 经 **PBKDF2-SHA256 / 100k / 32B** 派生。
/// 这是非互通项(Dart 自定格式,仅本地存取),**永不持久化明文**。
///
/// GCM 的 16 字节 auth tag 提供「错密码必败」的硬保证 —— 任何篡改或密钥不匹配都会在
/// 解密时校验失败,杜绝「错密码解出乱码」的静默错误。

/// 解密失败(密码错误 / 密文损坏)的领域异常。UI 据此提示「密码错误」。
class DecryptionException implements Exception {
  const DecryptionException(this.message);
  final String message;
  @override
  String toString() => 'DecryptionException: $message';
}

/// 加密 [plaintext](助记词)→ base64 密文字符串。每次产生随机 salt/iv,密文互不相同。
String encryptSecret(String plaintext, String password) {
  final salt = _randomBytes(16);
  final iv = _randomBytes(12);
  final key = _deriveKey(password, salt);
  final cipherTextWithTag = _gcm(
    forEncryption: true,
    key: key,
    iv: iv,
    input: Uint8List.fromList(utf8.encode(plaintext)),
  );
  return base64.encode(
    Uint8List.fromList([...salt, ...iv, ...cipherTextWithTag]),
  );
}

/// 解密 [ciphertext](base64)→ 原文。密码错误或密文损坏抛 [DecryptionException]。
String decryptSecret(String ciphertext, String password) {
  final Uint8List blob;
  try {
    blob = base64.decode(ciphertext);
  } catch (_) {
    throw const DecryptionException('密文非合法 base64');
  }
  if (blob.length < 16 + 12 + 16) {
    throw const DecryptionException('密文长度异常');
  }
  final salt = Uint8List.fromList(blob.sublist(0, 16));
  final iv = Uint8List.fromList(blob.sublist(16, 28));
  final cipherTextWithTag = Uint8List.fromList(blob.sublist(28));
  final key = _deriveKey(password, salt);
  try {
    final plain = _gcm(
      forEncryption: false,
      key: key,
      iv: iv,
      input: cipherTextWithTag,
    );
    return utf8.decode(plain);
  } catch (_) {
    throw const DecryptionException('解密失败:密码错误或密文已损坏');
  }
}

Uint8List _deriveKey(String password, Uint8List salt) {
  final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
  pbkdf2.init(Pbkdf2Parameters(salt, 100000, 32));
  return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
}

Uint8List _gcm({
  required bool forEncryption,
  required Uint8List key,
  required Uint8List iv,
  required Uint8List input,
}) {
  final cipher = GCMBlockCipher(AESEngine());
  cipher.init(
      forEncryption, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
  final output = Uint8List(cipher.getOutputSize(input.length));
  var offset = cipher.processBytes(input, 0, input.length, output, 0);
  offset += cipher.doFinal(output, offset);
  return Uint8List.fromList(output.sublist(0, offset));
}

final _rng = Random.secure();
Uint8List _randomBytes(int n) =>
    Uint8List.fromList(List<int>.generate(n, (_) => _rng.nextInt(256)));
