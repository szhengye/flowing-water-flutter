import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/providers.dart';
import 'package:flowing_water/shared/design/app_colors.dart';
import 'package:flowing_water/shared/design/app_spacing.dart';
import 'package:flowing_water/shared/design/app_text_styles.dart';

/// 按 settle tx 查关联中转流水(07;对齐上游 `/chain-settlements/by-tx`
/// → `getRecordsBySettleTx`)。Settlements 行点击 / Wallet USDT 交易钻取共用。
///
/// 展示该 settle tx 回填到的 provider_log 记录(requestId / 模型 / 金额 / 状态)。
Future<void> showRelayRecordsSheet(BuildContext context, String tx) {
  return showModalBottomSheet<void>(
    context: context,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => _RelayRecordsSheet(tx: tx),
  );
}

class _RelayRecordsSheet extends ConsumerStatefulWidget {
  const _RelayRecordsSheet({required this.tx});
  final String tx;

  @override
  ConsumerState<_RelayRecordsSheet> createState() => _RelayRecordsSheetState();
}

class _RelayRecordsSheetState extends ConsumerState<_RelayRecordsSheet> {
  late final Future<List<ProviderLogRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(providerLogDaoProvider).getBySettleTx(widget.tx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<ProviderLogRow>>(
        future: _future,
        builder: (context, snap) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.cardPaddingCompact,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('关联中转流水', style: AppTextStyles.h2),
                      AppSpacing.spaceXs.hSpace,
                      SelectableText(widget.tx, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ),
              if (snap.connectionState != ConnectionState.done)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snap.hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('加载失败:${snap.error}',
                        style: AppTextStyles.bodySecondary),
                  ),
                )
              else if (snap.data!.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('无关联中转流水(尚未对账到此 tx)',
                        style: AppTextStyles.bodySecondary),
                  ),
                )
              else
                SliverList.separated(
                  itemCount: snap.data!.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.borderSubtle),
                  itemBuilder: (_, i) => _RecordTile(row: snap.data![i]),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.row});
  final ProviderLogRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.listItemPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(row.requestId, style: AppTextStyles.bodySecondary),
                AppSpacing.space3xs.hSpace,
                Text('${row.modelName} · ${row.processingStatus}',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${row.amount} nUSD', style: AppTextStyles.body),
              AppSpacing.space3xs.hSpace,
              _ChainStatusBadge(status: row.chainStatus),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChainStatusBadge extends StatelessWidget {
  const _ChainStatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'on_chain_settled' => ('已结算', AppColors.positive),
      'on_chain_not_settled' => ('未结算', AppColors.warn),
      _ => ('未上链', AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: color)),
    );
  }
}
