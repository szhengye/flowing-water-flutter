import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/providers.dart';
import 'package:flowing_water/features/providers/providers_screen.dart';

/// Providers 页 widget 测试 —— 用内存库 override,验列表渲染 + 空态。
/// (表单交互由 VendorDao 单测覆盖 CRUD;此处验 UI 绑定。)
void main() {
  testWidgets('渲染已 seed 的厂商', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.into(db.providerLlmVendors).insert(
          ProviderLlmVendorsCompanion.insert(
            vendorName: 'OpenAI 官方',
            endpoint: 'https://api.openai.com/v1',
            apiKey: 'sk',
          ),
        );
    await tester.pumpWidget(ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: ProvidersScreen()),
    ));
    await tester.pump(); // 触发 watch 流首帧
    expect(find.text('OpenAI 官方'), findsOneWidget);
    expect(find.byTooltip('新增厂商'), findsOneWidget);
    await db.close();
  });

  testWidgets('空列表显示空态提示', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: ProvidersScreen()),
    ));
    await tester.pump();
    expect(find.text('尚无厂商,点右上角 + 添加'), findsOneWidget);
    await db.close();
  });
}
