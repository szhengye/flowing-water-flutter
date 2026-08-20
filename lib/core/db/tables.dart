import 'package:drift/drift.dart';

/// drift 表定义 —— 1:1 对齐 web3-api provider-server 的 better-sqlite3 schema
/// (wayfinder 06:单库、同名表、金额用 TextColumn/BigInt)。
///
/// 命名:表类用复数 + `@override tableName` 精确对齐 Node 表名(单数 snake_case),
/// `@DataClassName` 显式指定行类名(避免 drift 单数化不规则复数出错)。
///
/// 备注:
/// - `created_at` 等时间戳存 epoch 秒(对齐 Node `unixepoch()`),insert 时由代码填。
/// - `chain_status` 的 CHECK 约束留 TODO(M3 精化 drift `check`);M0 fresh start 无影响。
/// - 外键关系留 TODO(M3 用 drift `references`);M0 以普通列承载。


// 1) provider_log —— 每次 LLM 请求(wayfinder 09 在 dispatcher 层插桩)
@TableIndex(name: 'idx_provider_log_status', columns: {#processingStatus})
@TableIndex(name: 'idx_provider_log_chain_status', columns: {#chainStatus})
@TableIndex(name: 'idx_provider_log_created_at', columns: {#createdAt})
@DataClassName('ProviderLogRow')
class ProviderLogs extends Table {
  @override
  String get tableName => 'provider_log';

  TextColumn get requestId => text()();
  TextColumn get modelName => text()();
  IntColumn get inputTokens => integer().withDefault(const Constant(0))();
  IntColumn get outputTokens => integer().withDefault(const Constant(0))();
  IntColumn get amount => integer().withDefault(const Constant(0))(); // nUSD
  TextColumn get processingStatus =>
      text().withDefault(const Constant('pending'))(); // pending/completed/failed
  IntColumn get latencyMs => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().withDefault(const Constant(''))();
  // not_on_chain / on_chain_settled / on_chain_not_settled
  TextColumn get chainStatus =>
      text().withDefault(const Constant('not_on_chain'))();
  TextColumn get batchId => text().nullable()();
  TextColumn get anchorTx => text().nullable()();
  TextColumn get settleTx => text().nullable()();
  TextColumn get settleFailedReason => text().nullable()();
  // 06 链上对账回填:本笔归属的 settle tx 内的 log 位置(随 settle_tx 一起写)。
  IntColumn get logIndex => integer().nullable()();
  IntColumn get providerInputPrice =>
      integer().withDefault(const Constant(0))(); // 时点价快照
  IntColumn get providerOutputPrice =>
      integer().withDefault(const Constant(0))();
  TextColumn get relayInputToken => text().nullable()(); // relay 对账回填
  TextColumn get relayOutputToken => text().nullable()();
  IntColumn get relayAmount => integer().nullable()();
  TextColumn get relayProcessingStatus => text().nullable()();
  IntColumn get createdAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {requestId};
}

// 2) provider_llm_vendor —— 上游 LLM 服务商配置
@DataClassName('ProviderLlmVendorRow')
class ProviderLlmVendors extends Table {
  @override
  String get tableName => 'provider_llm_vendor';

  IntColumn get vendorId => integer().autoIncrement()();
  TextColumn get vendorName => text()();
  TextColumn get endpoint => text()();
  TextColumn get apiKey => text()();
  TextColumn get vendorModels =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get adapterType =>
      text().withDefault(const Constant('openai'))(); // openai/anthropic/gemini/deepseek/azure_openai
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get supportsStream => boolean().withDefault(const Constant(true))();
}

// 3) provider_quotation —— 已报送 relay 的报价快照(主表)
@DataClassName('ProviderQuotationRow')
class ProviderQuotations extends Table {
  @override
  String get tableName => 'provider_quotation';

  TextColumn get relayModelName => text()(); // relayModel
  IntColumn get providerId => integer().nullable()();
  TextColumn get providerModel => text().nullable()();
  IntColumn get inputPricePer1k => integer().withDefault(const Constant(0))(); // nUSD/1K
  IntColumn get outputPricePer1k => integer().withDefault(const Constant(0))();
  IntColumn get submittedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {relayModelName};
}

// 4) provider_quotation_buffer —— 工作副本(sendProviderInfo 时 flush 到主表)
@DataClassName('ProviderQuotationBufferRow')
class ProviderQuotationBuffers extends Table {
  @override
  String get tableName => 'provider_quotation_buffer';

  TextColumn get relayModelName => text()();
  IntColumn get providerId => integer().nullable()();
  TextColumn get providerModel => text().nullable()();
  IntColumn get inputPricePer1k => integer().withDefault(const Constant(0))();
  IntColumn get outputPricePer1k => integer().withDefault(const Constant(0))();
  IntColumn get submittedAt => integer().nullable()();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {relayModelName};
}

// 5) provider_quotation_history —— 不可变报价变更日志
@DataClassName('ProviderQuotationHistoryRow')
class ProviderQuotationHistories extends Table {
  @override
  String get tableName => 'provider_quotation_history';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get relayModelName => text()();
  IntColumn get providerId => integer()();
  TextColumn get providerModel => text()();
  IntColumn get inputPricePer1k => integer().withDefault(const Constant(0))();
  IntColumn get outputPricePer1k => integer().withDefault(const Constant(0))();
  IntColumn get submittedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer().withDefault(const Constant(0))();
}

// 6) provider_chain_settlement —— 链上 Settled 事件(金额用 TextColumn/BigInt)
@DataClassName('ProviderChainSettlementRow')
class ProviderChainSettlements extends Table {
  @override
  String get tableName => 'provider_chain_settlement';

  TextColumn get tx => text()();
  TextColumn get providerAddress => text()();
  TextColumn get relayStationAddress => text()();
  TextColumn get receivedUsdt => text()(); // raw token amount string
  IntColumn get settledCount => integer()();
  TextColumn get settledAmount => text()();
  IntColumn get notSettledCount => integer()();
  TextColumn get notSettledAmount => text()();
  IntColumn get createdAt => integer()();
  IntColumn get logIndex => integer().nullable()();

  @override
  Set<Column> get primaryKey => {tx};
}

// 7) chain_sync_cursor —— watcher backfill 游标
@DataClassName('ChainSyncCursorRow')
class ChainSyncCursors extends Table {
  @override
  String get tableName => 'chain_sync_cursor';

  TextColumn get scope => text()(); // e.g. 'provider_settled'
  IntColumn get lastBlock => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {scope};
}

// 8) unmatched_settled_events —— 无匹配 relay 记录的 Settled 事件(composite PK)
@DataClassName('UnmatchedSettledEventRow')
class UnmatchedSettledEvents extends Table {
  @override
  String get tableName => 'unmatched_settled_events';

  TextColumn get tx => text()();
  IntColumn get logIndex => integer()();
  TextColumn get providerAddress => text()();
  TextColumn get receivedUsdt => text()();
  IntColumn get settledCount => integer()();
  TextColumn get settledAmount => text()();
  IntColumn get notSettledCount => integer()();
  TextColumn get notSettledAmount => text()();
  IntColumn get blockTimestamp => integer()();
  IntColumn get detectedAt => integer()();
  IntColumn get lastRetryAt => integer().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {tx, logIndex};
}

// 9) provider_models —— 从 relay 同步的模型元数据
@DataClassName('ProviderModelRow')
class ProviderModels extends Table {
  @override
  String get tableName => 'provider_models';

  TextColumn get modelName => text()();
  TextColumn get displayName => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get contextWindow => integer().nullable()();
  IntColumn get maxOutputTokens => integer().nullable()();
  TextColumn get modality => text().withDefault(const Constant(''))();
  RealColumn get promptPrice => real().nullable()();
  RealColumn get completionPrice => real().nullable()();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {modelName};
}

// 10) settings —— K-V 存储(keypair 密文 / provider_address / payment_address 等)
@DataClassName('SettingsRow')
class AppSettings extends Table {
  @override
  String get tableName => 'settings';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
