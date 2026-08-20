import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/crypto/identity_controller.dart';
import 'features/keypair/keypair_screen.dart';
import 'routing/app_router.dart';
import 'shared/design/app_colors.dart';
import 'shared/design/app_spacing.dart';
import 'shared/design/app_text_styles.dart';
import 'shared/design/app_theme.dart';

/// 应用根 widget —— wayfinder 05:Riverpod(ProviderScope 在 main)+ go_router。
///
/// **身份门禁(M1)**:冷启动先判定供应商身份状态,三态分流:
/// - loading → 启动闪屏;none → 强制 Keypair 设置(生成/恢复);locked → 解锁页;
/// - unlocked → 进入带导航的后台(go_router AppShell)。
///
/// 用 watch:身份一变,整根重建,自动在「门禁屏」与「后台」间切换 —— 未设/未解锁身份
/// 时绝不会进入后台。
class FlowingWaterApp extends ConsumerWidget {
  const FlowingWaterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityControllerProvider);
    return identity.when(
      loading: () => _shell(const _IdentitySplash()),
      error: (e, _) => _shell(_IdentityError(error: e.toString())),
      data: (s) => switch (s.status) {
        IdentityStatus.none => _shell(const KeypairScreen(setup: true)),
        IdentityStatus.locked =>
          _shell(const KeypairScreen(initialTab: KeypairTab.unlock)),
        IdentityStatus.unlocked => MaterialApp.router(
            title: '流水供应商',
            theme: AppTheme.light,
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
          ),
      },
    );
  }

  Widget _shell(Widget home) => MaterialApp(
        title: '流水供应商',
        theme: AppTheme.light,
        home: home,
        debugShowCheckedModeBanner: false,
      );
}

class _IdentitySplash extends StatelessWidget {
  const _IdentitySplash();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            AppSpacing.spaceLg.hSpace,
            const Text('正在加载身份…', style: AppTextStyles.bodySecondary),
          ],
        ),
      ),
    );
  }
}

class _IdentityError extends StatelessWidget {
  const _IdentityError({required this.error});
  final String error;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.danger),
              AppSpacing.spaceMd.hSpace,
              const Text('身份加载失败', style: AppTextStyles.h1),
              AppSpacing.spaceSm.hSpace,
              Text(error, style: AppTextStyles.bodySecondary),
            ],
          ),
        ),
      ),
    );
  }
}
