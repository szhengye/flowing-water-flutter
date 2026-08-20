import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:web3dart/web3dart.dart';

/// 供应商身份 —— secp256k1 keypair,由 12 词 BIP-39 助记词按 `m/44'/60'/0'/0/0` 派生。
///
/// 助记词仅在生成 / 恢复时短暂存在于内存(只展示一次),**永不持久化明文**。
/// [credentials] 用于 WS 鉴权 EIP-191 签名与链上操作;[addressEip55] 是身份标识与收款地址。
/// (wayfinder 01 / 10:与 viem 互通已实测,派生路径与地址必须逐字节一致。)
class ProviderKeypair {
  const ProviderKeypair({
    required this.credentials,
    required this.addressEip55,
  });

  final EthPrivateKey credentials;
  final String addressEip55;
}

/// 生成 12 词 BIP-39 助记词(128-bit 熵)。
String generateMnemonic() => bip39.generateMnemonic();

/// 校验助记词:词表成员 + checksum。
///
/// wayfinder 01 坑 #3:必须校验 checksum,否则拼错词会派生出「幽灵地址」
/// (地址合法但与上游不一致,且无任何报错)。
bool isValidMnemonic(String mnemonic) => bip39.validateMnemonic(mnemonic);

/// 由助记词派生供应商身份(`m/44'/60'/0'/0/0` secp256k1)。
///
/// 抛 [ArgumentError] 当助记词非法——派生前应先 [isValidMnemonic]。
ProviderKeypair deriveIdentity(String mnemonic) {
  if (!isValidMnemonic(mnemonic)) {
    throw ArgumentError('非法助记词:checksum 或词表校验未通过');
  }
  final seed = bip39.mnemonicToSeed(mnemonic);
  final child = bip32.BIP32.fromSeed(seed).derivePath("m/44'/60'/0'/0/0");
  final pkHex = _toHex(child.privateKey!);
  final credentials = EthPrivateKey.fromHex('0x$pkHex');
  return ProviderKeypair(
    credentials: credentials,
    addressEip55: credentials.address.hexEip55,
  );
}

String _toHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
