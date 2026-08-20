import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web3dart/web3dart.dart';

import 'package:flowing_water/core/chain/chain_watcher_service.dart';
import 'package:flowing_water/core/chain/polygonscan_client.dart';
import 'package:flowing_water/core/config/app_config.dart';
import 'package:flowing_water/core/crypto/identity_controller.dart';
import 'package:flowing_water/core/providers.dart';
import 'package:flowing_water/shared/design/app_colors.dart';
import 'package:flowing_water/shared/design/app_spacing.dart';
import 'package:flowing_water/shared/design/app_text_styles.dart';
import 'package:flowing_water/shared/widgets/relay_records_sheet.dart';

/// Polygonscan 客户端单例(测试可 override)。
final polygonscanClientProvider = Provider<PolygonscanClient>(
  (ref) => PolygonscanClient(),
);

/// MATIC + USDT 余额(对齐上游 `/wallet/balances`)。
class WalletBalances {
  const WalletBalances({
    required this.address,
    required this.maticWei,
    required this.usdtRaw,
  });
  // 非 const:BigInt.zero 非编译期常量。
  WalletBalances.unavailable()
      : address = null,
        maticWei = BigInt.zero,
        usdtRaw = BigInt.zero;

  final String? address;
  final BigInt maticWei;
  final BigInt usdtRaw;
  bool get available => address != null;
}

/// 钱包余额 —— 读身份 + 配置,未就绪(身份未解锁 / RPC 未配)→ unavailable。
/// identity / AppConfig 变化时自动重算(解锁身份后即拉取)。
final walletBalancesProvider = FutureProvider<WalletBalances>((ref) async {
  final identity = ref.watch(identityControllerProvider).valueOrNull;
  final cfg = ref.watch(appConfigProvider);
  final address = identity?.addressEip55;
  if (address == null || address.isEmpty || cfg.polygonRpcUrl.isEmpty) {
    return WalletBalances.unavailable();
  }
  final buildClient = ref.read(chainClientFactoryProvider);
  final client = buildClient(cfg);
  ref.onDispose(client.dispose);
  final matic = await client.getBalance(EthereumAddress.fromHex(address));
  final usdt = cfg.polygonUsdtAddress.isEmpty
      ? BigInt.zero
      : await client.getTokenBalance(
          token: EthereumAddress.fromHex(cfg.polygonUsdtAddress),
          owner: EthereumAddress.fromHex(address),
        );
  return WalletBalances(address: address, maticWei: matic.getInWei, usdtRaw: usdt);
});

/// MATIC(原生)交易历史(action=txlist)。未就绪 → 空列表(UI 另显提示)。
final walletMaticTxProvider = FutureProvider<List<WalletTx>>((ref) async {
  final (address, cfg) = _resolve(ref);
  if (address == null) return const [];
  return ref.read(polygonscanClientProvider).fetchMaticTx(
        address: address,
        apiKey: cfg.polygonscanApiKey,
      );
});

/// USDT(ERC-20)交易历史(action=tokentx)。需 USDT 合约地址;未就绪 → 空列表。
final walletUsdtTxProvider = FutureProvider<List<WalletTx>>((ref) async {
  final (address, cfg) = _resolve(ref);
  if (address == null || cfg.polygonUsdtAddress.isEmpty) return const [];
  return ref.read(polygonscanClientProvider).fetchUsdtTx(
        address: address,
        token: cfg.polygonUsdtAddress,
        apiKey: cfg.polygonscanApiKey,
      );
});

(String?, AppConfig) _resolve(Ref ref) {
  final identity = ref.watch(identityControllerProvider).valueOrNull;
  final cfg = ref.watch(appConfigProvider);
  return (identity?.addressEip55, cfg);
}

