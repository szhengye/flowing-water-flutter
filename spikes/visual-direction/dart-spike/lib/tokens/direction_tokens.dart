import 'package:flutter/material.dart';

/// 单个视觉方向的语义色板。所有槽位都按「语义」命名,不按色相命名 ——
/// 这样 dashboard 代码只跟语义打交道,换方向只换这套值。
@immutable
class DirPalette {
  final Color bg;
  final Color surface;
  final Color surfaceAlt; // 斑马纹 / 次级面板
  final Color border;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnAccent;
  final Color accent; // 主交互色
  final Color accentSoft; // accent 的淡背景(选中态 / 徽章)
  final Color positive; // 已结算 / 在线 / 成功
  final Color warn; // 待结算 / 余额低
  final Color danger; // 断连 / 失败

  const DirPalette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnAccent,
    required this.accent,
    required this.accentSoft,
    required this.positive,
    required this.warn,
    required this.danger,
  });
}

/// 一个视觉方向的全部 token:色板 + 圆角刻度 + 阴影策略 + 字体策略。
///
/// 组织方式对应 listening-king 的 AppColors/AppSpacing/AppTheme,但因为本原型要
/// 同时承载 3 个方向,改成「每个方向一个 const 实例」,而不是 3 套并列的 static 类。
/// 真实 app 选定方向后,把它展平回 listening-king 那种 `AppColors` static 类即可。
@immutable
class DirTokens {
  final String key; // 'A' | 'B' | 'C'
  final String name; // 展示名
  final String blurb; // 一句话定位
  final DirPalette palette;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final List<BoxShadow>? cardShadow;
  final bool monoNumbers; // 数字是否用等宽(终端风)
  final bool isDark;

  const DirTokens({
    required this.key,
    required this.name,
    required this.blurb,
    required this.palette,
    this.radiusSm = 6,
    this.radiusMd = 10,
    this.radiusLg = 16,
    this.cardShadow,
    this.monoNumbers = false,
    this.isDark = false,
  });

  TextStyle number({double size = 22, FontWeight weight = FontWeight.w700}) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        fontFamily: monoNumbers ? 'monospace' : null,
        fontFeatures: monoNumbers ? const [FontFeature.tabularFigures()] : const [],
        color: palette.textPrimary,
      );

  ThemeData theme() {
    final p = palette;
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.surface,
      dividerColor: p.borderSubtle,
      colorScheme: (isDark ? ColorScheme.dark : ColorScheme.light)(
        primary: p.accent,
        secondary: p.accent,
        surface: p.surface,
        error: p.danger,
        onSurface: p.textPrimary,
      ),
    );
  }
}

/// 方向 A —— Terminal / Console
/// 暗色、等宽数字、发丝边框面板、无阴影。算力运营商的「机器房」气质:
/// 高密度、高对比、一切为看清状态与吞吐。参考 Grafana / 交易终端 / GitHub dark。
const dirTerminal = DirTokens(
  key: 'A',
  name: 'Terminal / Console',
  blurb: '暗色 · 等宽数字 · 发丝面板 · 高密度 —— 算力运营商的机器房气质',
  monoNumbers: true,
  isDark: true,
  radiusSm: 3,
  radiusMd: 5,
  radiusLg: 8,
  cardShadow: null,
  palette: DirPalette(
    bg: Color(0xFF0D1117),
    surface: Color(0xFF161B22),
    surfaceAlt: Color(0xFF1C2128),
    border: Color(0xFF30363D),
    borderSubtle: Color(0xFF21262D),
    textPrimary: Color(0xFFE6EDF3),
    textSecondary: Color(0xFF8B949E),
    textMuted: Color(0xFF6E7681),
    textOnAccent: Color(0xFF0D1117),
    accent: Color(0xFF38BDF8),
    accentSoft: Color(0x1F38BDF8),
    positive: Color(0xFF3FB950),
    warn: Color(0xFFD29922),
    danger: Color(0xFFF85149),
  ),
);

/// 方向 B —— Light Enterprise SaaS
/// 浅色、卡片化 KPI、柔和阴影、克制靛蓝主色、留白舒适。后台的「管理者仪表盘」气质:
/// 清爽、专业、信息分层明确。参考 Stripe / Vercel / Linear settings。
const dirEnterprise = DirTokens(
  key: 'B',
  name: 'Light Enterprise SaaS',
  blurb: '浅色 · 卡片 KPI · 柔和阴影 · 克制靛蓝 —— 管理者仪表盘气质',
  radiusSm: 8,
  radiusMd: 12,
  radiusLg: 16,
  cardShadow: [
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 12, offset: Offset(0, 4)),
  ],
  palette: DirPalette(
    bg: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1F5F9),
    border: Color(0xFFE2E8F0),
    borderSubtle: Color(0xFFEFF2F6),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF94A3B8),
    textOnAccent: Color(0xFFFFFFFF),
    accent: Color(0xFF4F46E5),
    accentSoft: Color(0xFFEEF2FF),
    positive: Color(0xFF16A34A),
    warn: Color(0xFFD97706),
    danger: Color(0xFFDC2626),
  ),
);

/// 方向 C —— Compact Pro Tool
/// 浅色、扁平发丝边框(无阴影)、窄侧栏、表格为主角、极小圆角。后台的「老手高效工具」气质:
/// 信息密度拉满、装饰降到最低、键盘优先。参考 Linear / Notion admin / Grafana light 表格。
const dirCompact = DirTokens(
  key: 'C',
  name: 'Compact Pro Tool',
  blurb: '浅色 · 发丝边框 · 窄侧栏 · 表格为主角 —— 老手高效工具气质',
  radiusSm: 3,
  radiusMd: 5,
  radiusLg: 8,
  cardShadow: null,
  palette: DirPalette(
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFFAFAFA),
    border: Color(0xFFE5E7EB),
    borderSubtle: Color(0xFFF3F4F6),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    textMuted: Color(0xFF9CA3AF),
    textOnAccent: Color(0xFFFFFFFF),
    accent: Color(0xFF111827), // 近黑交互色
    accentSoft: Color(0xFFF3F4F6),
    positive: Color(0xFF16A34A),
    warn: Color(0xFFD97706),
    danger: Color(0xFFDC2626),
  ),
);

const allDirections = [dirTerminal, dirEnterprise, dirCompact];
