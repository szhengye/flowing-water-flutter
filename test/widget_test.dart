import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// M0 smoke test —— 仅验证 widget 基建可用(不依赖 router/db)。
/// 各 feature 的真实测试在所属 milestone 阶段补。
void main() {
  testWidgets('smoke: MaterialApp builds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('smoke'))),
    );
    expect(find.text('smoke'), findsOneWidget);
  });
}
