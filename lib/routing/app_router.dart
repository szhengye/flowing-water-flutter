import 'package:go_router/go_router.dart';
import 'package:flowing_water/features/dashboard/dashboard_screen.dart';
import 'package:flowing_water/features/keypair/keypair_screen.dart';
import 'package:flowing_water/features/models/models_screen.dart';
import 'package:flowing_water/features/providers/providers_screen.dart';
import 'package:flowing_water/features/records/records_screen.dart';
import 'package:flowing_water/features/settlements/settlements_screen.dart';
import 'package:flowing_water/features/settings/settings_screen.dart';
import 'package:flowing_water/features/wallet/wallet_screen.dart';
import 'package:flowing_water/features/scaffolding/placeholder_screen.dart';
import 'package:flowing_water/routing/nav_items.dart';
import 'package:flowing_water/shared/widgets/app_shell.dart';

/// 应用路由 —— wayfinder 05:go_router + StatefulShellRoute(桌面嵌套 shell)。
///
/// 每个 NavItem 一个 branch(indexedStack 保活各页状态),全部包在 AppShell 里。
/// M0 各页指向占位;M1–M5 逐页替换为真实实现(当前 M1:/keypair 已落地)。
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        for (final item in appNavItems)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: item.path,
                builder: (context, state) => switch (item.path) {
                      '/' => const DashboardScreen(),
                      '/records' => const RecordsScreen(),
                      '/keypair' => const KeypairScreen(),
                      '/providers' => const ProvidersScreen(),
                      '/models' => const ModelsScreen(),
                      '/settlements' => const SettlementsScreen(),
                      '/wallet' => const WalletScreen(),
                      '/settings' => const SettingsScreen(),
                      _ => PlaceholderScreen(
                          title: item.label, milestone: item.milestone),
                    },
              ),
            ],
          ),
      ],
    ),
  ],
);
