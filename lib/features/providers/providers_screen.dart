import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/db/vendor_dao.dart';
import 'package:flowing_water/core/providers.dart';
import 'package:flowing_water/features/providers/vendor_probe.dart';
import 'package:flowing_water/shared/design/app_colors.dart';
import 'package:flowing_water/shared/design/app_spacing.dart';
import 'package:flowing_water/shared/design/app_text_styles.dart';

/// vendor DAO provider(注入 appDatabase)。
final vendorDaoProvider = Provider<VendorDao>(
  (ref) => VendorDao(ref.watch(appDatabaseProvider)),
);

/// 厂商列表(实时 watch 表,CRUD 后自动刷新)。
final vendorListProvider = StreamProvider<List<ProviderLlmVendorRow>>(
  (ref) => ref.watch(vendorDaoProvider).watchAll(),
);

const _adapterTypes = [
  'openai',
  'deepseek',
  'azure_openai',
  'anthropic',
  'gemini',
];

/// LLM 厂商页(wayfinder 02):provider_llm_vendor 的 CRUD 管理。
///
/// MVP = vendor CRUD;「连通性测试 / endpoint 自动探测」为进阶,后续补。
class ProvidersScreen extends ConsumerWidget {
  const ProvidersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vendorListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM 厂商'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_outlined),
            tooltip: '新增厂商',
            onPressed: () => _openVendorForm(context, ref),
          ),
        ],
      ),
      body: async.when(
        data: (list) => list.isEmpty
            ? Center(
                child: Text('尚无厂商,点右上角 + 添加',
                    style: AppTextStyles.bodySecondary),
              )
            : ListView.separated(
                padding: AppSpacing.pagePadding,
                itemCount: list.length,
                separatorBuilder: (_, _) => AppSpacing.spaceXs.hSpace,
                itemBuilder: (_, i) => _VendorTile(vendor: list[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }
}

class _VendorTile extends ConsumerStatefulWidget {
  const _VendorTile({required this.vendor});
  final ProviderLlmVendorRow vendor;

  @override
  ConsumerState<_VendorTile> createState() => _VendorTileState();
}

class _VendorTileState extends ConsumerState<_VendorTile> {
  bool _probing = false;
  ProbeResult? _probe;

  Future<void> _test() async {
    final model = firstVendorModel(widget.vendor.vendorModels);
    if (model == null) {
      setState(() => _probe = const ProbeResult(ok: false, message: '厂商未配模型,无法测试'));
      return;
    }
    setState(() {
      _probing = true;
      _probe = null;
    });
    final r = await probeVendor(vendor: widget.vendor, providerModel: model);
    if (mounted) {
      setState(() {
        _probing = false;
        _probe = r;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
    return Card(
      child: ListTile(
        contentPadding: AppSpacing.listItemPadding,
        title: Text(v.vendorName, style: AppTextStyles.bodySecondary),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${v.endpoint}\n${v.adapterType} · 流式 ${v.supportsStream ? '开' : '关'}'
              '${v.isActive ? '' : ' · 停用'}',
              style: AppTextStyles.caption,
            ),
            if (_probe != null) ...[
              const SizedBox(height: 4),
              Text(
                _probe!.message,
                style: AppTextStyles.caption
                    .copyWith(color: _probe!.ok ? AppColors.positive : AppColors.danger),
              ),
            ],
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: _probing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.network_check, size: 20),
              tooltip: '连通性测试',
              onPressed: _probing ? null : _test,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: '编辑',
              onPressed: () =>
                  _openVendorForm(context, ref, existing: v),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
              tooltip: '删除',
              onPressed: () async {
                final ok = await _confirm(context, '删除厂商「${v.vendorName}」?');
                if (ok) {
                  await ref.read(vendorDaoProvider).remove(v.vendorId);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 打开新增/编辑表单(existing 为 null 即新增)。提交后写库并关 Dialog。
Future<void> _openVendorForm(
  BuildContext context,
  WidgetRef ref, {
  ProviderLlmVendorRow? existing,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _VendorFormDialog(
      existing: existing,
      onSubmit: (fields) async {
        final dao = ref.read(vendorDaoProvider);
        if (fields.vendorId == null) {
          await dao.create(
            vendorName: fields.vendorName,
            endpoint: fields.endpoint,
            apiKey: fields.apiKey,
            adapterType: fields.adapterType,
            supportsStream: fields.supportsStream,
          );
        } else {
          await dao.update(fields);
        }
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

class _VendorFormDialog extends StatefulWidget {
  const _VendorFormDialog({this.existing, required this.onSubmit});
  final ProviderLlmVendorRow? existing;
  final Future<void> Function(VendorEdit) onSubmit;

  @override
  State<_VendorFormDialog> createState() => _VendorFormDialogState();
}

class _VendorFormDialogState extends State<_VendorFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _endpoint;
  late final TextEditingController _apiKey;
  late String _adapterType;
  late bool _supportsStream;
  late bool _isActive;
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.vendorName ?? '');
    _endpoint = TextEditingController(text: e?.endpoint ?? '');
    _apiKey = TextEditingController(text: e?.apiKey ?? '');
    _adapterType = e?.adapterType ?? 'openai';
    _supportsStream = e?.supportsStream ?? true;
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _endpoint.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? '编辑厂商' : '新增厂商'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: '厂商名称'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '必填' : null,
              ),
              TextFormField(
                controller: _endpoint,
                decoration: const InputDecoration(labelText: 'Endpoint'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '必填' : null,
              ),
              TextFormField(
                controller: _apiKey,
                decoration: const InputDecoration(labelText: 'API Key'),
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? '必填' : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _adapterType,
                decoration: const InputDecoration(labelText: 'Adapter 类型'),
                items: [
                  for (final t in _adapterTypes) DropdownMenuItem(value: t, child: Text(t))
                ],
                onChanged: (v) => setState(() => _adapterType = v ?? 'openai'),
              ),
              CheckboxListTile(
                value: _supportsStream,
                title: const Text('支持流式'),
                onChanged: (v) => setState(() => _supportsStream = v ?? true),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (isEdit)
                CheckboxListTile(
                  value: _isActive,
                  title: const Text('启用'),
                  onChanged: (v) => setState(() => _isActive = v ?? true),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
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
                  await widget.onSubmit(VendorEdit(
                    vendorId: widget.existing?.vendorId,
                    vendorName: _name.text.trim(),
                    endpoint: _endpoint.text.trim(),
                    apiKey: _apiKey.text,
                    adapterType: _adapterType,
                    supportsStream: _supportsStream,
                    isActive: _isActive,
                  ));
                },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
