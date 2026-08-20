import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/db/provider_models_dao.dart';
import 'package:flowing_water/core/db/quotation_dao.dart';
import 'package:flowing_water/core/db/vendor_dao.dart';
import 'package:flowing_water/core/providers.dart';
import 'package:flowing_water/core/relay/node_service.dart';
import 'package:flowing_water/shared/design/app_colors.dart';
import 'package:flowing_water/shared/design/app_spacing.dart';
import 'package:flowing_water/shared/design/app_text_styles.dart';

final quotationDaoProvider = Provider<QuotationDao>(
  (ref) => QuotationDao(ref.watch(appDatabaseProvider)),
);

final quotationListProvider = StreamProvider<List<ProviderQuotationRow>>(
  (ref) => ref.watch(quotationDaoProvider).watchAll(),
);

/// 从 relay 同步下来的模型目录(02 sync-model-params)。
/// 报价的 **relay 模型名必须从此表选**(relay 规范名),不能自造。
final providerModelsDaoProvider = Provider<ProviderModelsDao>(
  (ref) => ProviderModelsDao(ref.watch(appDatabaseProvider)),
);
final providerModelsListProvider = StreamProvider<List<ProviderModelRow>>(
  (ref) => ref.watch(providerModelsDaoProvider).watchAll(),
);

/// vendor 下拉选项(Models 页选 providerId 用;与 Providers 页同源表)。
final _vendorOptionsProvider = StreamProvider<List<ProviderLlmVendorRow>>(
  (ref) => VendorDao(ref.watch(appDatabaseProvider)).watchAll(),
);

