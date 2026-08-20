import 'package:flutter/material.dart';
import '../tokens/direction_tokens.dart';
import '../tokens/app_spacing.dart';
import '../data/mock_data.dart';
import 'widgets.dart';

/// 方向 B —— Light Enterprise SaaS。
/// 浅色、卡片化 KPI、柔和阴影、克制靛蓝、舒适留白。
/// 布局:标题 + 连接 pill → 4 张 KPI 卡 → 24h 卡 → 请求卡 / 结算卡 双栏 → 模型卡。
class VariantBEnterprise extends StatelessWidget {
  final DirTokens dir;
  final DashboardData d;
  const VariantBEnterprise({super.key, required this.dir, required this.d});

  Widget _card({required Widget child, EdgeInsets? padding}) {
    final p = dir.palette;
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.spaceLg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(dir.radiusLg),
        border: Border.all(color: p.borderSubtle),
        boxShadow: dir.cardShadow,
      ),
      child: child,
    );
  }

  Widget _kpi({
    required String label,
    required String value,
    required IconData icon,
    String? trend,
    Color? trendColor,
  }) {
    final p = dir.palette;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.spaceXs),
              decoration: BoxDecoration(
                color: p.accentSoft,
                borderRadius: BorderRadius.circular(dir.radiusSm),
              ),
              child: Icon(icon, size: 16, color: p.accent),
            ),
            const Spacer(),
          ]),
          const SizedBox(height: AppSpacing.spaceMd),
          Text(value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(height: AppSpacing.space3xs),
          Text(label, style: TextStyle(fontSize: 13, color: p.textSecondary)),
          if (trend != null) ...[
            const SizedBox(height: AppSpacing.spaceXs),
            Text(trend, style: TextStyle(fontSize: 12, color: trendColor ?? p.positive, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = dir.palette;
    final c = d.connection;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spaceXl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题 + 连接 pill
              Row(children: [
                Text('Dashboard',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w700, color: p.textPrimary)),
                const SizedBox(width: AppSpacing.spaceMd),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spaceSm, vertical: AppSpacing.space3xs + 1),
                  decoration: BoxDecoration(
                    color: p.positive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(children: [
                    Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(color: p.positive, shape: BoxShape.circle)),
                    const SizedBox(width: AppSpacing.space2xs),
                    Text('Connected · ${c.latencyMs}ms',
                        style: TextStyle(fontSize: 12, color: p.positive, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const Spacer(),
                Text('up ${c.uptime}',
                    style: TextStyle(fontSize: 13, color: p.textSecondary)),
              ]),
              const SizedBox(height: AppSpacing.space2xs),
              Text('${d.vendor.shortAddr} · ${c.relayUrl}',
                  style: TextStyle(fontSize: 13, color: p.textMuted, fontFamily: 'monospace')),
              const SizedBox(height: AppSpacing.spaceXl),
              // KPI 卡片网格
              LayoutBuilder(builder: (context, con) {
                final cols = (con.maxWidth / 240).floor().clamp(2, 4);
                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AppSpacing.spaceMd,
                  mainAxisSpacing: AppSpacing.spaceMd,
                  childAspectRatio: 1.35,
                  children: [
                    _kpi(label: 'Balance (USDT)', value: d.vendor.balanceUsdt.toStringAsFixed(2), icon: Icons.account_balance_wallet_outlined, trend: '+\$73.20 pending'),
                    _kpi(label: 'Pending receivable', value: d.vendor.pendingUsdt.toStringAsFixed(2), icon: Icons.hourglass_bottom_outlined, trend: 'next settle 00:00', trendColor: p.warn),
                    _kpi(label: 'Requests / min', value: d.throughput.reqPerMin.toStringAsFixed(1), icon: Icons.bolt_outlined, trend: '${compactNum(d.throughput.tokensPerMin.round())} tok/min'),
                    _kpi(label: 'Success rate', value: '${d.throughput.successRate.toStringAsFixed(1)}%', icon: Icons.check_circle_outline, trend: 'p95 ${d.throughput.p95LatencyMs}ms'),
                  ],
                );
              }),
              const SizedBox(height: AppSpacing.spaceMd),
              // 24h
              _card(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('Throughput · last 24h',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.textPrimary)),
                    const Spacer(),
                    Text('${d.hourlyReqs.fold(0, (a, b) => a + b)} requests',
                        style: TextStyle(fontSize: 13, color: p.textSecondary)),
                  ]),
                  const SizedBox(height: AppSpacing.spaceMd),
                  Sparkbars(dir: dir, values: d.hourlyReqs, height: 72),
                ]),
              ),
              const SizedBox(height: AppSpacing.spaceMd),
              // 请求 / 结算 双栏
              LayoutBuilder(builder: (context, con) {
                final side = con.maxWidth >= 820;
                return Flex(
                  direction: side ? Axis.horizontal : Axis.vertical,
                  children: [
                    Expanded(flex: side ? 3 : 0, child: _requestsCard()),
                    SizedBox(width: side ? AppSpacing.spaceMd : 0, height: side ? 0 : AppSpacing.spaceMd),
                    Expanded(flex: side ? 2 : 0, child: _settlementsCard()),
                  ],
                );
              }),
              const SizedBox(height: AppSpacing.spaceMd),
              _modelsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) {
    final p = dir.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spaceSm),
      child: Text(t, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.textPrimary)),
    );
  }

  Widget _requestsCard() {
    final p = dir.palette;
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Recent requests'),
        DenseTable(
          dir: dir,
          headers: ['TIME', 'MODEL', 'TOKENS', 'STATUS', 'LATENCY', 'COST'],
          columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth(), 2: IntrinsicColumnWidth(), 3: IntrinsicColumnWidth(), 4: IntrinsicColumnWidth(), 5: IntrinsicColumnWidth()},
          rows: [
            for (final r in d.recentRequests)
              <Widget>[
                Text(r.time, style: TextStyle(fontSize: 13, fontFamily: 'monospace', color: p.textSecondary)),
                Text(r.model, style: TextStyle(fontSize: 13, color: p.textPrimary, fontWeight: FontWeight.w500)),
                Text('${r.tokensIn + r.tokensOut}', style: TextStyle(fontSize: 13, color: p.textSecondary)),
                Row(children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor(dir, r.status), shape: BoxShape.circle)),
                  const SizedBox(width: AppSpacing.space2xs),
                  Text(r.status, style: TextStyle(fontSize: 13, color: statusColor(dir, r.status), fontWeight: FontWeight.w600)),
                ]),
                Text('${r.latencyMs}ms', style: TextStyle(fontSize: 13, color: p.textSecondary)),
                Text(usd(r.costUsdt), style: TextStyle(fontSize: 13, fontFamily: 'monospace', color: p.textPrimary)),
              ],
          ],
        ),
      ]),
    );
  }

  Widget _settlementsCard() {
    final p = dir.palette;
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Chain settlements'),
        Column(children: [
          for (final s in d.settlements)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.spaceXs),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Epoch ${s.epoch}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textPrimary)),
                    Text(s.blockTime, style: TextStyle(fontSize: 12, color: p.textMuted)),
                  ]),
                ),
                Text('\$${s.amountUsdt.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.textPrimary)),
                const SizedBox(width: AppSpacing.spaceMd),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceXs, vertical: 2),
                  decoration: BoxDecoration(color: statusColor(dir, s.status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                  child: Text(s.status, style: TextStyle(fontSize: 11, color: statusColor(dir, s.status), fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
        ]),
      ]),
    );
  }

  Widget _modelsCard() {
    final p = dir.palette;
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Models · pricing'),
        DenseTable(
          dir: dir,
          headers: ['MODEL', 'RELAY ID', 'IN / 1k', 'OUT / 1k', 'STREAM', 'TODAY'],
          columnWidths: const {0: FlexColumnWidth(), 1: FlexColumnWidth(), 2: IntrinsicColumnWidth(), 3: IntrinsicColumnWidth(), 4: IntrinsicColumnWidth(), 5: IntrinsicColumnWidth()},
          rows: [
            for (final m in d.models)
              <Widget>[
                Text(m.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textPrimary)),
                Text(m.relayModel, style: TextStyle(fontSize: 13, fontFamily: 'monospace', color: p.textSecondary)),
                Text('\$${m.inPricePer1k}', style: TextStyle(fontSize: 13, color: p.textSecondary)),
                Text('\$${m.outPricePer1k}', style: TextStyle(fontSize: 13, color: p.textSecondary)),
                Text(m.stream ? 'yes' : 'no', style: TextStyle(fontSize: 13, color: p.positive)),
                Text(compactNum(m.todayReqs), style: TextStyle(fontSize: 13, color: p.textSecondary)),
              ],
          ],
        ),
      ]),
    );
  }
}
