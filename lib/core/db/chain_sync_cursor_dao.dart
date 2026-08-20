import 'package:drift/drift.dart';

import 'database.dart';

/// chain_sync_cursor DAO —— watcher backfill 的跨重启断点(scope = 'provider_settled')。
class ChainSyncCursorDao {
  ChainSyncCursorDao(this.db);
  final AppDatabase db;

  /// 取某 scope 的上次成功扫描块号;无记录返回 null(首跑)。
  Future<int?> get(String scope) async {
    final row = await (db.select(db.chainSyncCursors)
          ..where((t) => t.scope.equals(scope)))
        .getSingleOrNull();
    return row?.lastBlock;
  }

  /// 设置/更新某 scope 的断点(仅全程成功后调用)。
  Future<void> set(String scope, int lastBlock) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await db.into(db.chainSyncCursors).insert(
          ChainSyncCursorsCompanion.insert(
            scope: scope,
            lastBlock: lastBlock,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }
}
