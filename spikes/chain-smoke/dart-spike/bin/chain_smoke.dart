// ignore_for_file: avoid_print
//
// Polygon Amoy 链集成 smoke(wayfinder 05/08)。
// 验证 web3dart 真连 Amoy:连通性 / MATIC+USDT 读余额 / Settled 解码(真实数据)/
// getLogs(page=10,对齐 Alchemy 免费层 10 块上限)/ WS eth_subscribe 实时订阅。
//
// 运行:cd spikes/chain-smoke/dart-spike && dart pub get && dart run bin/chain_smoke.dart
import 'dart:convert';

import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const rpc = 'https://polygon-amoy.g.alchemy.com/v2/jHk-yC9S0Pk-EDQumLF0L';
const wsUrl = 'wss://polygon-amoy.g.alchemy.com/v2/jHk-yC9S0Pk-EDQumLF0L';
const contractHex = '0x08Eb4964b31D22D21e813aD8C7DD85EB0B3328A9';
const usdtHex = '0x88D654Bfaa1a993f0bf59b50e759a6afF8418AeC';
const polygonscanKey = 'JSGD5Y2Z9RTJU9YZ8J75ZVTBBZYVFA5SZZ';

const settledAbi = '''
[{"anonymous":false,"inputs":[
  {"indexed":true,"internalType":"address","name":"vendor","type":"address"},
  {"indexed":false,"internalType":"uint32","name":"successCount","type":"uint32"},
  {"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},
  {"indexed":false,"internalType":"uint32","name":"notSuccessCount","type":"uint32"},
  {"indexed":false,"internalType":"uint256","name":"notSuccessAmount","type":"uint256"},
  {"indexed":false,"internalType":"uint256","name":"timestamp","type":"uint256"}],
  "name":"Settled","type":"event"}]
''';

const erc20Abi =
    '[{"constant":true,"inputs":[{"name":"owner","type":"address"}],'
    '"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],'
    '"type":"function"}]';

String hexOf(List<int> bytes) =>
    '0x${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';

Future<void> main() async {
  final httpClient = Client();
  final client = Web3Client(
    rpc,
    httpClient,
    socketConnector: () =>
        WebSocketChannel.connect(Uri.parse(wsUrl)).cast<String>(),
  );
  try {
    final contract = DeployedContract(
      ContractAbi.fromJson(settledAbi, 'RelayStationPolygon'),
      EthereumAddress.fromHex(contractHex),
    );
    final settled = contract.event('Settled');
    final sigHex = hexOf(settled.signature); // topic0

    // 1) 连通性。
    final latest = await client.getBlockNumber();
    print('✅ 连通 Amoy:latest block = $latest');

    // 2) MATIC 原生余额(合约地址)。
    final matic = await client.getBalance(EthereumAddress.fromHex(contractHex));
    print('✅ MATIC 余额(合约)= ${matic.getValueInUnit(EtherUnit.ether)}');

    // 3) USDT(ERC-20)balanceOf 读路径(07 复用)。
    final usdt = DeployedContract(
      ContractAbi.fromJson(erc20Abi, 'USDT'),
      EthereumAddress.fromHex(usdtHex),
    );
    final usdtBal = await client.call(
      contract: usdt,
      function: usdt.function('balanceOf'),
      params: [EthereumAddress.fromHex(contractHex)],
    );
    print('✅ USDT balanceOf(合约)= ${usdtBal.first} (raw,6 decimals)');

    // 4) Polygonscan 查该合约的 Settled 事件(绕过 10 块上限做「找」)。
    final uri = Uri.parse(
      'https://api-amoy.polygonscan.com/api?module=logs&action=getLogs'
      '&address=$contractHex&topic0=$sigHex&apikey=$polygonscanKey',
    );
    final resp = await httpClient.get(uri);
    final body = jsonDecode(resp.body);
    final List found =
        (body is Map && body['result'] is List) ? body['result'] as List : [];
    print('✅ Polygonscan Settled(该合约,topic0=$sigHex)= ${found.length} 笔');
    int? lastBlock;
    for (final l in found.take(3)) {
      final topics = (l['topics'] as List).map((e) => e.toString()).toList();
      final d = settled.decodeResults(topics, l['data'] as String);
      final block = int.parse((l['blockNumber'] as String).substring(2),
          radix: 16);
      lastBlock = block;
      print('  • block=$block logIndex=${l['logIndex']} tx=${l['transactionHash']}');
      print('    vendor=${d[0]} success=${d[1]} amount=${d[2]} '
          'notSuccess=${d[3]}/${d[4]} ts=${d[5]}');
    }

    // 5) web3dart getLogs(page=10,对齐 Alchemy 免费层)—— 若找到 Settled,扫它所在块。
    final scanFrom = (lastBlock != null)
        ? lastBlock - 5
        : (latest > 100 ? latest - 100 : 0);
    final scanTo = lastBlock != null ? lastBlock + 5 : latest;
    final logs = <FilterEvent>[];
    for (var from = scanFrom; from <= scanTo; from += 10) {
      final to = from + 9 > scanTo ? scanTo : from + 9;
      try {
        logs.addAll(await client.getLogs(FilterOptions.events(
          contract: contract,
          event: settled,
          fromBlock: BlockNum.exact(from),
          toBlock: BlockNum.exact(to),
        )));
      } catch (e) {
        print('   (getLogs $from-$to 失败:$e)');
      }
    }
    print('✅ web3dart getLogs(page=10,块 $scanFrom-$scanTo)= ${logs.length} 笔 Settled');

    // 6) WS eth_subscribe 实时订阅 smoke(5s)。
    var live = 0;
    print('⏱ WS events() 真订阅 5s ...');
    final sub = client
        .events(FilterOptions.events(contract: contract, event: settled))
        .listen((e) {
      live++;
      print('🔴 实时 Settled:block=${e.blockNum} tx=${e.transactionHash}');
    }, onError: (Object e) => print('   (WS onError:$e)'));
    await Future<void>.delayed(const Duration(seconds: 5));
    await sub.cancel();
    print('✅ WS 订阅结束(5s 内 $live 笔;Amoy 低频,0 属正常)');
  } finally {
    await client.dispose();
    httpClient.close();
  }
}
