import 'package:flutter/material.dart';
import '../tokens/direction_tokens.dart';
import '../tokens/app_spacing.dart';

/// 共享小工具(状态色 / sparkbars / 格式化)。共享工具不破坏变体的结构差异 ——
/// 各变体的布局/层级/主交互仍各自独立。

Color statusColor(DirTokens dir, String status) {
  switch (status) {
    case 'ok':
    case 'settled':
    case 'connected':
      return dir.palette.positive;
    case 'pending':
    case 'cancelled':
      return dir.palette.warn;
    case 'error':
    case 'disconnected':
      return dir.palette.danger;
    default:
      return dir.palette.textMuted;
  }
}

String usd(double v) => '\$${v.toStringAsFixed(v < 1 ? 4 : 2)}';
String compactNum(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k' : '$v';

/// 24h 请求量柱图。条的形状随 dir(圆角/色)走,但「柱图」本身是工具。
class Sparkbars extends StatelessWidget {
  final DirTokens dir;
  final List<int> values;
  final double height;
  const Sparkbars({super.key, required this.dir, required this.values, this.height = 40});

  @override
  Widget build(BuildContext context) {
    final max = values.fold<int>(1, (a, b) => a > b ? a : b);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final v in values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: FractionallySizedBox(
                  heightFactor: (v / max).clamp(0.04, 1.0),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: dir.palette.accent.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(dir.radiusSm),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 通用数据表(紧凑、发丝网格),C 变体大量复用;A/B 也可选用。
class DenseTable extends StatelessWidget {
  final DirTokens dir;
  final List<String> headers;
  final List<List<Widget>> rows;
  final Map<int, TableColumnWidth>? columnWidths;
  const DenseTable({
    super.key,
    required this.dir,
    required this.headers,
    required this.rows,
    this.columnWidths,
  });

  @override
  Widget build(BuildContext context) {
    final p = dir.palette;
    Widget cell(String text, {bool mono = false, Color? color, FontWeight w = FontWeight.w400}) =>
        Text(text,
            style: TextStyle(
                fontSize: 12,
                fontFamily: mono ? 'monospace' : null,
                color: color ?? p.textPrimary,
                fontWeight: w));
    return Table(
      columnWidths: columnWidths ?? {for (var i = 0; i < headers.length; i++) i: const FlexColumnWidth()},
      border: TableBorder(
        horizontalInside: BorderSide(color: p.borderSubtle, width: 1),
        top: BorderSide(color: p.borderSubtle, width: 1),
        bottom: BorderSide(color: p.borderSubtle, width: 1),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(color: p.surfaceAlt),
          children: [
            for (final h in headers)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spaceSm, vertical: AppSpacing.spaceXs),
                child: cell(h, color: p.textSecondary, w: FontWeight.w600),
              ),
          ],
        ),
        for (final r in rows)
          TableRow(
            children: [
              for (final w in r)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spaceSm, vertical: AppSpacing.spaceXs + 1),
                  child: w,
                ),
            ],
          ),
      ],
    );
  }
}