/// 模型报价页(wayfinder 02):provider_quotation CRUD。
///
/// CRUD 后即时 [NodeService.reportProviderInfo] 重报给 relay(连接时有效),
/// 保证 relay 用最新报价计费。MVP = 报价 CRUD + 重报;
/// 「sync-model-params / 反拉报价覆盖」为进阶,后续补。
class ModelsScreen extends ConsumerWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(quotationListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('模型报价'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download_outlined),
            tooltip: '从中转站同步模型参数',
            onPressed: () async {
              final n = await ref.read(nodeServiceProvider.notifier).syncModels();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    n > 0 ? '已同步 $n 个 relay 模型' : '同步失败(未连中转站?)',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_outlined),
            tooltip: '新增模型',
            onPressed: () => _openForm(context, ref),
          ),
        ],
      ),
      body: async.when(
        data: (list) => list.isEmpty
            ? Center(
                child: Text('尚无模型报价,点右上角 + 添加',
                    style: AppTextStyles.bodySecondary),
              )
            : ListView.separated(
                padding: AppSpacing.pagePadding,
                itemCount: list.length,
                separatorBuilder: (_, _) => AppSpacing.spaceXs.hSpace,
                itemBuilder: (_, i) => _QuotationTile(row: list[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }
}

class _QuotationTile extends ConsumerWidget {
  const _QuotationTile({required this.row});
  final ProviderQuotationRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vs = ref.watch(_vendorOptionsProvider).valueOrNull ??
        const <ProviderLlmVendorRow>[];
    final vendorName =
        vs.where((v) => v.vendorId == row.providerId).firstOrNull?.vendorName;
    return Card(
      child: ListTile(
        contentPadding: AppSpacing.listItemPadding,
        title: Text(row.relayModelName, style: AppTextStyles.bodySecondary),
        subtitle: Text(
          '${row.providerModel ?? '—'}\n'
          '厂商: ${vendorName ?? '未绑定'} · 入 ${row.inputPricePer1k} / 出 ${row.outputPricePer1k} nUSD/1K',
          style: AppTextStyles.caption,
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: '编辑',
              onPressed: () => _openForm(context, ref, existing: row),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
              tooltip: '删除',
              onPressed: () async {
                final ok = await _confirm(context, '删除模型「${row.relayModelName}」?');
                if (ok) {
                  await ref.read(quotationDaoProvider).remove(row.relayModelName);
                  unawaited(
                      ref.read(nodeServiceProvider.notifier).reportProviderInfo());
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openForm(
  BuildContext context,
  WidgetRef ref, {
  ProviderQuotationRow? existing,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _QuotationFormDialog(
      existing: existing,
      vendors: ref.read(_vendorOptionsProvider).valueOrNull ?? const [],
      relayModels: ref.read(providerModelsListProvider).valueOrNull ?? const [],
      onSubmit: (fields) async {
        final dao = ref.read(quotationDaoProvider);
        if (existing == null) {
          await dao.create(
            relayModelName: fields.relayModelName,
            providerId: fields.providerId,
            providerModel: fields.providerModel,
            inputPricePer1k: fields.inputPricePer1k,
            outputPricePer1k: fields.outputPricePer1k,
          );
        } else {
          await dao.update(fields);
        }
        // CRUD 后即时重报 provider_info(连接时有效)。
        unawaited(ref.read(nodeServiceProvider.notifier).reportProviderInfo());
        if (context.mounted) Navigator.of(context).pop();
      },
    ),
  );
}

Future<bool> _confirm(BuildContext context, String message) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        ),
      ) ??
      false;
}

class _QuotationFormDialog extends StatefulWidget {
  const _QuotationFormDialog({
    this.existing,
    required this.vendors,
    required this.relayModels,
    required this.onSubmit,
  });
  final ProviderQuotationRow? existing;
  final List<ProviderLlmVendorRow> vendors;
  /// 从 relay 同步下来的规范目录;报价的 relayModelName **从此选**(不自造)。
  final List<ProviderModelRow> relayModels;
  final Future<void> Function(QuotationEdit) onSubmit;

  @override
  State<_QuotationFormDialog> createState() => _QuotationFormDialogState();
}

class _QuotationFormDialogState extends State<_QuotationFormDialog> {
  late final TextEditingController _providerModel;
  late final TextEditingController _input;
  late final TextEditingController _output;
  String? _relayModelName; // 从同步目录选的 relay 规范名(下拉)
  late int? _vendorId;
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _relayModelName = e?.relayModelName;
    _providerModel = TextEditingController(text: e?.providerModel ?? '');
    _input = TextEditingController(text: '${e?.inputPricePer1k ?? 0}');
    _output = TextEditingController(text: '${e?.outputPricePer1k ?? 0}');
    _vendorId = e?.providerId;
  }

  @override
  void dispose() {
    _providerModel.dispose();
    _input.dispose();
    _output.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? '编辑模型' : '新增模型'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                initialValue: _relayModelName,
                decoration: const InputDecoration(
                    labelText: 'Relay 模型名(从同步目录选)'),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('— 选模型 —')),
                  ...widget.relayModels.map(
                    (m) => DropdownMenuItem<String?>(
                        value: m.modelName, child: Text(m.modelName)),
                  ),
                ],
                onChanged: !isEdit // PK 编辑时禁改
                    ? (v) => setState(() => _relayModelName = v)
                    : null,
                validator: (v) =>
                    (v == null || v.isEmpty) ? '必选(先点页头 ☁ 同步)' : null,
              ),
              TextFormField(
                controller: _providerModel,
                decoration: const InputDecoration(
                    labelText: '厂商模型名(留空则同 Relay 名)'),
              ),
              DropdownButtonFormField<int?>(
                initialValue: _vendorId,
                decoration: const InputDecoration(labelText: '厂商'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('未绑定'),
                  ),
                  ...widget.vendors.map(
                    (v) => DropdownMenuItem<int?>(
                      value: v.vendorId,
                      child: Text(v.vendorName),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _vendorId = v),
              ),
              TextFormField(
                controller: _input,
                decoration:
                    const InputDecoration(labelText: '输入价 (nUSD/1K tokens)'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || int.tryParse(v) == null) ? '需为整数' : null,
              ),
              TextFormField(
                controller: _output,
                decoration:
                    const InputDecoration(labelText: '输出价 (nUSD/1K tokens)'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || int.tryParse(v) == null) ? '需为整数' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _saving = true);
                  await widget.onSubmit(QuotationEdit(
                    relayModelName: _relayModelName ?? '',
                    providerId: _vendorId,
                    providerModel: _providerModel.text.trim().isEmpty
                        ? null
                        : _providerModel.text.trim(),
                    inputPricePer1k: int.parse(_input.text),
                    outputPricePer1k: int.parse(_output.text),
                  ));
                },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
