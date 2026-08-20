import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/crypto/keypair.dart';

// viem 交叉验证参考向量(ticket 10,spikes/crypto-interop/vectors.json)。
// 同一助记词在 Dart 派生的地址必须与 viem 逐字节一致 → 这是 WS 鉴权身份互通的前提。
const _kMnemonic =
    'legal winner thank year wave sausage worth useful legal winner thank yellow';
const _kDerivedAddress = '0x58A57ed9d8d624cBD12e2C467D34787555bB1b25';

void main() {
  group('mnemonic 生成与校验', () {
    test('生成的 12 词助记词能通过自身校验', () {
      final mnemonic = generateMnemonic();
      final words = mnemonic.split(' ');

      expect(words.length, 12, reason: 'BIP-39 128-bit 熵 → 恰好 12 词');
      expect(isValidMnemonic(mnemonic), isTrue,
          reason: '新生成助记词必须通过 checksum(否则生成即坏)');
    });

    test('接受合法助记词,拒绝坏 checksum / 非词表 / 错长度', () {
      // 合法参考向量
      expect(isValidMnemonic(_kMnemonic), isTrue);

      // abandon×11 + about 是全零熵的唯一合法组合 → abandon×12 必然 checksum 不符。
      // 这条确定性失败证明校验了 checksum(wayfinder 01 坑 #3:拼错词会派生「幽灵地址」)。
      const badChecksum =
          'abandon abandon abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon';
      expect(isValidMnemonic(badChecksum), isFalse,
          reason: 'checksum 不符必须被拒,杜绝幽灵地址');

      // 非词表乱码
      expect(isValidMnemonic('zzz zzz zzz zzz zzz zzz zzz zzz zzz zzz zzz zzz'),
          isFalse);
      // 词数错
      expect(isValidMnemonic('legal winner thank year wave sausage'), isFalse);
    });
  });

  group('身份派生', () {
    test('派生的 EIP-55 地址与 viem 参考向量逐字节一致', () {
      final identity = deriveIdentity(_kMnemonic);

      expect(identity.addressEip55, _kDerivedAddress,
          reason: "m/44'/60'/0'/0/0 必须与 viem 一致(EIP-55 混合大小写)");
    });

    test('同一助记词派生是确定性的(重复派生地址不变)', () {
      expect(deriveIdentity(_kMnemonic).addressEip55,
          deriveIdentity(_kMnemonic).addressEip55);
    });
  });
}
