import 'package:drift/drift.dart';

import 'database.dart';

/// unmatched_settled_events DAO —— 06 链上对账:Settled 事件经 WS
/// `query_relay_records_by_tx_logindex` 反查 0 匹配(或查询失败耗尽重试)后落地,
/// 待 operator 手动重试(上游 admin.routes retry-all)。PK=(tx, logIndex) 防重。
///
/// 06 落地了 `insert`(采集期);`recordRetry` / `remove` / `list` / `count` /
/// `watchAll` 随 operator-retry 票(09)补 —— 操作即对齐上游
/// `createUnmatchedSettledEventRepo` 的 list/count/remove/recordRetry。
class UnmatchedSettledEventDao {
  UnmatchedSettledEventDao(this.db);
  final AppDatabase db;

  /// 全部未匹配事件(09 operator 列表;按发现时间倒序,最近的最先重试)。
  Future<List<UnmatchedSettledEventRow>> list() {
    return (db.select(db.unmatchedSettledEvents)
          ..orderBy([(t) => OrderingTerm.desc(t.detectedAt)]))
        .get();
  }

  /// 反应式列表(09 Settings 区:重试后 drift watch 自动刷新)。
  Stream<List<UnmatchedSettledEventRow>> watchAll() {
    return (db.select(db.unmatchedSettledEvents)
          ..orderBy([(t) => OrderingTerm.desc(t.detectedAt)]))
        .watch();
  }

  /// 未匹配条数(09 count 徽标)。
  Future<int> count() async =>
      (await db.select(db.unmatchedSettledEvents).get()).length;

  /// 命中匹配后从未匹配表移除(对齐上游 repo.remove)。
  Future<void> remove({required String tx, required int logIndex}) {
    return (db.delete(db.unmatchedSettledEvents)
          ..where((t) => t.tx.equals(tx) & t.logIndex.equals(logIndex)))
        .go();
  }

  /// 仍 0 匹配:累加重试计数 + 记本次重试时间(对齐上游 repo.recordRetry)。
  /// 行不存在则 no-op。事务内 read-modify-write 保证计数自增可靠
  /// (与 [insert] 同款 select-then-write,避免并发/重入双写)。
  Future<void> recordRetry({required String tx, required int logIndex}) {
    return db.transaction(() async {
      final row = await (db.select(db.unmatchedSettledEvents)
            ..where((t) => t.tx.equals(tx) & t.logIndex.equals(logIndex)))
          .getSingleOrNull();
      if (row == null) return;
      await (db.update(db.unmatchedSettledEvents)
            ..where((t) => t.tx.equals(tx) & t.logIndex.equals(logIndex)))
          .write(UnmatchedSettledEventsCompanion(
        retryCount: Value(row.retryCount + 1),
        lastRetryAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      ));
    });
  }

  /// 记录一笔未匹配 Settled。幂等:PK 已存在则不重插(返回 false = 已在跟踪)。
  /// 事务内 select-then-insert 保证「是否新插入」判定可靠(insertOrIgnore 的
  /// lastInsertRowId 在 ignore 时不可靠)。
  Future<bool> insert({
    required String tx,
    required int logIndex,
    required String providerAddress,
    required String receivedUsdt,
    required int settledCount,
    required String settledAmount,
    required int notSettledCount,
    required String notSettledAmount,
    required int blockTimestamp,
  }) {
    return db.transaction(() async {
      final exists = await (db.select(db.unmatchedSettledEvents)
            ..where((t) => t.tx.equals(tx) & t.logIndex.equals(logIndex)))
          .getSingleOrNull();
      if (exists != null) return false;
      await db.into(db.unmatchedSettledEvents).insert(
            UnmatchedSettledEventsCompanion.insert(
              tx: tx,
              logIndex: logIndex,
              providerAddress: providerAddress,
              receivedUsdt: receivedUsdt,
              settledCount: settledCount,
              settledAmount: settledAmount,
              notSettledCount: notSettledCount,
              notSettledAmount: notSettledAmount,
              blockTimestamp: blockTimestamp,
              detectedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            ),
          );
      return true;
    });
  }
}
