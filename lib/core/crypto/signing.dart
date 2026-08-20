import 'dart:convert';
import 'dart:typed_data';

import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:web3dart/web3dart.dart';

/// EIP-191 `personal_sign` 签名 —— 中转站 WS 鉴权的核心。
///
/// 对 [message] 的 UTF-8 字节施加 `\x19Ethereum Signed Message:\n`+len 前缀后
/// keccak256 → secp256k1,返回 r‖s‖v(65 字节,hex,`0x` 前缀)。
/// 确定性签名(RFC 6979)→ 与 viem 逐字节一致(wayfinder 10 已实测)。
///
/// 用途(M2):收中转站 `auth_ack.challenge` 字符串,对其原文 UTF-8 字节调用本函数,
/// 中转站 `verifyMessage` 从签名恢复地址并比对 claimed address。
String signPersonalMessage(String message, EthPrivateKey credentials) {
  final msgBytes = Uint8List.fromList(utf8.encode(message));
  return EthSigUtil.signPersonalMessage(
    message: msgBytes,
    privateKeyInBytes: credentials.privateKey,
  );
}
