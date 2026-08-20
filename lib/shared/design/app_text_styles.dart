import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 文字样式 —— wayfinder 08:light 默认、紧凑专业后台风。
///
/// 数字样式用 `tabularFigures`(等宽数字列对齐),不强制 monospace 字体
/// (C 方向非等宽,但数字列需对齐)。
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle h1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  /// 数字(KPI / 余额 / token / 金额)—— tabular 等宽对齐。
  static TextStyle number({
    double size = 22,
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
