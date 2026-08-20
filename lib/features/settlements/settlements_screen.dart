import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flowing_water/core/chain/chain_watcher_service.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/errors/friendly_error.dart';
import 'package:flowing_water/core/providers.dart';
import 'package:flowing_water/shared/design/app_colors.dart';
import 'package:flowing_water/shared/design/app_spacing.dart';
import 'package:flowing_water/shared/design/app_text_styles.dart';
import 'package:flowing_water/shared/widgets/relay_records_sheet.dart';

/// 链上 Settled 列表(07;drift watch → watcher 落地新事件自动刷新)。
final settlementListProvider = StreamProvider<List<ProviderChainSettlementRow>>(
  (ref) => ref.watch(providerChainSettlementDaoProvider).watchAll(),
);

/// 链上结算页(07):Settled 事件只读列表 + tx 筛选 + 全量同步(对齐上游
/// `GET /chain-settlements` 列表 + `POST /sync-chain-status {mode:"full"}`)。
///
/// 逐行 tx+logIndex 对账[进阶] / 未匹配重试[进阶] 毕业到 09(06 已自动对账采集)。
class SettlementsScreen extends ConsumerStatefulWidget {
  const SettlementsScreen({super.key});

  @override
  ConsumerState<SettlementsScreen> createState() => _SettlementsScreenState();
}

class _SettlementsScreenState extends ConsumerState<SettlementsScreen> {
  final _filterCtrl = TextEditingController();
  bool _syncing = false;

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  Future<void> _syncFull() async {
    setState(() => _syncing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final count = await ref
          .read(chainWatcherServiceProvider.notifier)
          .syncSettlements(full: true);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(count > 0 ? '全量同步:补回 $count 笔 Settled' : '已是最新'),
      ));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('同步失败:${friendlyError(e)}')));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(settlementListProvider);
    final chainStatus = ref.watch(chainWatcherStatusProvider);
    final canSync = chainStatus == ChainWatcherStatus.running && !_syncing;
    return Scaffold(
      appBar: AppBar(
        title: const Text('链上结算'),
        actions: [
          TextButton.icon(
            onPressed: canSync ? _syncFull : null,
            icon: _syncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync, size: 18),
            label: const Text('全量同步'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spaceLg,
              AppSpacing.spaceMd,
              AppSpacing.spaceLg,
              AppSpacing.spaceSm,
            ),
            child: TextField(
              controller: _filterCtrl,
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 18),
                hintText: '按 tx hash 筛选',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (chainStatus != ChainWatcherStatus.running)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceLg),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppColors.textMuted),
                  AppSpacing.spaceXs.wSpace,
                  const Expanded(
                    child: Text(
                      '链监听未运行,全量同步不可用(Settled 列表仍可查看)',
                      style: AppTextStyles.caption,
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

  Widget _body(AsyncValue<List<ProviderChainSettlementRow>> async) {
    return async.when(
      data: (all) {
        final q = _filterCtrl.text.trim().toLowerCase();
        final list = q.isEmpty
            ? all
            : all.where((r) => r.tx.toLowerCase().contains(q)).toList();
        if (list.isEmpty) {
          return Center(
            child: Text(q.isEmpty ? '尚无 Settled 事件' : '无匹配记录',
                style: AppTextStyles.bodySecondary),
          );
        }
        return ListView.separated(
          padding: AppSpacing.pagePaddingCompact,
          itemCount: list.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.spaceXs),
          itemBuilder: (_, i) => _SettlementTile(row: list[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败:$e')),
    );
  }
}

class _SettlementTile extends StatelessWidget {
  const _SettlementTile({required this.row});
  final ProviderChainSettlementRow row;

  @override
  Widget build(BuildContext context) {
    final usdt = _formatUsdt(row.receivedUsdt);
    final time = row.createdAt == 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.createdAt);
    return Card(
      child: ListTile(
        contentPadding: AppSpacing.listItemPadding,
        onTap: () => showRelayRecordsSheet(context, row.tx),
        title: Row(
          children: [
            Expanded(
              child: Text('+ $usdt USDT',
                  style: AppTextStyles.number(size: 15, color: AppColors.positive)),
            ),
            Text('${row.settledCount} 笔',
                style: AppTextStyles.bodySecondary),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSpacing.space3xs.hSpace,
            SelectableText(row.tx, style: AppTextStyles.caption),
            if (row.notSettledCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '未结算 ${row.notSettledCount} 笔 · ${_formatUsdt(row.notSettledAmount)} USDT',
                  style: AppTextStyles.caption.copyWith(color: AppColors.warn),
                ),
              ),
            if (time != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${time.toLocal()}'.split('.').first,
                  style: AppTextStyles.caption,
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
      ),
    );
  }
}

/// USDT 原始(raw,6 位)→ 人类单位(2 位小数)。raw 可能是整数 BigInt 字符串。
String _formatUsdt(String raw) {
  final n = int.tryParse(raw);
  if (n == null) return raw;
  return (n / 1e6).toStringAsFixed(2);
}
