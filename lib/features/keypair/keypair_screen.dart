import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flowing_water/core/crypto/aes_gcm.dart';
import 'package:flowing_water/core/crypto/identity_controller.dart';
import 'package:flowing_water/core/crypto/keypair.dart';
import 'package:flowing_water/core/errors/friendly_error.dart';
import 'package:flowing_water/shared/design/app_colors.dart';
import 'package:flowing_water/shared/design/app_spacing.dart';
import 'package:flowing_water/shared/design/app_text_styles.dart';

/// Keypair 页三 tab(wayfinder 07):生成 12 词 / 恢复 / 解锁。
///
/// [setup]=true 时作为「首次强制门禁」的 home 展示(无返回键,必须生成或恢复才能进后台)。
/// unlocked 状态下(后台 /keypair)顶部显示当前身份地址 + 锁定按钮。
enum KeypairTab { generate, recover, unlock }

class KeypairScreen extends ConsumerWidget {
  const KeypairScreen({
    super.key,
    this.setup = false,
    this.initialTab = KeypairTab.generate,
  });

  final bool setup;
  final KeypairTab initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityControllerProvider).valueOrNull;
    final unlocked = identity?.isUnlocked ?? false;

    return DefaultTabController(
      length: 3,
      initialIndex: initialTab.index,
      child: Scaffold(
        appBar: AppBar(
          title: Text(setup ? '设置供应商身份' : '私钥管理'),
          automaticallyImplyLeading: !setup,
          bottom: const TabBar(
            tabs: [
              Tab(text: '生成'),
              Tab(text: '恢复'),
              Tab(text: '解锁'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (unlocked && identity!.addressEip55 != null)
              _IdentityHeader(
                address: identity.addressEip55!,
                onLock: () => ref
                    .read(identityControllerProvider.notifier)
                    .lock(),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _GenerateTab(existing: unlocked),
                  _RecoverTab(existing: unlocked),
                  const _UnlockTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 顶部身份摘要:当前收款/鉴权地址 + 锁定按钮(仅 unlocked)。
class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({required this.address, required this.onLock});
  final String address;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spaceLg, vertical: AppSpacing.spaceMd),
      color: AppColors.accentSoft,
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined,
              size: 18, color: AppColors.accent),
          AppSpacing.spaceSm.wSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('当前身份已解锁', style: AppTextStyles.label),
                Text(address,
                    style: AppTextStyles.number(size: 13),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          OutlinedButton(onPressed: onLock, child: const Text('锁定')),
        ],
      ),
    );
  }
}

// ───────────────────────── 生成 ─────────────────────────

class _GenerateTab extends ConsumerStatefulWidget {
  const _GenerateTab({required this.existing});
  final bool existing;

  @override
  ConsumerState<_GenerateTab> createState() => _GenerateTabState();
}

class _GenerateTabState extends ConsumerState<_GenerateTab> {
  String? _mnemonic;
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _backupConfirmed = false;
  bool _autoRecover = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final pw = _password.text;
    if (pw.length < 8) {
      setState(() => _error = '密码至少 8 位');
      return;
    }
    if (pw != _confirm.text) {
      setState(() => _error = '两次密码不一致');
      return;
    }
    if (widget.existing &&
        !(await _confirmOverwrite(context))) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(identityControllerProvider.notifier)
          .generate(password: pw, autoRecover: _autoRecover);
      // 成功 → 身份变 unlocked → 门禁自动切到后台(本页 unmount),无需手动导航
    } catch (e) {
      setState(() {
        _busy = false;
        _error = '创建失败:${friendlyError(e)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('生成 12 词 BIP-39 助记词', style: AppTextStyles.h2),
          AppSpacing.spaceXs.hSpace,
          const Text(
            '助记词是供应商身份的唯一根。生成后**只显示一次**,务必离线抄写备份;'
            '任何掌握助记词的人都能冒用本供应商身份。',
            style: AppTextStyles.bodySecondary,
          ),
          AppSpacing.spaceLg.hSpace,
          if (_mnemonic == null)
            FilledButton.icon(
              onPressed: () => setState(() => _mnemonic = generateMnemonic()),
              icon: const Icon(Icons.casino_outlined),
              label: const Text('生成助记词'),
            )
          else ...[
            _MnemonicGrid(mnemonic: _mnemonic!),
            AppSpacing.spaceXs.hSpace,
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _mnemonic!));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('助记词已复制(请尽快离线保存)')));
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('复制全部'),
              ),
            ),
            AppSpacing.spaceMd.hSpace,
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _backupConfirmed,
              onChanged: (v) => setState(() => _backupConfirmed = v ?? false),
              title: const Text('我已安全备份助记词', style: AppTextStyles.body),
            ),
            AppSpacing.spaceMd.hSpace,
            _PasswordField(label: '设置解锁密码', controller: _password),
            AppSpacing.spaceSm.hSpace,
            _PasswordField(label: '确认解锁密码', controller: _confirm),
            AppSpacing.spaceSm.hSpace,
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _autoRecover,
              onChanged: (v) => setState(() => _autoRecover = v),
              title: const Text('自动恢复(解锁凭证存 macOS Keychain,桌面默认开)',
                  style: AppTextStyles.body),
            ),
            if (_error != null) ...[
              AppSpacing.spaceXs.hSpace,
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
            AppSpacing.spaceLg.hSpace,
            FilledButton(
              onPressed:
                  (_backupConfirmed && !_busy) ? _create : null,
              child: _busy
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.textOnAccent))
                  : const Text('创建身份'),
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────── 恢复 ─────────────────────────

