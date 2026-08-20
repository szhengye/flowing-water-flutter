// ignore_for_file: avoid_print
//
// 触发 RelayStationPolygon.settle()(wayfinder 05/08 端到端采集验证)。
// 只发 1 个 vendor 的 SettlementItem → emit Settled(vendor=…) → watcher 采集。
//
// 用法:
//   预检(无需私钥,eth_call 模拟):
//     VENDOR_ADDRESS=0x…  dart run bin/settle.dart
//   真发(需 operator 私钥,从环境读,不进代码):
//     VENDOR_ADDRESS=0x…  OPERATOR_PRIVATE_KEY=0x…  dart run bin/settle.dart
//   可选 SETTLE_AMOUNT(默认 100000 = 0.1 USDT,6 decimals)。
import 'dart:io';

import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

const rpc = 'https://polygon-amoy.g.alchemy.com/v2/jHk-yC9S0Pk-EDQumLF0L';
const contractHex = '0x08Eb4964b31D22D21e813aD8C7DD85EB0B3328A9';
const usdtHex = '0x88D654Bfaa1a993f0bf59b50e759a6afF8418AeC';
const operatorHex = '0x38bb1239e6f64bbb5a20b8015349c468c3b9854a';

const abi = '''
[{"name":"settle","type":"function","stateMutability":"nonpayable","inputs":[
  {"name":"token","type":"address"},
  {"name":"items","type":"tuple[]","components":[
    {"name":"vendor","type":"address"},
    {"name":"successCount","type":"uint32"},
    {"name":"amount","type":"uint256"},
    {"name":"notSuccessCount","type":"uint32"},
    {"name":"notSuccessAmount","type":"uint256"}
  ]}],"outputs":[]},
 {"anonymous":false,"name":"Settled","type":"event","inputs":[
  {"indexed":true,"name":"vendor","type":"address"},
  {"indexed":false,"name":"successCount","type":"uint32"},
  {"indexed":false,"name":"amount","type":"uint256"},
  {"indexed":false,"name":"notSuccessCount","type":"uint32"},
  {"indexed":false,"name":"notSuccessAmount","type":"uint256"},
  {"indexed":false,"name":"timestamp","type":"uint256"}]}]
''';

String hexOf(List<int> b) =>
    '0x${b.map((x) => x.toRadixString(16).padLeft(2, '0')).join()}';

Future<void> main() async {
  final env = Platform.environment;
  final vendor = env['VENDOR_ADDRESS'] ?? '';
  final opKey = env['OPERATOR_PRIVATE_KEY'] ?? '';
  final amountRaw =
      BigInt.parse(env['SETTLE_AMOUNT'] ?? '100000'); // 0.1 USDT (6 decimals)

  if (vendor.isEmpty) {
    print('❌ 请设 VENDOR_ADDRESS=0x… (= supplier-app 的 provider 地址,Keypair/Settings 页可见)');
    exit(1);
  }

  final client = Web3Client(rpc, Client());
  final contract = DeployedContract(
      ContractAbi.fromJson(abi, 'RelayStationPolygon'), EthereumAddress.fromHex(contractHex));
  final settleFn = contract.function('settle');
  final settledEv = contract.event('Settled');
  final usdt = EthereumAddress.fromHex(usdtHex);
  final vendorAddr = EthereumAddress.fromHex(vendor);
  final items = [
    [vendorAddr, BigInt.one, amountRaw, BigInt.zero, BigInt.zero],
  ];

  if (opKey.isEmpty) {
    // 预检:eth_call 以 operator 身份模拟 settle(无需私钥)。
    try {
      await client.call(
        contract: contract,
        function: settleFn,
        params: [usdt, items],
        sender: EthereumAddress.fromHex(operatorHex),
      );
      print('✅ eth_call 预检通过:settle 会成功'
          '(vendor=$vendor amount=$amountRaw raw=${amountRaw.toDouble() / 1e6} USDT)');
    } catch (e) {
      print('❌ eth_call 预检失败(可能余额/approve/编码问题):$e');
    }
    await client.dispose();
    return;
  }

  // 真发送。
  final creds = EthPrivateKey.fromHex(opKey);
  final chainId = (await client.getChainId()).toInt();
  final data = settleFn.encodeCall([usdt, items]);
  final gas = await client.estimateGas(
      sender: creds.address,
      to: EthereumAddress.fromHex(contractHex),
      data: data);
  final gasPrice = await client.getGasPrice();
  final hash = await client.sendTransaction(
    creds,
    Transaction(
      to: EthereumAddress.fromHex(contractHex),
      data: data,
      gasPrice: gasPrice,
      maxGas: gas.toInt(),
    ),
    chainId: chainId,
  );
  print('✅ settle tx 已发:$hash  (chainId=$chainId gas=$gas)');

  // 等收据,解码 Settled 确认。
  TransactionReceipt? receipt;
  for (var i = 0; i < 20; i++) {
    receipt = await client.getTransactionReceipt(hash);
    if (receipt != null) break;
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  if (receipt == null) {
    print('⚠ 未取到收据(查 Polygonscan):$hash');
  } else {
    print('status=${receipt.status} block=${receipt.blockNumber.blockNum}');
    for (final log in receipt.logs) {
      if (log.topics != null &&
          log.topics!.isNotEmpty &&
          hexOf(settledEv.signature) == log.topics![0]) {
        final d = settledEv.decodeResults(log.topics!, log.data ?? '0x');
        print('🔴 Settled 解码:vendor=${d[0]} success=${d[1]} amount=${d[2]} '
            'notSuccess=${d[3]}/${d[4]} ts=${d[5]}');
      }
    }
  }
  await client.dispose();
}
