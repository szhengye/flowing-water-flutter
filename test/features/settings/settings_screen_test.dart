import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/config/app_config.dart';
import 'package:flowing_water/core/crypto/identity_controller.dart';
import 'package:flowing_water/core/providers.dart';
import 'package:flowing_water/core/relay/node_service.dart';
import 'package:flowing_water/features/settings/settings_screen.dart';

/// 假身份:恒为 unlocked,地址 0xTest(绕过 db/vault bootstrap)。
class _UnlockedIdentity extends IdentityController {
  @override
  Future<IdentityState> build() async => const IdentityState(
        status: IdentityStatus.unlocked,
        addressEip55: '0xTest',
      );
}

void main() {
  testWidgets('显示身份地址 + relay URL + WS 状态', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityControllerProvider.overrideWith(() => _UnlockedIdentity()),
          appConfigProvider.overrideWithValue(AppConfig.fromEnvironment()),
          nodeStatusProvider.overrideWithValue(NodeStatus.connected),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Owner 与 Payment 两处都显示地址。
    expect(find.text('0xTest'), findsNWidgets(2));
    expect(find.text('ws://localhost:3003'), findsOneWidget);
    expect(find.text('已连接'), findsOneWidget);
  });
}
