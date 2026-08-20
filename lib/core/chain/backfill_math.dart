import 'dart:math';

/// backfill 纯逻辑 —— 抽出便于单测(floor 选择 / 分页 / 退避)。

/// chain_sync_cursor scope(对齐上游 'provider_settled')。
const String kProviderSettledScope = 'provider_settled';

/// 三层 backfill floor(ADR-0003 #06):
///   1. [cursor] —— 上次成功扫描块(跨重启续点,重扫该块以幂等兜底)。
///   2. [deployBlock] —— 合约部署块(生产首选,不错过部署以来的事件)。
///   3. recent window —— 兜底(无 cursor/deployBlock 时仅扫最近 [recentWindowHours] 小时)。
///
/// 返回应开始扫描的块号(含)。重扫幂等(provider_chain_settlement 以 tx 去重)。
int backfillFloor({
  required int latest,
  int? cursor,
  int? deployBlock,
  int recentWindowHours = 72,
  int blocksPerHour = 1800, // Polygon ~2s/块 → 1800 块/h
}) {
  if (cursor != null && cursor > 0) return cursor;
  if (deployBlock != null && deployBlock > 0) return deployBlock;
  final window = recentWindowHours * blocksPerHour;
  return latest > window ? latest - window : 0;
}

/// 把 [fromBlock, latest] 切成 page 块一页(eth_getLogs 块范围上限,如 Alchemy 免费层 ~10)。
List<({int from, int to})> logPages(int fromBlock, int latest, {int page = 10}) {
  if (latest < fromBlock) return const [];
  final out = <({int from, int to})>[];
  for (var from = fromBlock; from <= latest; from += page) {
    final to = from + page - 1 > latest ? latest : from + page - 1;
    out.add((from: from, to: to));
  }
  return out;
}

/// 退避调度:输入重连次数,返回等待秒数(可注入,便于测试固定值)。
typedef BackoffSchedule = int Function(int attempt);

/// full-jitter 指数退避(对齐 relay `ws_client.fullJitterBackoff`,优于上游无 jitter):
/// delay = random[0, min(cap, base·2^attempt)] 秒,base 1s、cap 60s。
int fullJitterDelaySeconds(
  int attempt, {
  int baseSeconds = 1,
  int capSeconds = 60,
  Random? random,
}) {
  final r = random ?? Random();
  final exp = baseSeconds * (1 << attempt.clamp(0, 30));
  final upper = exp < capSeconds ? exp : capSeconds;
  return r.nextInt(upper + 1); // [0, upper]
}
