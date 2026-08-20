/// 应用配置 —— 运行时参数(网络 / relay / 链 / 上游 key)。
///
/// wayfinder 07:Settings 含**网络选择器**(dev / mainnet / testnet)+ 可编辑 RPC。
/// 本类是这些配置的载体;M0 提供结构与默认值,真实连接逻辑在 M2(relay,生产应从
/// 合约 `wsUrl()` 读)/ M4(链)落地。
///
/// 读取方式:编译期 `--dart-define=KEY=value`(见 `fromEnvironment`)。敏感值
/// (上游 LLM key)不入 repo、不落盘 —— 运行时经环境变量传入(wayfinder 11 安全约束)。
///
/// 注意:与 Claude Code 自身的 ANTHROPIC_* 凭据完全无关。
class AppConfig {
  const AppConfig({
    required this.network,
    required this.relayWsUrl,
    required this.polygonRpcUrl,
    required this.polygonRpcUrlWs,
    required this.polygonContractAddress,
    required this.polygonDeployBlock,
    required this.polygonUsdtAddress,
    required this.polygonscanApiKey,
    required this.upstreamApiKey,
  });

  /// 当前网络(dev 默认 —— 对本地 relay)。
  final AppNetwork network;

  /// relay WebSocket 地址。dev 默认本地 relay(wayfinder 04 runbook);
  /// 生产应从链上合约 `wsUrl()` 读取(M2)。
  final String relayWsUrl;

  /// Polygon HTTP RPC(M4 链上读 / backfill)。
  final String polygonRpcUrl;

  /// Polygon WebSocket RPC(M4 事件订阅)。
  final String polygonRpcUrlWs;

  /// RelayStationPolygon 合约地址。
  final String polygonContractAddress;

  /// 合约部署块(backfill 下限;0 = 用 recent window)。Alchemy 免费层 10 块/请求,
  /// 生产应设此值贴近当前以避免冷 backfill 海量请求(见 wayfinder 08 Amoy smoke)。
  final int polygonDeployBlock;

  /// USDT(ERC-20)合约地址。
  final String polygonUsdtAddress;

  /// Polygonscan API key(M4 交易历史)。
  final String polygonscanApiKey;

  /// 上游 LLM key(M3 forwarder)。**不落盘**,运行时注入。
  final String upstreamApiKey;

  /// 从 `--dart-define` 读取,带 dev 默认值。缺省 = 本地开发配置。
  factory AppConfig.fromEnvironment() => AppConfig(
        network: AppNetwork.dev,
        relayWsUrl: const String.fromEnvironment(
            'RELAY_WS_URL', defaultValue: 'ws://localhost:3003'),
        polygonRpcUrl:
            const String.fromEnvironment('POLYGON_RPC_URL', defaultValue: ''),
        polygonRpcUrlWs: const String.fromEnvironment(
            'POLYGON_RPC_URL_WS', defaultValue: ''),
        polygonContractAddress: const String.fromEnvironment(
            'POLYGON_CONTRACT_ADDRESS', defaultValue: ''),
        polygonDeployBlock:
            const int.fromEnvironment('POLYGON_DEPLOY_BLOCK', defaultValue: 0),
        polygonUsdtAddress: const String.fromEnvironment(
            'POLYGON_USDT_ADDRESS', defaultValue: ''),
        polygonscanApiKey: const String.fromEnvironment(
            'POLYGONSCAN_API_KEY', defaultValue: ''),
        upstreamApiKey: const String.fromEnvironment(
            'UPSTREAM_API_KEY', defaultValue: ''),
      );

  AppConfig copyWith({
    AppNetwork? network,
    String? polygonRpcUrl,
    String? polygonRpcUrlWs,
  }) =>
      AppConfig(
        network: network ?? this.network,
        relayWsUrl: relayWsUrl,
        polygonRpcUrl: polygonRpcUrl ?? this.polygonRpcUrl,
        polygonRpcUrlWs: polygonRpcUrlWs ?? this.polygonRpcUrlWs,
        polygonContractAddress: polygonContractAddress,
        polygonDeployBlock: polygonDeployBlock,
        polygonUsdtAddress: polygonUsdtAddress,
        polygonscanApiKey: polygonscanApiKey,
        upstreamApiKey: upstreamApiKey,
      );
}

/// 网络环境(wayfinder 07:Settings 网络选择器)。
enum AppNetwork { dev, mainnet, testnet }
