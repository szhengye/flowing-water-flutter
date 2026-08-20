import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 链读端口 —— 隔离 web3dart `Web3Client`,使 `PolygonEventWatcher` 可注入伪实现测试。
abstract class ChainClient {
  /// 订阅事件(socketConnector 存在时为真 eth_subscribe + 初始 getLogs;否则轮询)。
  Stream<FilterEvent> events(FilterOptions options);

  /// 按块范围拉历史日志(backfill 分页用)。
  Future<List<FilterEvent>> getLogs(FilterOptions options);

  /// 最新块号。
  Future<int> getBlockNumber();

  /// 原生(MATIC)余额(wayfinder 07 Wallet 页)。
  Future<EtherAmount> getBalance(EthereumAddress address);

  /// ERC-20(USDT)余额 —— `balanceOf(owner)`(最小 ABI,对齐上游
  /// admin.routes `/wallet/balances` 的 erc20BalanceOfAbi)。返回 raw 单位(USDT 6 位)。
  Future<BigInt> getTokenBalance({
    required EthereumAddress token,
    required EthereumAddress owner,
  });

  /// 释放底层连接。
  Future<void> dispose();
}

typedef ChainClientFactory = ChainClient Function();

/// web3dart `Web3Client` 的 [ChainClient] 包装。
class Web3ChainClient implements ChainClient {
  Web3ChainClient._(this._c);
  final Web3Client _c;

  /// [rpcUrl] HTTP/HTTPS RPC(余额/调用/getLogs);[socketConnector] 注入 WS(events 真订阅)。
  factory Web3ChainClient(String rpcUrl, {SocketConnector? socketConnector}) =>
      Web3ChainClient._(
        Web3Client(rpcUrl, Client(), socketConnector: socketConnector),
      );

  @override
  Stream<FilterEvent> events(FilterOptions options) => _c.events(options);

  @override
  Future<List<FilterEvent>> getLogs(FilterOptions options) =>
      _c.getLogs(options);

  @override
  Future<int> getBlockNumber() => _c.getBlockNumber();

  @override
  Future<EtherAmount> getBalance(EthereumAddress address) =>
      _c.getBalance(address);

  @override
  Future<BigInt> getTokenBalance({
    required EthereumAddress token,
    required EthereumAddress owner,
  }) async {
    final contract = DeployedContract(_erc20BalanceOfAbi, token);
    final res = await _c.call(
      contract: contract,
      function: contract.function('balanceOf'),
      params: [owner],
    );
    return res.first as BigInt;
  }

  @override
  Future<void> dispose() => _c.dispose();
}

/// ERC-20 `balanceOf(address) view returns(uint256)` 最小 ABI
/// (对齐上游 erc20BalanceOfAbi;07 Wallet USDT 余额读取)。
final ContractAbi _erc20BalanceOfAbi = ContractAbi.fromJson(
  '''
[
  {"name":"balanceOf","type":"function","stateMutability":"view",
   "inputs":[{"name":"","type":"address"}],
   "outputs":[{"name":"","type":"uint256"}]}
]
''',
  'ERC20',
);

/// 构造 Polygon WS 的 socketConnector(web3dart events() 真订阅用)。
SocketConnector polygonSocketConnector(String wsUrl) =>
    () => WebSocketChannel.connect(Uri.parse(wsUrl)).cast<String>();
