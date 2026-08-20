import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/db/quotation_dao.dart';
import 'package:flowing_water/core/providers.dart';
import 'package:flowing_water/features/models/models_screen.dart';

/// Models 页 widget 测试 —— 用内存库 override,验列表渲染 + 空态。
/// (表单交互由 QuotationDao 单测覆盖 CRUD;此处验 UI 绑定。)
void main() {
  testWidgets('渲染已 seed 的模型报价', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await QuotationDao(db).create(
      relayModelName: 'gpt-4o',
      providerModel: 'gpt-4o-2024',
      inputPricePer1k: 2,
      outputPricePer1k: 3,
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: ModelsScreen()),
    ));
    await tester.pump();
    expect(find.text('gpt-4o'), findsOneWidget);
    expect(find.byTooltip('新增模型'), findsOneWidget);
    await db.close();
  });

  testWidgets('空列表显示空态提示', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: ModelsScreen()),
    ));
    await tester.pump();
    expect(find.text('尚无模型报价,点右上角 + 添加'), findsOneWidget);
    await db.close();
  });
}
