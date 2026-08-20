import 'package:flutter_test/flutter_test.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flowing_water/core/crypto/signing.dart';

// viem 参考向量(ticket 10,spikes/crypto-interop/vectors.json)。
// Dart 的 EIP-191 签名必须与 viem 逐字节一致 —— 否则中转站 verifyMessage 无法从签名
// 恢复出 claimed address,WS 鉴权直接失败。这是 M2 握手的前提,M1 先锁定。
const _kTestPrivateKey =
    '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';
const _kFixedMessage = 'flowing-water interop check: Dart<->viem EIP-191';
const _kFixedSignatureViem =
    '0xfd592fb82b6a7d3ca7e9bf91a986cf3cd5c29fe58939b9c3a27f64be8d5f04363d05e95cf4fd8004f03787d6599856b80f43cddb0b11aed52deb5d96b331b4671c';

void main() {
  test('EIP-191 签名逐字节与 viem 一致(确定性 RFC 6979)', () {
    final credentials = EthPrivateKey.fromHex(_kTestPrivateKey);

    final signature = signPersonalMessage(_kFixedMessage, credentials);

    expect(signature, _kFixedSignatureViem,
        reason: '签名必须与 viem 逐字节相同,中转站 verifyMessage 才能恢复出 claimed address');
  });
}
