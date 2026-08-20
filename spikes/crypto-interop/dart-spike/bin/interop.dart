// Dart<->viem crypto interop spike (ticket 10).
//
// Reads ../vectors.json (produced by Node/viem gen-vectors.mjs) and asserts:
//   1. mnemonic -> address at m/44'/60'/0'/0/0 matches viem's derived address.
//   2. test private key -> address matches the known Anvil #0 address.
//   3. EIP-191 personal_sign over the fixed message recovers to the signer
//      (Dart self-consistency). The signature is written to
//      ../dart-signature.txt for viem to cross-verify (verify-dart.mjs).
//
// Exit code 0 iff all checks pass.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:web3dart/web3dart.dart';
import 'package:eth_sig_util/eth_sig_util.dart';

/// Normalize an EVM address to lowercase, no 0x — for case/prefix-insensitive compare.
String norm(String addr) => addr.toLowerCase().replaceAll('0x', '');

String _toHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

List<int> _fromHex(String h) => [
      for (var i = 0; i < h.length; i += 2)
        int.parse(h.substring(i, i + 2), radix: 16),
    ];

void main() {
  final vectors =
      jsonDecode(File('../vectors.json').readAsStringSync()) as Map<String, dynamic>;

  final mnemonic = vectors['mnemonic'] as String;
  final expectedDerived = vectors['derivedAddress'] as String;
  final testPk = vectors['testPrivateKey'] as String;
  final expectedTestAddr = vectors['testAddress'] as String;
  final fixedMessage = vectors['fixedMessage'] as String;

  // 1. mnemonic -> address (BIP-39 seed + BIP-32 HD m/44'/60'/0'/0/0)
  final seed = bip39.mnemonicToSeed(mnemonic);
  final child = bip32.BIP32.fromSeed(seed).derivePath("m/44'/60'/0'/0/0");
  final pkHex = '0x${_toHex(child.privateKey!)}';
  final derivedAddr = EthPrivateKey.fromHex(pkHex).address.hex;
  check(
    '1. mnemonic->address (m/44\'/60\'/0\'/0/0)',
    norm(derivedAddr) == norm(expectedDerived),
    'Dart=$derivedAddr  viem=$expectedDerived',
  );

  // 2. test private key -> address (web3dart secp256k1 / keccak)
  final testAddr = EthPrivateKey.fromHex(testPk).address.hex;
  check(
    '2. testPrivKey->address (Anvil #0)',
    norm(testAddr) == norm(expectedTestAddr),
    'Dart=$testAddr  expected=$expectedTestAddr',
  );

  // 3. EIP-191 personal_sign + recover (Dart self-consistency)
  final msgBytes = Uint8List.fromList(utf8.encode(fixedMessage));
  final pkBytesRaw = Uint8List.fromList(_fromHex(testPk.substring(2)));
  final sig = EthSigUtil.signPersonalMessage(
    message: msgBytes,
    privateKeyInBytes: pkBytesRaw,
  );
  final recovered = EthSigUtil.recoverPersonalSignature(
    signature: sig,
    message: msgBytes,
  );
  check(
    '3. EIP-191 sign->recover (self-consistent)',
    norm(recovered) == norm(testAddr),
    'recovered=$recovered  signer=$testAddr',
  );

  // hand the Dart-produced signature to viem for cross-verification
  File('../dart-signature.txt').writeAsStringSync(sig);
  print('\nDart signature -> ../dart-signature.txt');
  print('  $sig');
  print('\nNext: `node ../verify-dart.mjs` (viem verifies this Dart signature).');
}

void check(String name, bool ok, String detail) {
  print('${ok ? "PASS" : "FAIL"}  $name');
  if (!ok) print('     $detail');
  if (!ok) exit(1);
}
