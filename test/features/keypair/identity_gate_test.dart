import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/app.dart';
import 'package:flowing_water/core/crypto/identity_controller.dart';
import 'package:flowing_water/features/keypair/keypair_screen.dart';
import 'package:flowing_water/shared/widgets/app_shell.dart';

/// 喂给定状态的假身份控制器 —— 让门禁的「按状态切屏」逻辑脱离真实 DB/Keychain 可测。
class _FakeIdentity extends IdentityController {
  _FakeIdentity(this.fixed);
  final IdentityState fixed;
  @override
  Future<IdentityState> build() async => fixed;
}

void main() {
  // 门禁是「未设身份时绝不让用户进后台」的唯一闸门 —— 走错会让供应商在没有身份的
  // 情况下进到管理界面(然后什么节点功能都跑不通,且难以溯源)。三态切换必须钉死。
  testWidgets('identity loading → 启动闪屏(无后台、无设置页)', (t) async {
    await t.pumpWidget(ProviderScope(
      overrides: [
        identityControllerProvider.overrideWith(
            () => _LoadingIdentity()),
      ],
      child: const FlowingWaterApp(),
    ));
    await t.pump(); // loading 态:不 settle(故意停在 loading)

    expect(find.byType(AppShell), findsNothing);
    expect(find.byType(KeypairScreen), findsNothing);
  });

  testWidgets('identity none → 强制 Keypair 设置页(不进带导航后台)', (t) async {
    await t.pumpWidget(ProviderScope(
      overrides: [
        identityControllerProvider.overrideWith(() =>
            _FakeIdentity(const IdentityState(status: IdentityStatus.none))),
      ],
      child: const FlowingWaterApp(),
    ));
    await t.pumpAndSettle();

    expect(find.byType(KeypairScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing,
        reason: '未设置身份时绝不应进入带侧栏的后台');
  });

  testWidgets('identity locked → 解锁页(不进带导航后台)', (t) async {
    await t.pumpWidget(ProviderScope(
      overrides: [
        identityControllerProvider.overrideWith(() => _FakeIdentity(
                const IdentityState(
              status: IdentityStatus.locked,
              addressEip55: '0x58A57ed9d8d624cBD12e2C467D34787555bB1b25',
            ))),
      ],
      child: const FlowingWaterApp(),
    ));
    await t.pumpAndSettle();

    expect(find.byType(AppShell), findsNothing,
        reason: '未解锁时不应进入后台');
  });

  testWidgets('identity unlocked → 进入带导航的后台(AppShell)', (t) async {
    await t.pumpWidget(ProviderScope(
      overrides: [
        identityControllerProvider.overrideWith(() => _FakeIdentity(
                const IdentityState(
              status: IdentityStatus.unlocked,
              addressEip55: '0x58A57ed9d8d624cBD12e2C467D34787555bB1b25',
            ))),
      ],
      child: const FlowingWaterApp(),
    ));
    // 排干测试环境 CJK 字体缺失造成的 AppShell 侧栏标签溢出假象
    // (固定 176px 侧栏 × 无中文字体 → 豆腐块过宽;真实 macOS 系统字体下不溢出,M0 已验证)。
    // 本测试只关心门禁路由,不关心 AppShell 内部布局。
    await t.pump();
    await t.pump();
    t.takeException();

    expect(find.byType(AppShell), findsOneWidget,
        reason: '解锁后应进入带侧栏导航的后台');
    expect(find.text('流水供应商'), findsOneWidget);
  });
}

/// 永远停在 loading 的假控制器(模拟冷启动 bootstrap 未完成)。
/// 用永不完成的 Future,避免 fakeAsync 下产生 pending timer。
class _LoadingIdentity extends IdentityController {
  @override
  Future<IdentityState> build() async =>
      Completer<IdentityState>().future;
}
