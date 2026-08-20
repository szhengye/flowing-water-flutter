import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flowing_water/core/chain/chain_watcher_service.dart';
import 'package:flowing_water/core/relay/node_service.dart';
import 'package:flowing_water/routing/nav_items.dart';
import 'package:flowing_water/shared/design/app_colors.dart';
import 'package:flowing_water/shared/design/app_spacing.dart';
import 'package:flowing_water/shared/design/app_text_styles.dart';
import 'package:flowing_water/shared/widgets/status_visuals.dart';

/// 应用外壳 —— wayfinder 08:**C 骨架**(208px 窄侧栏 / 发丝边框 / 紧凑 / 无重阴影)
/// + 顶部嫁接 **B** 的 Connected pill。
///
/// 响应式:≥720px 侧栏(M0 桌面优先);<720px 底导航(M0 占位,移动端整体延后)。
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _SideNav(navigationShell: navigationShell),
          const VerticalDivider(width: 1, color: AppColors.border),
          Expanded(
            child: Column(
              children: [
                const _TopBar(),
                const Divider(height: 1, color: AppColors.borderSubtle),
                Expanded(child: navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 208,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('流水供应商', style: AppTextStyles.h2),
                Text('Provider Node', style: AppTextStyles.caption),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),
          Expanded(
            child: ListView.builder(
              itemCount: appNavItems.length,
              itemBuilder: (context, i) {
                final item = appNavItems[i];
                final selected = i == navigationShell.currentIndex;
                return _NavTile(
                  item: item,
                  selected: selected,
                  onTap: () => navigationShell.goBranch(
                    i,
                    initialLocation: i == navigationShell.currentIndex,
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const _StatusCard(),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.textPrimary;
    return Material(
      color: selected ? AppColors.accentSoft : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spaceMd,
            vertical: AppSpacing.spaceSm,
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 18, color: color),
              AppSpacing.space3xl.wSpace,
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 顶部连接 pill(04:接 NodeService 状态机 + 心跳 RTT)。绿/黄/红随状态;
/// 已连接时附 `· Xms` 心跳延迟(首心跳回包前 / 未连显示无延迟)。
class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(nodeStatusProvider);
    final latency = ref.watch(nodeLatencyProvider).valueOrNull;
    final (label, color) = nodeStatusVisual(status);
    final connected = status == NodeStatus.connected;
    final latencyLabel =
        connected ? (latency == null ? '--ms' : '${latency}ms') : null;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                AppSpacing.spaceXs.wSpace,
                Text(
                  latencyLabel == null ? label : '$label · $latencyLabel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 侧栏底部状态卡 —— 接 NodeService 连接状态(wayfinder 01)+ 链监听状态(05)。
/// watch [nodeStatusProvider] / [chainWatcherStatusProvider] 即激活两个服务:
/// AppShell 一渲染(用户进后台),节点开始连中转站、链监听开始监听 Settled。
class _StatusCard extends ConsumerWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(nodeStatusProvider);
    final chain = ref.watch(chainWatcherStatusProvider);
    final (label, color) = nodeStatusVisual(status);
    final (clabel, ccolor) = chainWatcherStatusVisual(chain);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dotRow('中转站:$label', color),
          AppSpacing.spaceXs.hSpace,
          _dotRow('链监听:$clabel', ccolor),
          AppSpacing.space2xs.hSpace,
          const Text('地址:—', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _dotRow(String label, Color color) => Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          AppSpacing.spaceXs.wSpace,
          Text(label, style: AppTextStyles.caption),
        ],
      );
}