class _RecoverTab extends ConsumerStatefulWidget {
  const _RecoverTab({this.existing = false});
  final bool existing;

  @override
  ConsumerState<_RecoverTab> createState() => _RecoverTabState();
}

class _RecoverTabState extends ConsumerState<_RecoverTab> {
  final _mnemonic = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _autoRecover = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _mnemonic.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _recover() async {
    final pw = _password.text;
    if (pw.length < 8) {
      setState(() => _error = '密码至少 8 位');
      return;
    }
    if (pw != _confirm.text) {
      setState(() => _error = '两次密码不一致');
      return;
    }
    if (widget.existing && !(await _confirmOverwrite(context))) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(identityControllerProvider.notifier).recover(
            mnemonic: _mnemonic.text.trim(),
            password: pw,
            autoRecover: _autoRecover,
          );
    } on ArgumentError {
      setState(() {
        _busy = false;
        _error = '助记词无效:词表或 checksum 校验未通过';
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = '恢复失败:${friendlyError(e)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('用既有助记词恢复身份', style: AppTextStyles.h2),
          AppSpacing.spaceXs.hSpace,
          const Text(
            '老供应商链上地址不可变 —— 用**同一助记词**在此重新导入,'
            '即可接管原身份(本地以新密码重新加密)。',
            style: AppTextStyles.bodySecondary,
          ),
          AppSpacing.spaceLg.hSpace,
          TextField(
            controller: _mnemonic,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '助记词(12 词,空格分隔)',
              border: OutlineInputBorder(),
            ),
          ),
          AppSpacing.spaceSm.hSpace,
          _PasswordField(label: '设置解锁密码', controller: _password),
          AppSpacing.spaceSm.hSpace,
          _PasswordField(label: '确认解锁密码', controller: _confirm),
          AppSpacing.spaceSm.hSpace,
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: _autoRecover,
            onChanged: (v) => setState(() => _autoRecover = v),
            title: const Text('自动恢复(存 Keychain,桌面默认开)', style: AppTextStyles.body),
          ),
          if (_error != null) ...[
            AppSpacing.spaceXs.hSpace,
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          AppSpacing.spaceLg.hSpace,
          FilledButton(
            onPressed: !_busy ? _recover : null,
            child: _busy
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.textOnAccent))
                : const Text('恢复身份'),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 解锁 ─────────────────────────

class _UnlockTab extends ConsumerStatefulWidget {
  const _UnlockTab();

  @override
  ConsumerState<_UnlockTab> createState() => _UnlockTabState();
}

class _UnlockTabState extends ConsumerState<_UnlockTab> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(identityControllerProvider.notifier)
          .unlock(password: _password.text);
      // 成功 → unlocked → 门禁自动切到后台
    } on DecryptionException {
      setState(() {
        _busy = false;
        _error = '密码错误,或密文已损坏';
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = '解锁失败:${friendlyError(e)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('解锁身份', style: AppTextStyles.h2),
          AppSpacing.spaceXs.hSpace,
          const Text('输入解锁密码,将加密助记词解密载入内存以作为节点工作。',
              style: AppTextStyles.bodySecondary),
          AppSpacing.spaceLg.hSpace,
          _PasswordField(label: '解锁密码', controller: _password),
          if (_error != null) ...[
            AppSpacing.spaceXs.hSpace,
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          AppSpacing.spaceLg.hSpace,
          FilledButton(
            onPressed: !_busy ? _unlock : null,
            child: _busy
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.textOnAccent))
                : const Text('解锁'),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 共用 ─────────────────────────

class _PasswordField extends StatefulWidget {
  const _PasswordField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

class _MnemonicGrid extends StatelessWidget {
  const _MnemonicGrid({required this.mnemonic});
  final String mnemonic;

  @override
  Widget build(BuildContext context) {
    final words = mnemonic.split(' ');
    return Wrap(
      spacing: AppSpacing.spaceXs,
      runSpacing: AppSpacing.spaceXs,
      children: [
        for (var i = 0; i < words.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spaceSm, vertical: AppSpacing.space2xs),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text('${i + 1}. ${words[i]}', style: AppTextStyles.number(size: 13)),
          ),
      ],
    );
  }
}

Future<bool> _confirmOverwrite(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('覆盖现有身份?'),
      content: const Text('已存在供应商身份。继续将生成/导入新身份并覆盖旧的。'
          '若覆盖,旧链上地址将不再可用(除非用其原助记词重新恢复)。'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('覆盖')),
      ],
    ),
  );
  return ok ?? false;
}
