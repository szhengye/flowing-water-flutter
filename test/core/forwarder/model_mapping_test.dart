import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/forwarder/adapters/types.dart';
import 'package:flowing_water/core/forwarder/model_mapping.dart';

/// model mapping 测试 —— relayModel → vendor 配置 + providerModel + 时点价;
/// 无 quotation / 无 vendor / providerModel 缺省回退 / adapterType 解析。
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> seedVendor({
    String adapterType = 'openai',
    bool supportsStream = true,
  }) async {
    return db.into(db.providerLlmVendors).insert(
          ProviderLlmVendorsCompanion.insert(
            vendorName: 'v',
            endpoint: 'https://api.openai.com/v1',
            apiKey: 'sk-x',
            adapterType: Value(adapterType),
            supportsStream: Value(supportsStream),
          ),
        );
  }

  test('relayModel → ProviderMapping(vendor 配置 + providerModel + 时点价)', () async {
    final vid = await seedVendor();
    await db.into(db.providerQuotations).insert(
          ProviderQuotationsCompanion.insert(
            relayModelName: 'gpt-4o',
            providerId: Value(vid),
            providerModel: const Value('gpt-4o-2024'),
            inputPricePer1k: const Value(2),
            outputPricePer1k: const Value(3),
          ),
        );
    final m = await resolveProviderMapping(db, 'gpt-4o');
    expect(m, isNotNull);
    expect(m!.endpoint, 'https://api.openai.com/v1');
    expect(m.apiKey, 'sk-x');
    expect(m.adapterType, AdapterType.openai);
    expect(m.supportsStream, isTrue);
    expect(m.providerModel, 'gpt-4o-2024');
    expect(m.inputPricePer1k, 2);
    expect(m.outputPricePer1k, 3);
  });

  test('无 quotation → null(dispatcher 据 onError "No model mapping")', () async {
    expect(await resolveProviderMapping(db, 'nope'), isNull);
  });

  test('quotation 无 providerId → null', () async {
    await db.into(db.providerQuotations).insert(
          ProviderQuotationsCompanion.insert(relayModelName: 'orphan'),
        );
    expect(await resolveProviderMapping(db, 'orphan'), isNull);
  });

  test('providerModel 缺省回退 relayModel', () async {
    final vid = await seedVendor();
    await db.into(db.providerQuotations).insert(
          ProviderQuotationsCompanion.insert(
            relayModelName: 'relay-x',
            providerId: Value(vid),
          ),
        );
    expect((await resolveProviderMapping(db, 'relay-x'))!.providerModel, 'relay-x');
  });

  test('adapterType 解析:azure_openai→azureOpenai,未知→openai', () async {
    final vid = await seedVendor(adapterType: 'azure_openai');
    await db.into(db.providerQuotations).insert(
          ProviderQuotationsCompanion.insert(
            relayModelName: 'az',
            providerId: Value(vid),
          ),
        );
    expect(
      (await resolveProviderMapping(db, 'az'))!.adapterType,
      AdapterType.azureOpenai,
    );
    expect(parseAdapterType('weird'), AdapterType.openai);
  });

  test('supportsStream=false 透传(vendor 不支持流式 → forwarder 应 onError)', () async {
    final vid = await seedVendor(supportsStream: false);
    await db.into(db.providerQuotations).insert(
          ProviderQuotationsCompanion.insert(
            relayModelName: 'ns',
            providerId: Value(vid),
          ),
        );
    expect((await resolveProviderMapping(db, 'ns'))!.supportsStream, isFalse);
  });
}
