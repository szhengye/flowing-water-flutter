import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/config/app_config.dart';
import 'package:flowing_water/core/crypto/identity_controller.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/providers.dart';
import 'package:flowing_water/features/wallet/wallet_screen.dart';
import 'package:drift/native.dart';

/// Wallet 页 widget 测试(07):验身份 / 配置门禁的禁用态文案。
/// 隔离渲染(不套 AppShell)。真实链读 / Etherscan 往返需 Polygon 配置,留 e2e。
AppConfig _emptyCfg() => const AppConfig(
      network: AppNetwork.dev,
      relayWsUrl: '',
      polygonRpcUrl: '',
      polygonRpcUrlWs: '',
      polygonContractAddress: '',
      polygonDeployBlock: 0,
      polygonUsdtAddress: '',
      polygonscanApiKey: '',
      upstreamApiKey: '',
    );

class _UnlockedIdentity extends IdentityController {
  @override
  Future<IdentityState> build() async => const IdentityState(
        status: IdentityStatus.unlocked,
        addressEip55: '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      );
}

class _NoneIdentity extends IdentityController {
  @override
  Future<IdentityState> build() async =>
      const IdentityState(status: IdentityStatus.none);
}

void main() {
  testWidgets('无身份(none)→ 提示先生成/解锁身份', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory()); // 空 → identity none
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appConfigProvider.overrideWithValue(_emptyCfg()),
        identityControllerProvider.overrideWith(() => _NoneIdentity()),
      ],
      child: const MaterialApp(home: WalletScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('需先生成 / 解锁供应商身份后查看钱包'), findsOneWidget);
    await db.close();
  });

  testWidgets('已解锁但 Polygon 未配 → 余额卡门禁 + MATIC tab 门禁提示', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appConfigProvider.overrideWithValue(_emptyCfg()),
        identityControllerProvider.overrideWith(() => _UnlockedIdentity()),
      ],
      child: const MaterialApp(home: WalletScreen()),
    ));
    await tester.pumpAndSettle();
    // 余额卡:RPC 未配 → unavailable 提示
    expect(find.text('需解锁身份并配置 Polygon RPC 后读取余额'), findsOneWidget);
    // MATIC tab(默认选中):Polygonscan key 未配提示
    expect(find.textContaining('Polygonscan API key 未配置'), findsOneWidget);
    await db.close();
  });
}
