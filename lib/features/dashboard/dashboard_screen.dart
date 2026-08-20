import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flowing_water/core/chain/chain_watcher_service.dart';
import 'package:flowing_water/core/crypto/identity_controller.dart';
import 'package:flowing_water/core/db/provider_log_dao.dart';
import 'package:flowing_water/core/providers.dart';
import 'package:flowing_water/core/relay/node_service.dart';
import 'package:flowing_water/shared/design/app_colors.dart';
import 'package:flowing_water/shared/design/app_spacing.dart';
import 'package:flowing_water/shared/design/app_text_styles.dart';
import 'package:flowing_water/shared/widgets/status_visuals.dart';

/// Dashboard 看板页(04):LLM 指标(周期 24h/7d/30d/累计)+ 节点健康 + 链上汇总 +
/// 模型明细。落地页(`/`),把两个 M5 占位页之一变成真实视图。
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);
    final period = ref.watch(dashboardPeriodProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('看板'),
        actions: [
          PopupMenuButton<DashboardPeriod>(
            tooltip: '周期',
            onSelected: (p) =>
                ref.read(dashboardPeriodProvider.notifier).state = p,
            itemBuilder: (_) => [
              for (final p in DashboardPeriod.values)
                PopupMenuItem<DashboardPeriod>(
                  value: p,
                  child: Row(
                    children: [
                      if (p == period)
                        const Padding(
                          padding: EdgeInsets.only(right: AppSpacing.spaceXs),
                          child: Icon(Icons.check,
                              size: 16, color: AppColors.accent),
                        ),
                      Text(p.label),
                    ],
                  ),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spaceMd,
                vertical: AppSpacing.spaceSm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timelapse, size: 16),
                  AppSpacing.spaceXs.wSpace,
                  Text(period.label, style: AppTextStyles.bodySecondary),
                  const Icon(Icons.arrow_drop_down,
                      size: 18, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
      body: metrics.when(
        data: (m) => _body(context, m),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败:$e')),
      ),
    );
  }

  Widget _body(BuildContext context, LlmMetrics m) {
    final kpis = <(String, String)>[
      ('总调用', '${m.total}'),
      ('完成率', m.total == 0 ? '—' : '${(m.completionRate * 100).round()}%'),
      ('收益(USDT)', _formatNusdToUsdt(m.amountNusd)),
      ('平均延迟', m.avgLatencyMs == 0 ? '—' : '${m.avgLatencyMs}ms'),
    ];
    return ListView(
      padding: AppSpacing.pagePaddingCompact,
      children: [
        const _HealthCard(),
        AppSpacing.spaceMd.hSpace,
        Wrap(
          spacing: AppSpacing.spaceXs,
          runSpacing: AppSpacing.spaceXs,
          children: [
            for (final k in kpis)
              SizedBox(width: 200, child: _KpiCard(label: k.$1, value: k.$2)),
          ],
        ),
        AppSpacing.spaceMd.hSpace,
        const _ChainSummaryCard(),
        AppSpacing.spaceMd.hSpace,
        _ModelBreakdownCard(metrics: m),
        AppSpacing.spaceMd.hSpace,
        const _VendorBreakdownCard(),
      ],
    );
  }
}

/// 节点健康卡:中转站连接态 / 链监听态 / 心跳延迟 / 供应商地址。
class _HealthCard extends ConsumerWidget {
  const _HealthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(nodeStatusProvider);
    final latency = ref.watch(nodeLatencyProvider).valueOrNull;
    final chain = ref.watch(chainWatcherStatusProvider);
    final address =
        ref.watch(identityControllerProvider).valueOrNull?.addressEip55 ??
            '—';
    final (sLabel, sColor) = nodeStatusVisual(status);
    final (cLabel, cColor) = chainWatcherStatusVisual(chain);
    final latencyText = status == NodeStatus.connected
        ? (latency == null ? '—' : '${latency}ms')
        : '—';
    return Card(
      child: Padding(
        padding: AppSpacing.cardPaddingCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('节点健康', style: AppTextStyles.h2),
            AppSpacing.space2xs.hSpace,
            _row('中转站', sLabel, sColor),
            _row('链监听', cLabel, cColor),
            _row('延迟', latencyText, AppColors.textSecondary),
            _row('地址', address, AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3xs),
        child: Row(
          children: [
            Text(k, style: AppTextStyles.caption),
            const Spacer(),
            Flexible(
              child: Text(
                v,
                style: AppTextStyles.bodySecondary.copyWith(color: color),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPaddingCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppTextStyles.label),
            AppSpacing.space3xs.hSpace,
            Text(value, style: AppTextStyles.number(size: 20)),
          ],
        ),
      ),
    );
  }
}

/// 链上结算累计汇总(笔数 + 应收 USDT),接 05/06/07 的 settlement 数据。
class _ChainSummaryCard extends ConsumerWidget {
  const _ChainSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary =
        ref.watch(chainSettlementSummaryProvider).valueOrNull ??
            ChainSummary.empty;
    return Card(
      child: Padding(
        padding: AppSpacing.cardPaddingCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('链上结算(累计)', style: AppTextStyles.h2),
                const Spacer(),
                Text('${summary.count} 笔', style: AppTextStyles.bodySecondary),
              ],
            ),
            AppSpacing.space2xs.hSpace,
            Text(
              '+ ${_formatUsdt(summary.receivedUsdtRaw)} USDT',
              style:
                  AppTextStyles.number(size: 18, color: AppColors.positive),
            ),
          ],
        ),
      ),
    );
  }
}

