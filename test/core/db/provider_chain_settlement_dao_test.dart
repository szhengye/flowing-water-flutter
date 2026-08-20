import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/db/provider_chain_settlement_dao.dart';

/// provider_chain_settlement DAO 测试 —— 07 Settlements 页 watchAll(倒序)。
/// 内存库,零 IO。
void main() {
  late AppDatabase db;
  late ProviderChainSettlementDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = ProviderChainSettlementDao(db);
  });
  tearDown(() => db.close());

  test('watchAll:按 createdAt 倒序(最新在前)', () async {
    await dao.insert(
      tx: '0xold',
      providerAddress: '0xaaa',
      relayStationAddress: '0xbbb',
      receivedUsdt: '1000000',
      settledCount: 1,
      settledAmount: '1000000',
      notSettledCount: 0,
      notSettledAmount: '0',
      createdAtMs: 1000,
    );
    await dao.insert(
      tx: '0xnew',
      providerAddress: '0xaaa',
      relayStationAddress: '0xbbb',
      receivedUsdt: '2000000',
      settledCount: 2,
      settledAmount: '2000000',
      notSettledCount: 0,
      notSettledAmount: '0',
      createdAtMs: 2000,
    );

    final rows = await dao.watchAll().first;
    expect(rows.map((r) => r.tx).toList(), ['0xnew', '0xold']);
    expect(rows.first.receivedUsdt, '2000000');
  });

  test('watchAll:空表 → 空列表', () async {
    expect(await dao.watchAll().first, isEmpty);
  });
}
