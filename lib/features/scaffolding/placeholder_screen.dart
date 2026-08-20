import 'package:flutter/material.dart';
import 'package:flowing_water/shared/design/app_spacing.dart';
import 'package:flowing_water/shared/design/app_text_styles.dart';

/// M0 通用占位页。各功能页在所属 milestone 阶段(M1–M5)由真实实现替换。
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, this.milestone});

  final String title;
  final String? milestone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppTextStyles.h1),
          AppSpacing.spaceMd.hSpace,
          Text(
            milestone != null ? '占位 · 待 $milestone 实现' : '占位 · 待实现',
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}
