import 'package:flutter/material.dart';
import '../tokens/direction_tokens.dart';
import '../tokens/app_spacing.dart';
import '../data/mock_data.dart';
import 'widgets.dart';

/// 方向 C —— Compact Pro Tool。
/// 浅色、扁平发丝边框、无阴影、窄侧栏、表格为主角、极小圆角、信息密度拉满。
/// 布局:薄工具条 → 一行内联微指标 → 请求表(主角)→ 模型/结算表。
class VariantCCompact extends StatelessWidget {
  final DirTokens dir;
  final DashboardData d;
  const VariantCCompact({super.key, required this.dir, required this.d});

  Widget _stat(String label, String value, {Color? valueColor}) {
    final p = dir.palette;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(label.toUpperCase(),
          style: TextStyle(fontSize: 9, letterSpacing: 0.8, fontWeight: FontWeight.w600, color: p.textMuted)),
      const SizedBox(height: 1),
      Text(value,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? p.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()])),
    ]);
  }

  Widget _ribbonItem(String label, String value, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd, vertical: AppSpacing.spaceXs),
        child: _stat(label, value, valueColor: valueColor),
      );

  Widget _sectionHeader(String title, String count) {
    final p = dir.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceSm, vertical: AppSpacing.spaceXs),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        border: Border(top: BorderSide(color: p.border), bottom: BorderSide(color: p.borderSubtle)),
      ),
      child: Row(children: [
        Text(title.toUpperCase(),
            style: TextStyle(fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w700, color: p.textSecondary)),
        const SizedBox(width: AppSpacing.spaceXs),
        Text(count, style: TextStyle(fontSize: 10, color: p.textMuted)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = dir.palette;
    final c = d.connection;
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 薄工具条
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spaceLg, vertical: AppSpacing.spaceSm),
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(bottom: BorderSide(color: p.border)),
            ),
            child: Row(children: [
              Text('Dashboard',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.textPrimary)),
              const SizedBox(width: AppSpacing.spaceMd),
              Row(children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: p.positive, shape: BoxShape.circle)),
                const SizedBox(width: AppSpacing.space2xs),
                Text('Connected ${c.latencyMs}ms',
                    style: TextStyle(fontSize: 11, color: p.textSecondary)),
                const SizedBox(width: AppSpacing.spaceMd),
                Text(d.vendor.shortAddr,
                    style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: p.textSecondary)),
              ]),
              const Spacer(),
              Text('${d.vendor.balanceUsdt.toStringAsFixed(2)} USDT',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.textPrimary)),
            ]),
          ),
          // 内联微指标 ribbon
          Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.borderSubtle))),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _ribbonItem('Balance', d.vendor.balanceUsdt.toStringAsFixed(2)),
                Container(width: 1, height: 28, color: p.borderSubtle),
                _ribbonItem('Pending', d.vendor.pendingUsdt.toStringAsFixed(2), valueColor: p.warn),
                Container(width: 1, height: 28, color: p.borderSubtle),
                _ribbonItem('Req/min', d.throughput.reqPerMin.toStringAsFixed(1)),
                Container(width: 1, height: 28, color: p.borderSubtle),
                _ribbonItem('Tokens/min', compactNum(d.throughput.tokensPerMin.round())),
                Container(width: 1, height: 28, color: p.borderSubtle),
                _ribbonItem('p95', '${d.throughput.p95LatencyMs}ms'),
                Container(width: 1, height: 28, color: p.borderSubtle),
                _ribbonItem('Success', '${d.throughput.successRate.toStringAsFixed(1)}%'),
              ]),
            ),
          ),
          // 请求表(主角)
          _sectionHeader('Recent requests', '${d.recentRequests.length}'),
          _requestsTable(),
          const SizedBox(height: AppSpacing.spaceLg),
          // 模型表
          _sectionHeader('Models · pricing', '${d.models.length}'),
          _modelsTable(),
          const SizedBox(height: AppSpacing.spaceLg),
          // 结算表
          _sectionHeader('Chain settlements', '${d.settlements.length}'),
          _settlementsTable(),
          const SizedBox(height: AppSpacing.space2xl),
        ],
      ),
    );
  }

  Widget _cell(String t, {bool mono = false, Color? color, FontWeight w = FontWeight.w400}) => Text(t,
      style: TextStyle(fontSize: 12, fontFamily: mono ? 'monospace' : null, color: color ?? dir.palette.textPrimary, fontWeight: w));

  Widget _requestsTable() => DenseTable(
        dir: dir,
        headers: ['TIME', 'MODEL', 'IN', 'OUT', 'STATUS', 'LAT', 'COST'],
        columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth(), 2: IntrinsicColumnWidth(), 3: IntrinsicColumnWidth(), 4: IntrinsicColumnWidth(), 5: IntrinsicColumnWidth(), 6: IntrinsicColumnWidth()},
        rows: [
          for (final r in d.recentRequests)
            <Widget>[
              _cell(r.time, mono: true, color: dir.palette.textSecondary),
              _cell(r.model, w: FontWeight.w500),
              _cell('${r.tokensIn}', mono: true, color: dir.palette.textSecondary),
              _cell('${r.tokensOut}', mono: true, color: dir.palette.textSecondary),
              _cell(r.status, color: statusColor(dir, r.status), w: FontWeight.w600),
              _cell('${r.latencyMs}ms', mono: true, color: dir.palette.textSecondary),
              _cell(usd(r.costUsdt), mono: true),
            ],
        ],
      );

  Widget _modelsTable() => DenseTable(
        dir: dir,
        headers: ['MODEL', 'RELAY ID', 'IN/1k', 'OUT/1k', 'STREAM', 'TODAY REQ', 'TODAY TOK'],
        columnWidths: const {0: FlexColumnWidth(), 1: FlexColumnWidth(), 2: IntrinsicColumnWidth(), 3: IntrinsicColumnWidth(), 4: IntrinsicColumnWidth(), 5: IntrinsicColumnWidth(), 6: IntrinsicColumnWidth()},
        rows: [
          for (final m in d.models)
            <Widget>[
              _cell(m.name, w: FontWeight.w600),
              _cell(m.relayModel, mono: true, color: dir.palette.textSecondary),
              _cell('\$${m.inPricePer1k}', mono: true, color: dir.palette.textSecondary),
              _cell('\$${m.outPricePer1k}', mono: true, color: dir.palette.textSecondary),
              _cell(m.stream ? 'yes' : 'no', color: dir.palette.positive),
              _cell(compactNum(m.todayReqs), mono: true, color: dir.palette.textSecondary),
              _cell(compactNum(m.todayTokens), mono: true, color: dir.palette.textSecondary),
            ],
        ],
      );

  Widget _settlementsTable() => DenseTable(
        dir: dir,
        headers: ['EPOCH', 'BLOCK TIME', 'AMOUNT', 'TX', 'STATUS'],
        columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth(), 2: IntrinsicColumnWidth(), 3: IntrinsicColumnWidth(), 4: IntrinsicColumnWidth()},
        rows: [
          for (final s in d.settlements)
            <Widget>[
              _cell(s.epoch, mono: true, w: FontWeight.w600),
              _cell(s.blockTime, color: dir.palette.textSecondary),
              _cell('\$${s.amountUsdt.toStringAsFixed(2)}', mono: true),
              _cell(s.txHash, mono: true, color: dir.palette.textSecondary),
              _cell(s.status, color: statusColor(dir, s.status), w: FontWeight.w600),
            ],
        ],
      );
}