/// 模型明细:周期内按模型聚合的调用数 / 计费额(按计费额倒序,取前 8)。
class _ModelBreakdownCard extends StatelessWidget {
  const _ModelBreakdownCard({required this.metrics});
  final LlmMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPaddingCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('模型明细', style: AppTextStyles.h2),
            AppSpacing.space2xs.hSpace,
            if (metrics.byModel.isEmpty)
              const Text('周期内无流水', style: AppTextStyles.bodySecondary)
            else
              for (final m in metrics.byModel.take(8))
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.space3xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.modelName,
                          style: AppTextStyles.bodySecondary,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        child: Text('${m.calls} 次',
                            style: AppTextStyles.caption,
                            textAlign: TextAlign.end),
                      ),
                      SizedBox(
                        width: 92,
                        child: Text('${_formatNusdToUsdt(m.amountNusd)} USDT',
                            style: AppTextStyles.bodySecondary,
                            textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// 厂商明细(12):周期内按上游厂商聚合的收益(USDT)+ 调用数(按收益倒序,前 8)。
class _VendorBreakdownCard extends ConsumerWidget {
  const _VendorBreakdownCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(dashboardVendorBreakdownProvider).valueOrNull ??
        const <VendorBreakdown>[];
    return Card(
      child: Padding(
        padding: AppSpacing.cardPaddingCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('厂商明细', style: AppTextStyles.h2),
            AppSpacing.space2xs.hSpace,
            if (list.isEmpty)
              const Text('周期内无已结算厂商流水', style: AppTextStyles.bodySecondary)
            else
              for (final v in list.take(8))
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.space3xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(v.vendor,
                            style: AppTextStyles.bodySecondary,
                            overflow: TextOverflow.ellipsis),
                      ),
                      SizedBox(
                        width: 56,
                        child: Text('${v.calls} 次',
                            style: AppTextStyles.caption,
                            textAlign: TextAlign.end),
                      ),
                      SizedBox(
                        width: 92,
                        child: Text('${_formatNusdToUsdt(v.amountNusd)} USDT',
                            style: AppTextStyles.bodySecondary,
                            textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// USDT raw(6 位)→ 2 位小数(与 Settlements 页格式一致)。
String _formatUsdt(int raw) => (raw / 1e6).toStringAsFixed(2);

/// nUSD(nano;1 USDT = 1e9 nUSD)→ USDT,6 位小数(镜像上游 portal `formatNusd`)。
String _formatNusdToUsdt(int nusd) => (nusd / 1e9).toStringAsFixed(6);