/// 链上钱包页(07):余额 + 交易历史 + USDT 交易钻取关联流水。
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(identityControllerProvider);
    final cfg = ref.watch(appConfigProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('链上钱包'),
          actions: [
            IconButton(
              tooltip: '刷新',
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () {
                ref.invalidate(walletBalancesProvider);
                ref.invalidate(walletMaticTxProvider);
                ref.invalidate(walletUsdtTxProvider);
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'MATIC'), Tab(text: 'USDT')],
          ),
        ),
        body: identityAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('身份加载失败:$e')),
          data: (identity) {
            if (identity.addressEip55 == null) {
              return const Center(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Text('需先生成 / 解锁供应商身份后查看钱包',
                      style: AppTextStyles.bodySecondary),
                ),
              );
            }
            return Column(
              children: [
                _BalancesCard(),
                Expanded(
                  child: TabBarView(
                    children: [
                      _TxList(
                        provider: walletMaticTxProvider,
                        ready: cfg.polygonscanApiKey.isNotEmpty,
                        missingHint: 'Polygonscan API key 未配置(POLYGONSCAN_API_KEY)',
                        onTap: null,
                      ),
                      _TxList(
                        provider: walletUsdtTxProvider,
                        ready: cfg.polygonscanApiKey.isNotEmpty &&
                            cfg.polygonUsdtAddress.isNotEmpty,
                        missingHint: cfg.polygonUsdtAddress.isEmpty
                            ? 'USDT 合约地址未配置(POLYGON_USDT_ADDRESS)'
                            : 'Polygonscan API key 未配置(POLYGONSCAN_API_KEY)',
                        onTap: (tx) => showRelayRecordsSheet(context, tx.txHash),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BalancesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(walletBalancesProvider);
    return Card(
      margin: const EdgeInsets.all(AppSpacing.spaceLg),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: async.when(
          loading: () => const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('余额读取失败:$e',
              style: AppTextStyles.bodySecondary),
          data: (b) {
            if (!b.available) {
              return Row(
                children: [
                  const Icon(Icons.lock_outline,
                      size: 16, color: AppColors.textMuted),
                  AppSpacing.spaceXs.wSpace,
                  const Expanded(
                    child: Text('需解锁身份并配置 Polygon RPC 后读取余额',
                        style: AppTextStyles.bodySecondary),
                  ),
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(b.address!, style: AppTextStyles.caption),
                AppSpacing.spaceSm.hSpace,
                Row(
                  children: [
                    Expanded(
                      child: _BalanceItem(
                        label: 'MATIC',
                        value: _formatMatic(b.maticWei),
                      ),
                    ),
                    Expanded(
                      child: _BalanceItem(
                        label: 'USDT',
                        value: _formatUsdt(b.usdtRaw),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  const _BalanceItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        AppSpacing.space3xs.hSpace,
        Text(value, style: AppTextStyles.number(size: 20)),
      ],
    );
  }
}

class _TxList extends ConsumerWidget {
  const _TxList({
    required this.provider,
    required this.ready,
    required this.missingHint,
    required this.onTap,
  });

  final ProviderBase<AsyncValue<List<WalletTx>>> provider;
  final bool ready;
  final String missingHint;
  final void Function(WalletTx)? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ready) {
      return Center(
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Text(missingHint, style: AppTextStyles.bodySecondary),
        ),
      );
    }
    final async = ref.watch(provider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('交易历史加载失败:$e')),
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Text('无交易记录', style: AppTextStyles.bodySecondary),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceLg),
          itemCount: list.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: AppColors.borderSubtle),
          itemBuilder: (_, i) => _WalletTxTile(tx: list[i], onTap: onTap),
        );
      },
    );
  }
}

class _WalletTxTile extends StatelessWidget {
  const _WalletTxTile({required this.tx, required this.onTap});
  final WalletTx tx;
  final void Function(WalletTx)? onTap;

  @override
  Widget build(BuildContext context) {
    final isOut = tx.direction == WalletTxDirection.outgoing;
    final amountStr =
        '${isOut ? "−" : "+"}${tx.amount.abs().toStringAsFixed(tx.decimals == 6 ? 2 : 6)}';
    final time = tx.blockTimestamp == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(tx.blockTimestamp! * 1000);
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(tx),
      child: Padding(
        padding: AppSpacing.listItemPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(tx.txHash, style: AppTextStyles.bodySecondary),
                  AppSpacing.space3xs.hSpace,
                  Text(
                    '${isOut ? "支出" : "收入"} · ${tx.counterparty ?? "—"}'
                    '${tx.status ? "" : " · 失败"}',
                    style: AppTextStyles.caption,
                  ),
                  if (time != null)
                    Text('${time.toLocal()}'.split('.').first,
                        style: AppTextStyles.caption),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amountStr,
                    style: AppTextStyles.number(
                      size: 14,
                      color: isOut ? AppColors.textPrimary : AppColors.positive,
                    )),
                if (tx.decimals == 18)
                  Text('fee ${tx.feeMatic} MATIC', style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMatic(BigInt wei) => (wei.toDouble() / 1e18).toStringAsFixed(4);
String _formatUsdt(BigInt raw) => (raw.toDouble() / 1e6).toStringAsFixed(2);
