import 'package:flutter/material.dart';
import '../tokens/direction_tokens.dart';
import '../tokens/app_spacing.dart';
import '../data/mock_data.dart';
import 'widgets.dart';

/// 方向 A —— Terminal / Console。
/// 暗色、等宽数字、发丝边框面板、无阴影、大写微标签。
/// 布局:状态条 → 6 宫格扁平 stat 面板 → 24h 柱图 → 请求表 → 模型/结算双栏。
class VariantATerminal extends StatelessWidget {
  final DirTokens dir;
  final DashboardData d;
  const VariantATerminal({super.key, required this.dir, required this.d});

  Widget _microLabel(String t) => Text(t.toUpperCase(),
      style: TextStyle(
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
          color: dir.palette.textMuted,
          fontFamily: 'monospace'));

  Widget _statPanel(String label, String value, {Color? valueColor}) {
    final p = dir.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceSm),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border, width: 1),
        borderRadius: BorderRadius.circular(dir.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _microLabel(label),
          const SizedBox(height: AppSpacing.spaceXs),
          Text(value,
              style: dir.number(size: 20).copyWith(color: valueColor ?? p.textPrimary)),
        ],
      ),
    );
  }

  Widget _panel({required String title, required Widget child, Widget? trailing}) {
    final p = dir.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceSm),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border, width: 1),
        borderRadius: BorderRadius.circular(dir.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _microLabel(title),
            const Spacer(),
            ?trailing,
          ]),
          const SizedBox(height: AppSpacing.spaceXs),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = dir.palette;
    final c = d.connection;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态条
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spaceSm, vertical: AppSpacing.spaceXs),
            decoration: BoxDecoration(
              color: p.surface,
              border: Border.all(color: p.border),
              borderRadius: BorderRadius.circular(dir.radiusSm),
            ),
            child: Row(children: [
              Text('●', style: TextStyle(color: p.positive, fontSize: 12)),
              const SizedBox(width: AppSpacing.spaceXs),
              Text('CONNECTED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.positive, fontFamily: 'monospace')),
              const SizedBox(width: AppSpacing.spaceLg),
              _mono(c.relayUrl, p.textSecondary),
              const SizedBox(width: AppSpacing.spaceLg),
              _mono('${c.latencyMs}ms', p.textSecondary),
              const SizedBox(width: AppSpacing.spaceLg),
              _mono('up ${c.uptime}', p.textSecondary),
              const SizedBox(width: AppSpacing.spaceLg),
              _mono('hb ${c.lastHeartbeat}', p.textMuted),
            ]),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          // 6 宫格
          LayoutBuilder(builder: (context, con) {
            final cols = (con.maxWidth / 150).floor().clamp(2, 6);
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.spaceSm,
              mainAxisSpacing: AppSpacing.spaceSm,
              childAspectRatio: 2.2,
              children: [
                _statPanel('Balance', '${d.vendor.balanceUsdt.toStringAsFixed(2)} USDT'),
                _statPanel('Pending', '${d.vendor.pendingUsdt.toStringAsFixed(2)} USDT', valueColor: p.warn),
                _statPanel('Req / min', d.throughput.reqPerMin.toStringAsFixed(1)),
                _statPanel('Tokens / min', compactNum(d.throughput.tokensPerMin.round())),
                _statPanel('Success', '${d.throughput.successRate.toStringAsFixed(1)}%'),
                _statPanel('p95', '${d.throughput.p95LatencyMs}ms'),
              ],
            );
          }),
          const SizedBox(height: AppSpacing.spaceMd),
          // 24h 柱图
          _panel(
            title: 'Throughput · 24h',
            trailing: _mono('${d.hourlyReqs.fold(0, (a, b) => a + b)} reqs', p.textSecondary),
            child: Sparkbars(dir: dir, values: d.hourlyReqs, height: 56),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          // 请求表
          _panel(
            title: 'Recent requests',
            trailing: _mono('${d.recentRequests.length}', p.textMuted),
            child: _requestsTable(),
          ),
          const SizedBox(height: AppSpacing.spaceMd),
          // 模型 / 结算 双栏
          LayoutBuilder(builder: (context, con) {
            final side = con.maxWidth >= 760;
            return Flex(
              direction: side ? Axis.horizontal : Axis.vertical,
              children: [
                Expanded(
                  flex: side ? 3 : 0,
                  child: _panel(title: 'Models · pricing', child: _modelsTable()),
                ),
                SizedBox(width: side ? AppSpacing.spaceMd : 0, height: side ? 0 : AppSpacing.spaceMd),
                Expanded(
                  flex: side ? 2 : 0,
                  child: _panel(title: 'Settlements', child: _settlementsTable()),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _mono(String t, Color c) =>
      Text(t, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: c));

  Widget _requestsTable() => DenseTable(
        dir: dir,
        headers: ['TIME', 'MODEL', 'IN', 'OUT', 'STATUS', 'LAT', 'COST'],
        columnWidths: const {
          0: IntrinsicColumnWidth(), 1: FlexColumnWidth(), 2: IntrinsicColumnWidth(),
          3: IntrinsicColumnWidth(), 4: IntrinsicColumnWidth(),
          5: IntrinsicColumnWidth(), 6: IntrinsicColumnWidth(),
        },
        rows: [
          for (final r in d.recentRequests)
            <Widget>[
              monoCell(r.time), monoCell(r.model), monoCell('${r.tokensIn}'),
              monoCell('${r.tokensOut}'),
              statusCell(r.status), monoCell('${r.latencyMs}ms'),
              monoCell(usd(r.costUsdt)),
            ],
        ],
      );

  Widget _modelsTable() => DenseTable(
        dir: dir,
        headers: ['MODEL', 'IN/1k', 'OUT/1k', 'TODAY'],
        columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth(), 2: IntrinsicColumnWidth(), 3: IntrinsicColumnWidth()},
        rows: [
          for (final m in d.models)
            <Widget>[monoCell(m.name), monoCell('\$${m.inPricePer1k}'), monoCell('\$${m.outPricePer1k}'), monoCell(compactNum(m.todayReqs))],
        ],
      );

  Widget _settlementsTable() => DenseTable(
        dir: dir,
        headers: ['EPOCH', 'TIME', 'AMOUNT', 'STATUS'],
        columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth(), 2: IntrinsicColumnWidth(), 3: IntrinsicColumnWidth()},
        rows: [
          for (final s in d.settlements)
            <Widget>[monoCell(s.epoch), monoCell(s.blockTime.substring(5)), monoCell(s.amountUsdt.toStringAsFixed(2)), statusCell(s.status)],
        ],
      );

  // cell builders —— DenseTable 接收 Widget 列表
  Widget monoCell(String t) =>
      Text(t, style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: dir.palette.textPrimary));
  Widget statusCell(String s) => Text(s.toUpperCase(),
      style: TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w700,
          color: statusColor(dir, s)));
}
