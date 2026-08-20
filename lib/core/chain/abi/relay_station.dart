import 'package:web3dart/web3dart.dart';

/// RelayStationPolygon ABI —— 仅 `Settled` event(03a 监听用)。
///
/// web3-api 无签入的编译 ABI JSON,仅有 `contracts/RelayStationPolygon.sol`;
/// 本常量按 .sol 中 `event Settled(...)` 手写最小 ABI(字段顺序与 .sol 一致)。
/// 合约升级若改 Settled 字段,此处需同步。
const String relayStationAbiJson = '''
[
  {"anonymous":false,"inputs":[
    {"indexed":true,"internalType":"address","name":"vendor","type":"address"},
    {"indexed":false,"internalType":"uint32","name":"successCount","type":"uint32"},
    {"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},
    {"indexed":false,"internalType":"uint32","name":"notSuccessCount","type":"uint32"},
    {"indexed":false,"internalType":"uint256","name":"notSuccessAmount","type":"uint256"},
    {"indexed":false,"internalType":"uint256","name":"timestamp","type":"uint256"}
  ],"name":"Settled","type":"event"}
]
''';

/// 构造 RelayStationPolygon 部署合约(绑定 Settled event 定义用于解码)。
DeployedContract relayStationContract(EthereumAddress address) {
  final abi = ContractAbi.fromJson(relayStationAbiJson, 'RelayStationPolygon');
  return DeployedContract(abi, address);
}

/// 解码后的 Settled 事件参数(web3dart uint 一律 BigInt;vendor 为 indexed)。
class SettledEventArgs {
  const SettledEventArgs({
    required this.vendor,
    required this.successCount,
    required this.amount,
    required this.notSuccessCount,
    required this.notSuccessAmount,
    required this.timestamp,
  });

  final EthereumAddress vendor;
  final BigInt successCount;
  final BigInt amount;
  final BigInt notSuccessCount;
  final BigInt notSuccessAmount;
  final BigInt timestamp; // 合约秒

  /// 按 ABI 字段序从 web3dart `ContractEvent.decodeResults` 结果构造。
  factory SettledEventArgs.fromDecoded(List<dynamic> d) => SettledEventArgs(
        vendor: d[0] as EthereumAddress,
        successCount: d[1] as BigInt,
        amount: d[2] as BigInt,
        notSuccessCount: d[3] as BigInt,
        notSuccessAmount: d[4] as BigInt,
        timestamp: d[5] as BigInt,
      );

  /// 从一条 FilterEvent 解码(需对应 Settled 的 [ContractEvent])。
  static SettledEventArgs fromEvent(ContractEvent settled, FilterEvent log) =>
      SettledEventArgs.fromDecoded(
        settled.decodeResults(log.topics ?? const [], log.data ?? '0x'),
      );
}
