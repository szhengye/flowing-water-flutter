import 'package:drift/drift.dart';

import 'database.dart';

/// provider_chain_settlement DAO —— 链上 Settled 事件的幂等落地(03a)。
///
/// 03a 仅采集(写本表);对账(provider_log 回填 / unmatched)在 03b。
class ProviderChainSettlementDao {
  ProviderChainSettlementDao(this.db);
  final AppDatabase db;

  /// 该 tx 是否已记录(幂等:live 先到 + backfill 后到 / 重试重投)。
  Future<bool> exists(String tx) async {
    final row = await (db.select(db.providerChainSettlements)
          ..where((t) => t.tx.equals(tx)))
        .getSingleOrNull();
    return row != null;
  }

  /// 插入一条 Settled 记录(createdAt 由合约 timestamp 秒→毫秒)。
  Future<void> insert({
    required String tx,
    required String providerAddress,
    required String relayStationAddress,
    required String receivedUsdt,
    required int settledCount,
    required String settledAmount,
    required int notSettledCount,
    required String notSettledAmount,
    required int createdAtMs,
    int? logIndex,
  }) async {
    await db.into(db.providerChainSettlements).insert(
          ProviderChainSettlementsCompanion.insert(
            tx: tx,
            providerAddress: providerAddress,
            relayStationAddress: relayStationAddress,
            receivedUsdt: receivedUsdt,
            settledCount: settledCount,
            settledAmount: settledAmount,
            notSettledCount: notSettledCount,
            notSettledAmount: notSettledAmount,
            createdAt: createdAtMs,
            logIndex: Value(logIndex),
          ),
        );
  }

  /// 补写 logIndex(WS 先到时可能缺;backfill/upsert 时补)。
  Future<void> setLogIndex(String tx, int logIndex) async {
    await (db.update(db.providerChainSettlements)
          ..where((t) => t.tx.equals(tx)))
        .write(ProviderChainSettlementsCompanion(logIndex: Value(logIndex)));
  }

  /// 全部 Settled 记录(07 Settlements 页;按时间倒序)。drift `watch` →
  /// watcher 落地新事件时 UI 自动刷新。
  Stream<List<ProviderChainSettlementRow>> watchAll() {
    return (db.select(db.providerChainSettlements)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }
}
