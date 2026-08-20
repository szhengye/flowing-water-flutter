import 'package:flutter/material.dart';

/// 间距系统 —— 4px 基础单位。
///
/// 组织方式借自 listening-king 的 AppSpacing(私有构造 + static const 刻度 +
/// EdgeInsets 预设 + num 扩展),换成了供应商后台需要的中性刻度。
/// 这是「刻度菜单」:各方向(variant)按自己的密度从中挑值,而不是乘一个倍率。
class AppSpacing {
  AppSpacing._();

  static const double unit = 4.0;

  // 线性刻度
  static const double space3xs = 2.0;
  static const double space2xs = 4.0;
  static const double spaceXs = 8.0;
  static const double spaceSm = 12.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double space2xl = 48.0;
  static const double space3xl = 64.0;

  // EdgeInsets 预设
  static const EdgeInsets cardPadding = EdgeInsets.all(spaceLg);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(spaceMd);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: spaceMd,
    vertical: spaceSm,
  );
  static const EdgeInsets pagePadding = EdgeInsets.all(spaceXl);
  static const EdgeInsets pagePaddingCompact = EdgeInsets.all(spaceLg);
}

/// 便捷扩展 —— `16.hSpace` / `24.wSpace`。
extension SpacingExtension on num {
  SizedBox get hSpace => SizedBox(height: toDouble());
  SizedBox get wSpace => SizedBox(width: toDouble());
}
