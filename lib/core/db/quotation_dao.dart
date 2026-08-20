import 'package:drift/drift.dart';

import 'database.dart';

/// provider_quotation CRUD —— wayfinder 02 Models 页。
///
/// relayModelName 是 PK(不可改,update 以它定位)。providerId 关联 vendor(可空:
/// 未绑 vendor 的报价,resolveProviderMapping 会返回 null → forwarder onError)。
/// watch 流供列表实时刷新。
class QuotationDao {
  QuotationDao(this.db);
  final AppDatabase db;

  Stream<List<ProviderQuotationRow>> watchAll() =>
      (db.select(db.providerQuotations)
            ..orderBy([(t) => OrderingTerm.asc(t.relayModelName)]))
          .watch();

  /// relayModelName → vendorName 映射(12 Dashboard 厂商汇总):
  /// `quotation.providerId` join `provider_llm_vendor.vendorId`。未绑 vendor 的
  /// 报价(providerId null)排除。供 [computeVendorBreakdown] 把 provider_log 行归到厂商。
  Future<Map<String, String>> relayModelToVendorMap() async {
    final rows = await (db.select(db.providerQuotations).join([
          innerJoin(
            db.providerLlmVendors,
            db.providerLlmVendors.vendorId
                .equalsExp(db.providerQuotations.providerId),
          ),
        ])
              ..where(db.providerQuotations.providerId.isNotNull()))
        .get();
    return {
      for (final r in rows)
        r.read(db.providerQuotations.relayModelName)!:
            r.read(db.providerLlmVendors.vendorName)!,
    };
  }

  Future<void> create({
    required String relayModelName,
    int? providerId,
    String? providerModel,
    int inputPricePer1k = 0,
    int outputPricePer1k = 0,
  }) =>
      db.into(db.providerQuotations).insert(
            ProviderQuotationsCompanion.insert(
              relayModelName: relayModelName,
              providerId:
                  providerId == null ? const Value.absent() : Value(providerId),
              providerModel: providerModel == null
                  ? const Value.absent()
                  : Value(providerModel),
              inputPricePer1k: Value(inputPricePer1k),
              outputPricePer1k: Value(outputPricePer1k),
            ),
          );

  Future<int> update(QuotationEdit f) =>
      (db.update(db.providerQuotations)
            ..where((t) => t.relayModelName.equals(f.relayModelName)))
          .write(
        ProviderQuotationsCompanion(
          providerId: Value(f.providerId),
          providerModel: Value(f.providerModel),
          inputPricePer1k: Value(f.inputPricePer1k),
          outputPricePer1k: Value(f.outputPricePer1k),
        ),
      );

  Future<int> remove(String relayModelName) =>
      (db.delete(db.providerQuotations)
            ..where((t) => t.relayModelName.equals(relayModelName)))
          .go();
}

/// 报价编辑载荷。relayModelName 是 PK(update 定位用,不可改);providerId/providerModel
/// 可空(解绑 vendor)。
class QuotationEdit {
  const QuotationEdit({
    required this.relayModelName,
    required this.providerId,
    required this.providerModel,
    required this.inputPricePer1k,
    required this.outputPricePer1k,
  });
  final String relayModelName;
  final int? providerId;
  final String? providerModel;
  final int inputPricePer1k; // nUSD / 1K tokens
  final int outputPricePer1k;
}
