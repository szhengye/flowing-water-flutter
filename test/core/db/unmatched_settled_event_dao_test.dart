import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/db/unmatched_settled_event_dao.dart';

/// unmatched_settled_events DAO 测试 —— 锁定 09 operator 重试所需不变式:
/// insert 幂等(PK=(tx,logIndex) 防重)/ list / count / remove / recordRetry
/// 累加 retryCount + 写 lastRetryAt。内存库,零 IO。
void main() {
  late AppDatabase db;
  late UnmatchedSettledEventDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = UnmatchedSettledEventDao(db);
  });
  tearDown(() => db.close());

  Future<bool> seed(String tx, {int logIndex = 1}) => dao.insert(
        tx: tx,
        logIndex: logIndex,
        providerAddress: '0x1111111111111111111111111111111111111111',
        receivedUsdt: '500000000',
        settledCount: 2,
        settledAmount: '500000000',
        notSettledCount: 0,
        notSettledAmount: '0',
        blockTimestamp: 1700000000,
      );

  test('insert → list/count 可见', () async {
    await seed('0xaaa', logIndex: 1);
    await seed('0xbbb', logIndex: 2);
    final rows = await dao.list();
    expect(rows.length, 2);
    expect(rows.map((r) => r.tx).toSet(), {'0xaaa', '0xbbb'});
    expect(await dao.count(), 2);
  });

  test('同 (tx, logIndex) 二次 insert 幂等不重', () async {
    expect(await seed('0xaaa', logIndex: 5), isTrue); // 新插入
    expect(await seed('0xaaa', logIndex: 5), isFalse); // 已跟踪,不重插
    expect(await dao.count(), 1);
  });

  test('recordRetry 累加 retryCount 并写 lastRetryAt', () async {
    await seed('0xaaa', logIndex: 7);
    await dao.recordRetry(tx: '0xaaa', logIndex: 7);
    await dao.recordRetry(tx: '0xaaa', logIndex: 7);
    final row = (await dao.list()).single;
    expect(row.retryCount, 2);
    expect(row.lastRetryAt, isNotNull);
  });

  test('recordRetry 命中不存在的行 → no-op(不抛、不插)', () async {
    await seed('0xaaa', logIndex: 7);
    await dao.recordRetry(tx: '0xnone', logIndex: 0);
    expect(await dao.count(), 1); // 仍只有原 1 行
  });

  test('remove 删除指定 (tx, logIndex)', () async {
    await seed('0xaaa', logIndex: 1);
    await seed('0xbbb', logIndex: 2);
    await dao.remove(tx: '0xaaa', logIndex: 1);
    final rows = await dao.list();
    expect(rows.length, 1);
    expect(rows.single.tx, '0xbbb');
    expect(await dao.count(), 1);
  });
}
