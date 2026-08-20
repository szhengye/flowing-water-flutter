import 'package:flutter/material.dart';
import '../tokens/direction_tokens.dart';
import '../tokens/app_spacing.dart';
import '../data/mock_data.dart';

/// 响应式应用外壳。
/// - 宽屏(≥ 720px):左固定侧栏 + 内容区(macOS/Windows 桌面 shell)。
/// - 窄屏(< 720px):底部导航 + 顶栏(iOS/Android shell)。
///
/// 结构借自 listening-king 的 DesktopScaffold/SideNavBar,但导航项、色板、密度
/// 全部走 DirTokens。缩窗即见「移动 shell」——不为移动单开代码路径。
class AppShell extends StatefulWidget {
  final DirTokens dir;
  final int navIndex;
  final ValueChanged<int> onNavChanged;
  final Widget child;

  const AppShell({
    super.key,
    required this.dir,
    required this.navIndex,
    required this.onNavChanged,
    required this.child,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _wideBreakpoint = 720.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= _wideBreakpoint;
        return Scaffold(
          backgroundColor: widget.dir.palette.bg,
          body: wide ? _wide(context) : _narrow(context),
        );
      },
    );
  }

  Widget _wide(BuildContext context) {
    final p = widget.dir.palette;
    return Row(
      children: [
        _SideRail(
          dir: widget.dir,
          navIndex: widget.navIndex,
          onNavChanged: widget.onNavChanged,
        ),
        Container(width: 1, color: p.border),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _narrow(BuildContext context) {
    return Column(
      children: [
        _NarrowTopBar(dir: widget.dir),
        Expanded(child: widget.child),
        _BottomNav(
          dir: widget.dir,
          navIndex: widget.navIndex,
          onNavChanged: widget.onNavChanged,
        ),
      ],
    );
  }
}

/// 桌面侧栏。
class _SideRail extends StatelessWidget {
  final DirTokens dir;
  final int navIndex;
  final ValueChanged<int> onNavChanged;
  const _SideRail({required this.dir, required this.navIndex, required this.onNavChanged});

  @override
  Widget build(BuildContext context) {
    final p = dir.palette;
    return Container(
      width: 208,
      color: p.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BrandHeader(dir: dir),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.spaceSm, horizontal: AppSpacing.spaceXs),
              children: [
                for (var i = 0; i < navEntries.length; i++)
                  _NavTile(
                    dir: dir,
                    entry: navEntries[i],
                    selected: i == navIndex,
                    onTap: () => onNavChanged(i),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          _IdentityFooter(dir: dir),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final DirTokens dir;
  const _BrandHeader({required this.dir});
  @override
  Widget build(BuildContext context) {
    final p = dir.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.spaceLg, AppSpacing.spaceLg, AppSpacing.spaceLg, AppSpacing.spaceMd),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: p.accent,
              borderRadius: BorderRadius.circular(dir.radiusSm),
            ),
            child: Icon(Icons.water_drop, size: 16, color: p.textOnAccent),
          ),
          AppSpacing.spaceXs.wSpace,
          Text('流水 · 供应商端',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: p.textPrimary)),
        ],
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final DirTokens dir;
  final NavEntry entry;
  final bool selected;
  final VoidCallback onTap;
  const _NavTile(
      {required this.dir, required this.entry, required this.selected, required this.onTap});
  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final p = widget.dir.palette;
    final active = widget.selected;
    final fg = active ? p.accent : p.textSecondary;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spaceSm, vertical: AppSpacing.spaceXs + 2),
          decoration: BoxDecoration(
            color: active ? p.accentSoft : (_hover ? p.surfaceAlt : Colors.transparent),
            borderRadius: BorderRadius.circular(widget.dir.radiusSm),
          ),
          child: Row(
            children: [
              Icon(widget.entry.icon, size: 18, color: fg),
              const SizedBox(width: AppSpacing.spaceSm),
              Text(widget.entry.label,
                  style: TextStyle(
                      fontSize: 13,
                      color: fg,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityFooter extends StatelessWidget {
  final DirTokens dir;
  const _IdentityFooter({required this.dir});
  @override
  Widget build(BuildContext context) {
    final p = dir.palette;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: p.positive, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.spaceXs),
          Expanded(
            child: Text(sampleData.vendor.shortAddr,
                style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: p.textSecondary)),
          ),
          Text('${sampleData.vendor.balanceUsdt.toStringAsFixed(0)} USDT',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary)),
        ],
      ),
    );
  }
}

/// 窄屏顶栏。
class _NarrowTopBar extends StatelessWidget {
  final DirTokens dir;
  const _NarrowTopBar({required this.dir});
  @override
  Widget build(BuildContext context) {
    final p = dir.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.spaceMd, AppSpacing.spaceLg, AppSpacing.spaceMd, AppSpacing.spaceSm),
      color: p.surface,
      child: Row(
        children: [
          Icon(Icons.water_drop, size: 18, color: p.accent),
          const SizedBox(width: AppSpacing.spaceXs),
          Text('供应商端',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: p.textPrimary)),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: p.positive, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.space2xs),
          Text(sampleData.vendor.shortAddr,
              style: TextStyle(
                  fontSize: 12, fontFamily: 'monospace', color: p.textSecondary)),
        ],
      ),
    );
  }
}

/// 窄屏底部导航(前 5 项 + 更多)。
class _BottomNav extends StatelessWidget {
  final DirTokens dir;
  final int navIndex;
  final ValueChanged<int> onNavChanged;
  const _BottomNav({required this.dir, required this.navIndex, required this.onNavChanged});
  @override
  Widget build(BuildContext context) {
    final p = dir.palette;
    final items = navEntries.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < items.length; i++)
            _BottomTab(
              dir: dir,
              entry: items[i],
              selected: i == navIndex,
              onTap: () => onNavChanged(i),
            ),
        ],
      ),
    );
  }
}

class _BottomTab extends StatelessWidget {
  final DirTokens dir;
  final NavEntry entry;
  final bool selected;
  final VoidCallback onTap;
  const _BottomTab(
      {required this.dir, required this.entry, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = dir.palette;
    final fg = selected ? p.accent : p.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(entry.icon, size: 22, color: fg),
            const SizedBox(height: 2),
            Text(entry.label,
                style: TextStyle(fontSize: 10, color: fg, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
