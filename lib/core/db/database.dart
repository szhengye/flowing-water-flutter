import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

/// 应用数据库 —— wayfinder 06:drift 单库,1:1 对齐 web3-api provider-server schema。
///
/// M0 仅就位 schema + open + 索引;DAO/查询在 M3(provider_log 插桩)及各 UI 阶段补。
/// v1 fresh start;旧 Node SQLite 文件可直接拷入打开(同 schema,零成本逃生)。
@DriftDatabase(tables: [
  ProviderLogs,
  ProviderLlmVendors,
  ProviderQuotations,
  ProviderQuotationBuffers,
  ProviderQuotationHistories,
  ProviderChainSettlements,
  ChainSyncCursors,
  UnmatchedSettledEvents,
  ProviderModels,
  AppSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 测试用(注入内存执行器)。
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // provider_log 三索引由 @TableIndex 声明(见 tables.dart),createAll 自动建。
          // TODO(M3): seed 默认 LLM vendor(待确认 web3-api 默认 vendor 列表)
        },
        onUpgrade: (m, from, to) async {
          // v2(06 对账):provider_log 加 log_index —— 本笔归属 settle tx 内的 log 位置,
          // 由 settle-event-syncer 回填时随 settle_tx 一起写(对齐上游 syncer 第105行意图)。
          if (from < 2) {
            await m.addColumn(providerLogs, providerLogs.logIndex);
          }
        },
      );
}

/// 打开桌面文件库:`flowing_water.sqlite`(应用支持目录;createInBackground 隔离 isolate)。
LazyDatabase _openConnection() => LazyDatabase(() async {
      final dir = await getApplicationSupportDirectory();
      final file = File(p.join(dir.path, 'flowing_water.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
