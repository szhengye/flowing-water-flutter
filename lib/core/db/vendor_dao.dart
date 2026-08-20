import 'package:drift/drift.dart';

import 'database.dart';

/// provider_llm_vendor CRUD —— wayfinder 02 Providers 页。
///
/// 不用 `@DriftAccessor`(免 codegen),直接持 [AppDatabase] 用 table API。watch 流供
/// 列表实时刷新;create/update/remove 供表单操作。adapterType 用字符串(对齐表 schema
/// 与 parseAdapterType)。
class VendorDao {
  VendorDao(this.db);
  final AppDatabase db;

  Stream<List<ProviderLlmVendorRow>> watchAll() =>
      (db.select(db.providerLlmVendors)
            ..orderBy([(t) => OrderingTerm.asc(t.vendorId)]))
          .watch();

  Future<int> create({
    required String vendorName,
    required String endpoint,
    required String apiKey,
    String adapterType = 'openai',
    bool supportsStream = true,
  }) =>
      db.into(db.providerLlmVendors).insert(
            ProviderLlmVendorsCompanion.insert(
              vendorName: vendorName,
              endpoint: endpoint,
              apiKey: apiKey,
              adapterType: Value(adapterType),
              supportsStream: Value(supportsStream),
            ),
          );

  Future<int> update(VendorEdit fields) =>
      (db.update(db.providerLlmVendors)
            ..where((t) => t.vendorId.equals(fields.vendorId!)))
          .write(
        ProviderLlmVendorsCompanion(
          vendorName: Value(fields.vendorName),
          endpoint: Value(fields.endpoint),
          apiKey: Value(fields.apiKey),
          adapterType: Value(fields.adapterType),
          supportsStream: Value(fields.supportsStream),
          isActive: Value(fields.isActive),
        ),
      );

  Future<int> remove(int vendorId) =>
      (db.delete(db.providerLlmVendors)
            ..where((t) => t.vendorId.equals(vendorId)))
          .go();
}

/// 表单编辑载荷(vendorId 仅 update 用;create 时为 null)。
class VendorEdit {
  const VendorEdit({
    this.vendorId,
    required this.vendorName,
    required this.endpoint,
    required this.apiKey,
    required this.adapterType,
    required this.supportsStream,
    required this.isActive,
  });
  final int? vendorId;
  final String vendorName;
  final String endpoint;
  final String apiKey;
  final String adapterType;
  final bool supportsStream;
  final bool isActive;
}
