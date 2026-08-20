import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/db/vendor_dao.dart';

/// VendorDao CRUD 测试 —— 内存库。
void main() {
  late AppDatabase db;
  late VendorDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = VendorDao(db);
  });
  tearDown(() => db.close());

  test('create 落默认 adapterType=openai / supportsStream=true', () async {
    await dao.create(vendorName: 'v1', endpoint: 'https://x', apiKey: 'k');
    final rows = await db.select(db.providerLlmVendors).get();
    expect(rows.single.vendorName, 'v1');
    expect(rows.single.adapterType, 'openai');
    expect(rows.single.supportsStream, isTrue);
  });

  test('update 改字段(adapterType/isActive/supportsStream)', () async {
    final id = await dao.create(vendorName: 'v1', endpoint: 'e', apiKey: 'k');
    await dao.update(VendorEdit(
      vendorId: id,
      vendorName: 'v2',
      endpoint: 'e2',
      apiKey: 'k2',
      adapterType: 'anthropic',
      supportsStream: false,
      isActive: false,
    ));
    final row = await (db.select(db.providerLlmVendors)
          ..where((t) => t.vendorId.equals(id)))
        .getSingle();
    expect(row.vendorName, 'v2');
    expect(row.endpoint, 'e2');
    expect(row.apiKey, 'k2');
    expect(row.adapterType, 'anthropic');
    expect(row.supportsStream, isFalse);
    expect(row.isActive, isFalse);
  });

  test('remove 删除并返回行数', () async {
    final id = await dao.create(vendorName: 'v1', endpoint: 'e', apiKey: 'k');
    expect(await dao.remove(id), 1);
    expect(await db.select(db.providerLlmVendors).get(), isEmpty);
  });

  test('watchAll 流首帧发列表', () async {
    await dao.create(vendorName: 'v1', endpoint: 'e', apiKey: 'k');
    final first = await dao.watchAll().first;
    expect(first.single.vendorName, 'v1');
  });
}
