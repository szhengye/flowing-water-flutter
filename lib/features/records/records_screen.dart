import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/providers.dart';
import 'package:flowing_water/shared/design/app_colors.dart';
import 'package:flowing_water/shared/design/app_spacing.dart';
import 'package:flowing_water/shared/design/app_text_styles.dart';

/// 中转流水页(04):provider_log 只读列表 + 处理状态 / 链态筛选。
///
/// 筛选态在全局 provider(recordsProcessingStatusProvider / recordsChainStatusProvider),
/// 列表经 drift watch 反应式刷新。无写操作 —— 供应商不手改计费流水。
class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recordsListProvider);
    final pStatus = ref.watch(recordsProcessingStatusProvider);
    final cStatus = ref.watch(recordsChainStatusProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('中转流水')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spaceLg,
              AppSpacing.spaceMd,
              AppSpacing.spaceLg,
              AppSpacing.spaceSm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _FilterDropdown(
                    label: '处理状态',
                    value: pStatus,
                    items: const [
                      _Opt(null, '全部'),
                      _Opt('pending', '待处理'),
                      _Opt('completed', '已完成'),
                      _Opt('failed', '失败'),
                    ],
                    onChanged: (v) => ref
                        .read(recordsProcessingStatusProvider.notifier)
                        .state = v,
                  ),
                ),
                AppSpacing.spaceMd.wSpace,
                Expanded(
                  child: _FilterDropdown(
                    label: '链态',
                    value: cStatus,
                    items: const [
                      _Opt(null, '全部'),
                      _Opt('not_on_chain', '未上链'),
                      _Opt('on_chain_settled', '已结算'),
                      _Opt('on_chain_not_settled', '未结算'),
                    ],
                    onChanged: (v) =>
                        ref.read(recordsChainStatusProvider.notifier).state = v,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _body(async)),
        ],
      ),
    );
  }

  Widget _body(AsyncValue<List<ProviderLogRow>> async) => async.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text('无匹配流水', style: AppTextStyles.bodySecondary),
            );
          }
          return ListView.separated(
            padding: AppSpacing.pagePaddingCompact,
            itemCount: list.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.spaceXs),
            itemBuilder: (_, i) => _RecordTile(row: list[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败:$e')),
      );
}

class _Opt {
  const _Opt(this.value, this.label);
  final String? value;
  final String label;
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final List<_Opt> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final o in items)
          DropdownMenuItem<String?>(value: o.value, child: Text(o.label)),
      ],
      onChanged: onChanged,
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.row});
  final ProviderLogRow row;

  @override
  Widget build(BuildContext context) {
    final time = row.createdAt == 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.createdAt * 1000);
    return Card(
      child: Padding(
        padding: AppSpacing.listItemPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.modelName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _ProcessingBadge(processing: row.processingStatus),
              ],
            ),
            AppSpacing.space2xs.hSpace,
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.spaceMd,
              children: [
                _kv('入/出', '${row.inputTokens}/${row.outputTokens}'),
                _kv('计费', '${row.amount} nUSD'),
                if (row.latencyMs > 0) _kv('延迟', '${row.latencyMs}ms'),
              ],
            ),
            AppSpacing.space3xs.hSpace,
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.spaceXs,
              children: [
                _ChainBadge(chain: row.chainStatus),
                if (time != null)
                  Text('${time.toLocal()}'.split('.').first,
                      style: AppTextStyles.caption),
              ],
            ),
            if (row.processingStatus == 'failed' &&
                row.errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.space3xs),
                child: Text(
                  row.errorMessage,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.danger),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Text.rich(
        TextSpan(
          style: AppTextStyles.caption,
          children: [
            TextSpan(text: '$k '),
            TextSpan(
                text: v,
                style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
          ],
        ),
      );
}

class _ProcessingBadge extends StatelessWidget {
  const _ProcessingBadge({required this.processing});
  final String processing;
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (processing) {
      'completed' => ('已完成', AppColors.positive),
      'failed' => ('失败', AppColors.danger),
      'pending' => ('待处理', AppColors.warn),
      _ => (processing, AppColors.textMuted),
    };
    return _Badge(label: label, color: color);
  }
}

class _ChainBadge extends StatelessWidget {
  const _ChainBadge({required this.chain});
  final String chain;
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (chain) {
      'on_chain_settled' => ('已结算', AppColors.positive),
      'on_chain_not_settled' => ('未结算', AppColors.warn),
      _ => ('未上链', AppColors.textMuted),
    };
    return _Badge(label: label, color: color);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
