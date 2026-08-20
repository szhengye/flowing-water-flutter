import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/db/quotation_dao.dart';

/// QuotationDao CRUD 测试 —— 内存库。
void main() {
  late AppDatabase db;
  late QuotationDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = QuotationDao(db);
  });
  tearDown(() => db.close());

  test('create 落默认价 0 + providerId/providerModel 可空', () async {
    await dao.create(relayModelName: 'gpt-4o');
    final r = (await db.select(db.providerQuotations).get()).single;
    expect(r.relayModelName, 'gpt-4o');
    expect(r.inputPricePer1k, 0);
    expect(r.providerId, isNull);
    expect(r.providerModel, isNull);
  });

  test('update 改价 + providerId/providerModel', () async {
    await dao.create(relayModelName: 'gpt-4o');
    await dao.update(const QuotationEdit(
      relayModelName: 'gpt-4o',
      providerId: 5,
      providerModel: 'gpt-4o-2024',
      inputPricePer1k: 2,
      outputPricePer1k: 3,
    ));
    final r = await (db.select(db.providerQuotations)
          ..where((t) => t.relayModelName.equals('gpt-4o')))
        .getSingle();
    expect(r.providerId, 5);
    expect(r.providerModel, 'gpt-4o-2024');
    expect(r.inputPricePer1k, 2);
    expect(r.outputPricePer1k, 3);
  });

  test('remove 删除并返回行数', () async {
    await dao.create(relayModelName: 'gpt-4o');
    expect(await dao.remove('gpt-4o'), 1);
    expect(await db.select(db.providerQuotations).get(), isEmpty);
  });

  test('watchAll 流首帧发列表', () async {
    await dao.create(relayModelName: 'a');
    expect((await dao.watchAll().first).single.relayModelName, 'a');
  });

  test('relayModelToVendorMap(12):join vendor;未绑(providerId null)排除', () async {
    final vid = await db.into(db.providerLlmVendors).insert(
          ProviderLlmVendorsCompanion.insert(
              vendorName: 'OpenAI', endpoint: 'https://x', apiKey: 'k'));
    await dao.create(relayModelName: 'gpt-4o', providerId: vid);
    await dao.create(relayModelName: 'claude'); // providerId null → 排除
    expect(await dao.relayModelToVendorMap(), {'gpt-4o': 'OpenAI'});
  });
}
