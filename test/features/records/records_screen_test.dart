import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/providers.dart';
import 'package:flowing_water/features/records/records_screen.dart';

/// Records 页 widget 测试(04):验 provider_log 列表绑定 + 状态徽章。
/// 隔离渲染(不套 AppShell → 无 CJK 字体假溢出;见 cjk-font-test-overflow memory)。
void main() {
  testWidgets('渲染 seed 流水(模型名 + 处理/链态徽章 + 失败原因)', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.into(db.providerLogs).insert(ProviderLogsCompanion.insert(
          requestId: 'r1',
          modelName: 'gpt-4o',
          processingStatus: const Value('completed'),
          chainStatus: const Value('on_chain_settled'),
          amount: const Value(7),
          createdAt: const Value(1),
        ));
    await db.into(db.providerLogs).insert(ProviderLogsCompanion.insert(
          requestId: 'r2',
          modelName: 'claude',
          processingStatus: const Value('failed'),
          errorMessage: const Value('upstream 500'),
          createdAt: const Value(2),
        ));
    await tester.pumpWidget(ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: RecordsScreen()),
    ));
    await tester.pump(); // watch 流首帧

    expect(find.text('gpt-4o'), findsOneWidget);
    expect(find.text('claude'), findsOneWidget);
    expect(find.text('已完成'), findsOneWidget);
    expect(find.text('已结算'), findsOneWidget);
    expect(find.text('失败'), findsOneWidget);
    expect(find.textContaining('7 nUSD'), findsOneWidget);
    expect(find.text('upstream 500'), findsOneWidget);
    await db.close();
  });

  testWidgets('空表显示空态', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: RecordsScreen()),
    ));
    await tester.pump();
    expect(find.text('无匹配流水'), findsOneWidget);
    await db.close();
  });
}
