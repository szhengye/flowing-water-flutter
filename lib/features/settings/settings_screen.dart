import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flowing_water/core/chain/unmatched_retry_service.dart';
import 'package:flowing_water/core/config/app_config.dart';
import 'package:flowing_water/core/crypto/identity_controller.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/errors/friendly_error.dart';
import 'package:flowing_water/core/providers.dart';
import 'package:flowing_water/core/relay/node_service.dart';
import 'package:flowing_water/shared/design/app_colors.dart';
import 'package:flowing_water/shared/design/app_spacing.dart';
import 'package:flowing_water/shared/design/app_text_styles.dart';

/// 系统设置页(wayfinder 01 / Slice D):供应商身份 + 中转站连接的**只读可观测面板**。
///
/// 01 阶段展示:Owner/Payment 地址、relay WS URL、实时 WS 状态、当前网络。
/// 「运行时网络切换 + 可编辑 RPC」需要可变 AppConfig(且 mainnet/testnet 的 relay URL
/// 要从合约 `wsUrl()` 取),作为后续 —— 此处不提供会误导用户切到无 URL 网络的开关。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityControllerProvider).valueOrNull;
    final address = identity?.addressEip55;
    final status = ref.watch(nodeStatusProvider);
    final cfg = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('系统设置')),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          const _SectionTitle('身份'),
          _ReadOnlyField(label: 'Owner 地址', value: address ?? '—'),
          _ReadOnlyField(
            label: 'Payment 地址',
            value: address ?? '—',
            hint: '默认同 Owner(后续可独立配置)',
          ),
          AppSpacing.spaceLg.hSpace,
          const _SectionTitle('中转站连接'),
          _WsStatusField(status: status),
          _ReadOnlyField(label: 'Relay WS URL', value: cfg.relayWsUrl),
          AppSpacing.spaceLg.hSpace,
          const _SectionTitle('网络'),
          _ReadOnlyField(
            label: '当前网络',
            value: _networkLabel(cfg.network),
            hint: 'mainnet/testnet 的 relay URL 待合约配置;运行时切换为后续',
          ),
          AppSpacing.spaceLg.hSpace,
          const _UnmatchedEventsSection(),
        ],
      ),
    );
  }

  String _networkLabel(AppNetwork n) => switch (n) {
        AppNetwork.dev => 'dev(本地中转站)',
        AppNetwork.mainnet => 'mainnet',
        AppNetwork.testnet => 'testnet',
      };
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.spaceSm,
          bottom: AppSpacing.spaceXs,
        ),
        child: Text(text, style: AppTextStyles.h2),
      );
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value, this.hint});
  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.bodySecondary),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(hint!, style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 18),
            tooltip: '复制',
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: value)),
          ),
        ],
      ),
    );
  }
}

class _WsStatusField extends StatelessWidget {
  const _WsStatusField({required this.status});
  final NodeStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _visual(status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spaceXs),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          AppSpacing.spaceXs.wSpace,
          Text(label, style: AppTextStyles.bodySecondary),
        ],
      ),
    );
  }

  (String, Color) _visual(NodeStatus s) => switch (s) {
        NodeStatus.connected => ('已连接', AppColors.positive),
        NodeStatus.connecting => ('连接中…', AppColors.warn),
        NodeStatus.authenticating => ('鉴权中…', AppColors.warn),
        NodeStatus.reconnecting => ('重连中…', AppColors.warn),
        NodeStatus.failed => ('鉴权失败', AppColors.danger),
        NodeStatus.stopped => ('未连接', AppColors.textMuted),
      };
}

/// 未匹配 Settled 事件流(09 Settings 区:drift watch → 重试后自动刷新)。
final unmatchedEventsProvider =
    StreamProvider<List<UnmatchedSettledEventRow>>(
  (ref) => ref.watch(unmatchedSettledEventDaoProvider).watchAll(),
);

/// operator 未匹配事件手动重试区(09,对齐上游 `/unmatched-settled-events/retry-all`)。
///
/// 列 06 对账未命中(0 匹配/失败耗尽/relay 未连)的 Settled;一键「重试全部」复用
/// `SettleEventSyncer.sync`:命中则从未匹配表移除,仍 0 匹配则累加重试计数。按钮
/// 门禁中转站已连(未连时禁用,label 提示「需连接」)。
class _UnmatchedEventsSection extends ConsumerStatefulWidget {
  const _UnmatchedEventsSection();

  @override
  ConsumerState<_UnmatchedEventsSection> createState() =>
      _UnmatchedEventsSectionState();
}

class _UnmatchedEventsSectionState
    extends ConsumerState<_UnmatchedEventsSection> {
  bool _retrying = false;

  Future<void> _retryAll() async {
    setState(() => _retrying = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final summary = await ref.read(unmatchedRetryServiceProvider).retryAll();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_summaryText(summary))));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('重试失败:${friendlyError(e)}')));
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  String _summaryText(RetrySummary s) {
    if (s.notConnected) return '中转站未连接,已跳过(请先连接 relay)';
    if (s.retried == 0) return '暂无可重试的未匹配事件';
    return '重试 ${s.retried} 笔:匹配 ${s.matched} 笔,'
        '仍未匹配 ${s.stillUnmatched} 笔';
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(unmatchedEventsProvider).valueOrNull ?? const [];
    final connected = ref.watch(nodeStatusProvider) == NodeStatus.connected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionTitle('未匹配结算事件'),
            if (events.isNotEmpty) ...[
              AppSpacing.spaceXs.wSpace,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spaceXs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppColors.radiusSm),
                ),
                child: Text(
                  '${events.length}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.accent),
                ),
              ),
            ],
          ],
        ),
        Text(
          '06 对账未命中的 Settled;一键重试(命中则移除,仍空则累加重试次数)',
          style: AppTextStyles.caption,
        ),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.spaceXs),
            child: Text('暂无未匹配事件', style: AppTextStyles.bodySecondary),
          )
        else
          for (final e in events) _UnmatchedEventTile(event: e),
        AppSpacing.spaceSm.hSpace,
        FilledButton.icon(
          onPressed: (connected && !_retrying) ? _retryAll : null,
          icon: _retrying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh, size: 18),
          label: Text(
            _retrying
                ? '重试中…'
                : connected
                    ? '重试全部'
                    : '重试全部(需连接)',
          ),
        ),
      ],
    );
  }
}

class _UnmatchedEventTile extends StatelessWidget {
  const _UnmatchedEventTile({required this.event});
  final UnmatchedSettledEventRow event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_shortTx(event.tx)}  #${event.logIndex}',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: 2),
                Text(
                  '重试 ${event.retryCount} 次'
                  ' · ${_formatUsdt(event.receivedUsdt)} USDT',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 0x 开头 hash 截断为 `0xABCD..1234`。
String _shortTx(String tx) {
  if (tx.length <= 12) return tx;
  return '${tx.substring(0, 6)}..${tx.substring(tx.length - 4)}';
}

/// USDT 原始(raw,6 位)→ 人类单位(2 位小数)。对齐 settlements_screen._formatUsdt。
String _formatUsdt(String raw) {
  final n = int.tryParse(raw);
  if (n == null) return raw;
  return (n / 1e6).toStringAsFixed(2);
}
