import 'package:flutter/material.dart';

/// 语义色板 + 圆角刻度。
///
/// wayfinder 08 裁决:**C 骨架**(浅色 / 发丝边框 / 紧凑 / 近黑结构)+ **蓝 `#2563EB`
/// accent**(active 导航 / 链接 / 焦点 / 主操作)+ 语义色不变。light 默认,暗色延后。
///
/// 组织镜像 listening-king 的 `AppColors`(私有构造 + `static const` 语义槽)。
/// 槽位按「语义」命名而非色相 —— 换主题只换值,业务代码只跟语义打交道。
///
/// 展平自 spike `spikes/visual-direction/dart-spike/lib/tokens/direction_tokens.dart`
/// 的 `dirCompact`(C)色板,accent 由 C 的近黑替换为裁决的蓝。
@immutable
class AppColors {
  const AppColors._();

  // 背景 / 表面
  static const Color bg = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFFAFAFA); // 斑马纹 / 次级面板

  // 边框(发丝)
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderSubtle = Color(0xFFF3F4F6);

  // 文字
  static const Color textPrimary = Color(0xFF111827); // 近黑结构
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // accent(蓝 —— 08 裁决:active 导航 / 链接 / 焦点 / 主操作)
  static const Color accent = Color(0xFF2563EB);
  static const Color accentSoft = Color(0xFFEFF6FF); // accent 淡背景(选中 / 徽章)

  // 语义
  static const Color positive = Color(0xFF16A34A); // 已结算 / 在线 / 成功
  static const Color warn = Color(0xFFD97706); // 待结算 / 余额低
  static const Color danger = Color(0xFFDC2626); // 断连 / 失败

  // 圆角刻度(C:3/5/8,08 收敛到 3–5)
  static const double radiusSm = 3.0;
  static const double radiusMd = 5.0;
  static const double radiusLg = 8.0;
}
