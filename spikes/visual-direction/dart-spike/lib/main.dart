import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tokens/direction_tokens.dart';
import 'data/mock_data.dart';
import 'shell/app_shell.dart';
import 'dashboard/variant_a_terminal.dart';
import 'dashboard/variant_b_enterprise.dart';
import 'dashboard/variant_c_compact.dart';
import 'switcher/variant_switcher.dart';

/// 08 视觉方向原型 —— 三个结构不同的「专业供应商后台风」方向,可跑可切换。
/// 一次性原型,供取舍;选定方向后,把该方向展平回 listening-king 式
/// AppColors/AppSpacing/AppTheme static 类即可。
void main() {
  runApp(const VisualPrototypeApp());
}

class VisualPrototypeApp extends StatelessWidget {
  const VisualPrototypeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '流水 · 供应商端 — 视觉方向原型',
      home: _PrototypeRoot(),
    );
  }
}

class _PrototypeRoot extends StatefulWidget {
  const _PrototypeRoot();

  @override
  State<_PrototypeRoot> createState() => _PrototypeRootState();
}

class _PrototypeRootState extends State<_PrototypeRoot> {
  int _dirIndex = 1; // 默认 B(企业 SaaS)开场
  int _navIndex = 0; // Dashboard
  final FocusNode _focusNode = FocusNode();

  DirTokens get _dir => allDirections[_dirIndex];

  void _cycle(int next) =>
      setState(() => _dirIndex = (next + allDirections.length) % allDirections.length);

  /// 输入框聚焦时不拦截方向键(UI.md 要求)。
  bool get _editing {
    final f = FocusManager.instance.primaryFocus;
    return f?.context?.widget is EditableText;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (_editing) return KeyEventResult.ignored;
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _cycle(_dirIndex - 1);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _cycle(_dirIndex + 1);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Widget _dashboardFor(DirTokens dir) {
    switch (dir.key) {
      case 'A':
        return VariantATerminal(dir: dir, d: sampleData);
      case 'B':
        return VariantBEnterprise(dir: dir, d: sampleData);
      case 'C':
        return VariantCCompact(dir: dir, d: sampleData);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _placeholder(DirTokens dir, String name) {
    final p = dir.palette;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.construction_outlined, size: 40, color: p.textMuted),
        const SizedBox(height: 12),
        Text('$name — 本原型仅实现 Dashboard 一屏',
            style: TextStyle(fontSize: 14, color: p.textSecondary)),
        const SizedBox(height: 4),
        Text('切方向比较视觉;选定方向后,其余页面沿用同套 token。',
            style: TextStyle(fontSize: 12, color: p.textMuted)),
      ]),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dir = _dir;
    final isDashboard = _navIndex == 0;
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      autofocus: true,
      child: Theme(
        data: dir.theme(),
        child: Scaffold(
          backgroundColor: dir.palette.bg,
          body: Stack(
            children: [
              AppShell(
                dir: dir,
                navIndex: _navIndex,
                onNavChanged: (i) => setState(() => _navIndex = i),
                child: isDashboard
                    ? _dashboardFor(dir)
                    : _placeholder(dir, navEntries[_navIndex].label),
              ),
              VariantSwitcher(
                dirs: allDirections,
                index: _dirIndex,
                onCycle: _cycle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
