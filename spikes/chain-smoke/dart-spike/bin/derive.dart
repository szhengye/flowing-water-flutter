// ignore_for_file: avoid_print
// 由 operator 助记词(12 词)派生 m/44'/60'/0'/0/0 的私钥 + 地址(wayfinder settle 触发用)。
// 助记词从环境变量读,**不进代码/聊天**。地址应 = 链上 operator 0x38bb…b9854a。
//
// 用法:MNEMONIC="<12 个词>" dart run bin/derive.dart
import 'dart:io';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:web3dart/web3dart.dart';

void main() {
  final mn = Platform.environment['MNEMONIC'] ?? '';
  if (mn.isEmpty) {
    print('❌ 设 MNEMONIC="<12 词>"(部署合约时 cast wallet new-mnemonic 生成的那组)');
    exit(1);
  }
  if (!bip39.validateMnemonic(mn)) {
    print('❌ 助记词校验失败(checksum/词表)');
    exit(1);
  }
  final seed = bip39.mnemonicToSeed(mn);
  final child = bip32.BIP32.fromSeed(seed).derivePath("m/44'/60'/0'/0/0");
  final hex =
      child.privateKey!.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  final creds = EthPrivateKey.fromHex('0x$hex');
  print('address    = ${creds.address.hexEip55}');
  print('privateKey = 0x$hex');
  if (creds.address.hexEip55.toLowerCase() ==
      '0x38bb1239e6f64bbb5a20b8015349c468c3b9854a') {
    print('✅ 地址匹配链上 operator —— 这就是对的助记词');
  } else {
    print('⚠ 地址不等于 operator 0x38bb…b9854a(助记词可能不对,或用了别的派生路径)');
  }
}
