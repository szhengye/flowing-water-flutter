import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/crypto/aes_gcm.dart';

void main() {
  // 加密的是供应商助记词 —— 一旦密文能被错密码解开或可被还原成明文之外的任何东西,
  // 就等于私钥泄露。GCM 的 tag 校验是「错密码必败」的硬保证。
  group('AES-256-GCM 助记词加密', () {
    const mnemonic =
        'legal winner thank year wave sausage worth useful legal winner thank yellow';
    const password = 'correct horse battery staple';

    test('往返:解密(加密(明文, 密码), 密码) == 原始助记词', () {
      final ciphertext = encryptSecret(mnemonic, password);

      expect(ciphertext, isNot(equals(mnemonic)), reason: '密文不能是明文');
      expect(decryptSecret(ciphertext, password), mnemonic);
    });

    test('每次加密产生不同密文(随机 salt / iv)', () {
      final a = encryptSecret(mnemonic, password);
      final b = encryptSecret(mnemonic, password);

      expect(a, isNot(equals(b)),
          reason: '相同明文重复加密必须不同(随机 salt/iv),否则等同 ECB');
    });

    test('错误密码无法解密 —— 抛 DecryptionException(GCM tag 校验失败)', () {
      final ciphertext = encryptSecret(mnemonic, password);

      expect(() => decryptSecret(ciphertext, 'wrong password'),
          throwsA(isA<DecryptionException>()));
    });

    test('密文为 base64,解码后长度 = 16(salt) + 12(iv) + 明文 + 16(tag)', () {
      const tenBytes = '0123456789';
      final blob = base64.decode(encryptSecret(tenBytes, 'pw'));

      expect(blob.length, 16 + 12 + 10 + 16);
    });
  });
}
