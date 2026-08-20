import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/chain/chain_watcher_service.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/providers.dart';
import 'package:flowing_water/features/settlements/settlements_screen.dart';

/// Settlements 页 widget 测试(07):验列表绑定(watchAll)+ 未监听时的门禁提示。
/// 隔离渲染(不套 AppShell → 无 CJK 字体假溢出;见 cjk-font-test-overflow memory)。
void main() {
  testWidgets('渲染已 seed 的 Settled + 金额格式化;未监听显示同步门禁提示', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.into(db.providerChainSettlements).insert(
          ProviderChainSettlementsCompanion.insert(
            tx: '0xabc',
            providerAddress: '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
            relayStationAddress: '0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
            receivedUsdt: '1500000', // 1.5 USDT raw
            settledCount: 1,
            settledAmount: '1500000',
            notSettledCount: 0,
            notSettledAmount: '0',
            createdAt: 1000,
          ),
        );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        chainWatcherStatusProvider
            .overrideWith((ref) => ChainWatcherStatus.stopped),
      ],
      child: const MaterialApp(home: SettlementsScreen()),
    ));
    await tester.pump(); // watch 流首帧

    expect(find.text('0xabc'), findsOneWidget);
    expect(find.text('+ 1.50 USDT'), findsOneWidget);
    // 链监听未运行 → 全量同步门禁提示出现
    expect(find.textContaining('链监听未运行'), findsOneWidget);
    await db.close();
  });

  testWidgets('空表显示空态', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        chainWatcherStatusProvider
            .overrideWith((ref) => ChainWatcherStatus.stopped),
      ],
      child: const MaterialApp(home: SettlementsScreen()),
    ));
    await tester.pump();
    expect(find.text('尚无 Settled 事件'), findsOneWidget);
    await db.close();
  });
}
