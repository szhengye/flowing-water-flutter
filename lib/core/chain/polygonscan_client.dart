import 'dart:convert';

import 'package:dio/dio.dart';

/// Etherscan V2 API 客户端(07 Wallet 页交易历史)—— 镜像上游
/// `provider-server/src/chain/polygonscan-client.ts`(后者又镜像 relay-server)。
///
/// 在服务端代理 provider EOA 的 MATIC(原生)+ USDT(ERC-20)交易历史,
/// API key 只存本机 env、不进 UI 包。Etherscan V2 用 `chainid` 统一多链,
/// `tokentx` 绕开 RPC `eth_getLogs` 的块范围上限。
///
/// chainid 固定 137(Polygon mainnet);Amoy testnet(80002)交易历史待
/// Settings 网络门控 ticket(见 map Fog)落地后按网络切换。
const String kEtherscanV2Base = 'https://api.etherscan.io/v2/api';
const int kPolygonChainId = 137;

/// 钱包交易方向。
enum WalletTxDirection { incoming, outgoing }

/// 钱包一笔交易(MATIC 原生 / USDT ERC-20 共用)。对齐上游 `EvmWalletTx`。
class WalletTx {
  const WalletTx({
    required this.txHash,
    required this.direction,
    required this.amount,
    required this.decimals,
    required this.feeMatic,
    required this.status,
    this.blockNumber,
    this.blockTimestamp,
    this.counterparty,
  });

  final String txHash;
  final WalletTxDirection direction;

  /// 人类单位,带符号(收入 + / 支出 −)。MATIC decimals=18,USDT=6。
  final double amount;
  final int decimals;

  /// 矿工费(MATIC),如 "0.00123456"。
  final String feeMatic;

  /// `true` = 成功;`false` = 链上失败(isError=1)。
  final bool status;
  final int? blockNumber;
  final int? blockTimestamp;

  /// 对手方地址(支出→to;收入→from)。
  final String? counterparty;

  @override
  String toString() =>
      'WalletTx($txHash ${direction == WalletTxDirection.outgoing ? "out" : "in"} '
      '$amount status=$status)';
}

int _pow10(int n) {
  var r = 1;
  for (var i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}

/// 把一条 Etherscan 原始 tx 映射成 [WalletTx](对齐上游 `toEvmWalletTx`)。
WalletTx toWalletTx(
  Map<String, dynamic> t,
  String account,
  int decimals,
) {
  final op = account.toLowerCase();
  final isOut = (t['from'] as String).toLowerCase() == op;
  final valueHuman = int.parse(t['value'] as String) / _pow10(decimals);
  final feeMatic =
      (int.parse(t['gasUsed'] as String) * int.parse(t['gasPrice'] as String)) /
          1e18;
  return WalletTx(
    txHash: t['hash'] as String,
    direction:
        isOut ? WalletTxDirection.outgoing : WalletTxDirection.incoming,
    amount: isOut ? -valueHuman : valueHuman,
    decimals: decimals,
    feeMatic: feeMatic.toStringAsFixed(8),
    status: t['isError'] != '1',
    blockNumber: (t['blockNumber'] as String).isNotEmpty
        ? int.tryParse(t['blockNumber'] as String)
        : null,
    blockTimestamp: (t['timeStamp'] as String).isNotEmpty
        ? int.tryParse(t['timeStamp'] as String)
        : null,
    counterparty: isOut ? (t['to'] as String) : (t['from'] as String),
  );
}

/// 解析 Etherscan V2 响应体(已 decode 的 JSON map)→ [WalletTx] 列表。
/// 纯函数,便于单测(对齐上游 `fetchEtherscan` 的解析段):
/// `result` 为字符串("No transactions found" 等)或缺失 → 空列表。
List<WalletTx> parseEtherscanResponse(
  Map<String, dynamic> body, {
  required String account,
  required int decimals,
}) {
  final result = body['result'];
  if (result is! List) return const [];
  return result
      .whereType<Map<String, dynamic>>()
      .map((t) => toWalletTx(t, account, decimals))
      .toList();
}

/// Etherscan V2 客户端。Dio 可注入(测试用假 adapter / override)。
class PolygonscanClient {
  PolygonscanClient({Dio? dio, int? chainId})
      : _dio = dio ?? Dio(),
        _chainId = chainId ?? kPolygonChainId;

  final Dio _dio;
  final int _chainId;

  /// MATIC(原生)交易历史(`action=txlist`,decimals 18)。
  Future<List<WalletTx>> fetchMaticTx({
    required String address,
    int limit = 20,
    String? apiKey,
  }) =>
      _fetch(
        action: 'txlist',
        address: address,
        limit: limit,
        apiKey: apiKey,
        decimals: 18,
      );

  /// USDT(ERC-20)交易历史(`action=tokentx`,decimals 6;按合约过滤)。
  Future<List<WalletTx>> fetchUsdtTx({
    required String address,
    required String token,
    int limit = 20,
    String? apiKey,
  }) =>
      _fetch(
        action: 'tokentx',
        address: address,
        limit: limit,
        apiKey: apiKey,
        decimals: 6,
        extra: {'contractaddress': token},
      );

  Future<List<WalletTx>> _fetch({
    required String action,
    required String address,
    required int limit,
    required int decimals,
    String? apiKey,
    Map<String, String>? extra,
  }) async {
    final query = <String, dynamic>{
      'chainid': _chainId.toString(),
      'module': 'account',
      'action': action,
      'address': address,
      'page': '1',
      'offset': limit.toString(),
      'sort': 'desc',
      if (apiKey != null && apiKey.isNotEmpty) 'apikey': apiKey,
      if (extra != null) ...extra,
    };
    final res = await _dio.get<dynamic>(kEtherscanV2Base, queryParameters: query);
    final body = res.data is String
        ? (res.data as String).isEmpty
            ? <String, dynamic>{}
            : jsonDecode(res.data as String) as Map<String, dynamic>
        : (res.data as Map<String, dynamic>?) ?? const {};
    return parseEtherscanResponse(body, account: address, decimals: decimals);
  }
}
