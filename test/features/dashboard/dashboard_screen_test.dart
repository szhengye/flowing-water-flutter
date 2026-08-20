import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/chain/chain_watcher_service.dart';
import 'package:flowing_water/core/crypto/identity_controller.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/providers.dart';
import 'package:flowing_water/core/relay/node_service.dart';
import 'package:flowing_water/features/dashboard/dashboard_screen.dart';

/// Dashboard 页 widget 测试(04):验指标绑定(KPI / 模型明细 / 链上汇总 / 节点健康)。
/// 隔离渲染:override 掉 NodeService / ChainWatcher / 身份,避免测试里真起 WS / keychain。
class _NoneIdentity extends IdentityController {
  @override
  Future<IdentityState> build() async =>
      const IdentityState(status: IdentityStatus.none);
}

void main() {
  testWidgets('渲染 seed 指标 + 链上汇总 + 节点健康(已连接·42ms)', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    // 2 笔 completed(gpt-4o,amount 1e9+5e8 nUSD = 1.5 USDT)+ 1 笔 failed(claude)。
    await db.into(db.providerLogs).insert(ProviderLogsCompanion.insert(
          requestId: 'a',
          modelName: 'gpt-4o',
          processingStatus: const Value('completed'),
          amount: const Value(1000000000),
          createdAt: const Value(1),
        ));
    await db.into(db.providerLogs).insert(ProviderLogsCompanion.insert(
          requestId: 'b',
          modelName: 'gpt-4o',
          processingStatus: const Value('completed'),
          amount: const Value(500000000),
          createdAt: const Value(2),
        ));
    await db.into(db.providerLogs).insert(ProviderLogsCompanion.insert(
          requestId: 'c',
          modelName: 'claude',
          processingStatus: const Value('failed'),
          createdAt: const Value(3),
        ));
    // 1 笔链上结算(1.5 USDT raw)。
    await db.into(db.providerChainSettlements).insert(
          ProviderChainSettlementsCompanion.insert(
            tx: '0xsett',
            providerAddress: '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
            relayStationAddress: '0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
            receivedUsdt: '1500000',
            settledCount: 1,
            settledAmount: '1500000',
            notSettledCount: 0,
            notSettledAmount: '0',
            createdAt: 1000,
          ),
        );
    // 厂商映射(12):gpt-4o → OpenAI(供 厂商明细)。
    final vid = await db.into(db.providerLlmVendors).insert(
          ProviderLlmVendorsCompanion.insert(
              vendorName: 'OpenAI', endpoint: 'https://x', apiKey: 'k'));
    await db.into(db.providerQuotations).insert(
          ProviderQuotationsCompanion.insert(
              relayModelName: 'gpt-4o', providerId: Value(vid)));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        identityControllerProvider.overrideWith(() => _NoneIdentity()),
        dashboardPeriodProvider.overrideWith((ref) => DashboardPeriod.lifetime),
        nodeStatusProvider.overrideWithValue(NodeStatus.connected),
        nodeLatencyProvider.overrideWith((ref) => Stream.value(42)),
        chainWatcherStatusProvider
            .overrideWith((ref) => ChainWatcherStatus.running),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    ));
    await tester.pumpAndSettle();

    // KPI:完成率 67%(2/3)+ 收益(USDT,nUSD/1e9)。
    expect(find.text('67%'), findsOneWidget);
    expect(find.text('收益(USDT)'), findsOneWidget);
    expect(find.text('1.500000'), findsOneWidget); // 收益 KPI 值(1.5e9 nUSD / 1e9)
    // 模型明细(按计费额倒序:gpt-4o 在前,1.5e9 nUSD = 1.500000 USDT)。
    expect(find.text('gpt-4o'), findsOneWidget);
    expect(find.text('1.500000 USDT'),
        findsWidgets); // 模型明细 + 厂商明细(滚动后)各一处
    expect(find.text('2 次'), findsWidgets); // 模型明细 gpt-4o(厂商明细滚动后也一处)
    // 链上汇总。
    expect(find.text('+ 1.50 USDT'), findsOneWidget);
    // 节点健康。
    expect(find.textContaining('已连接'), findsWidgets);
    expect(find.textContaining('42ms'), findsOneWidget);
    // 非空 → 不应出现空态。
    expect(find.text('周期内无流水'), findsNothing);
    // 厂商明细(12)在列表底部,最后滚动至可见再断言(避免把顶部卡推出视口):gpt-4o → OpenAI。
    await tester.scrollUntilVisible(find.text('厂商明细'), 200);
    expect(find.text('厂商明细'), findsOneWidget);
    expect(find.text('OpenAI'), findsOneWidget);
    await db.close();
  });

  testWidgets('空数据 → 模型明细空态,不抛', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        identityControllerProvider.overrideWith(() => _NoneIdentity()),
        dashboardPeriodProvider.overrideWith((ref) => DashboardPeriod.lifetime),
        nodeStatusProvider.overrideWithValue(NodeStatus.stopped),
        nodeLatencyProvider.overrideWith((ref) => Stream.value(null)),
        chainWatcherStatusProvider
            .overrideWith((ref) => ChainWatcherStatus.stopped),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('周期内无流水'), findsOneWidget);
    await db.close();
  });
}
