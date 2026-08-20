import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flowing_water/core/crypto/aes_gcm.dart';
import 'package:flowing_water/core/crypto/identity_store.dart';
import 'package:flowing_water/core/crypto/keypair.dart';
import 'package:flowing_water/core/providers.dart';

/// 身份状态机的离散状态(wayfinder 05:连接/身份态用 enum + errors-as-state)。
///
/// - [none] —— 尚无供应商身份(首次运行)→ 触发「首次强制 modal」引导生成/恢复。
/// - [locked] —— 身份已落盘,但私钥不在内存 → 需解锁(或自动恢复)才能作为节点工作。
/// - [unlocked] —— 私钥在内存,可作为节点鉴权与签名。
///
/// `bootstrapping`(冷启动判定中)由外层 `AsyncValue.loading` 表达。
enum IdentityStatus { none, locked, unlocked }

/// 不可变身份快照。
class IdentityState {
  const IdentityState({
    required this.status,
    this.addressEip55,
    this.keypair,
  });

  final IdentityStatus status;

  /// 供应商地址(locked 时来自落盘记录,unlocked 时来自内存派生)。
  final String? addressEip55;

  /// 解锁后驻留内存的私钥(unlocked 时非空)。助记词**永不**在此持有。
  final ProviderKeypair? keypair;

  bool get isUnlocked => status == IdentityStatus.unlocked;
}

/// 供应商身份生命周期:冷启动 bootstrap → 生成/恢复/解锁/锁定。
///
/// 助记词仅在 generate/recover/unlock 的局部作用域内短暂存在(用于派生 + 加密),
/// 之后立即丢弃;长期驻留内存的只有 [ProviderKeypair](私钥 + 地址)。
class IdentityController extends AsyncNotifier<IdentityState> {
  @override
  Future<IdentityState> build() async {
    final store = IdentityStore(
      ref.read(appDatabaseProvider),
      ref.read(secureVaultProvider),
    );
    return _bootstrap(store);
  }

  IdentityStore get _store => IdentityStore(
        ref.read(appDatabaseProvider),
        ref.read(secureVaultProvider),
      );

  Future<IdentityState> _bootstrap(IdentityStore store) async {
    if (!await store.hasIdentity()) {
      return const IdentityState(status: IdentityStatus.none);
    }
    final address = await store.readAddress();

    // 自动恢复:Keychain 存了解锁凭证则直接解密载入(桌面默认开启,07)。
    String? pw;
    try {
      pw = await store.readUnlockPassword();
    } catch (_) {
      // keychain 失败 → 降级:无自动恢复凭证 → locked,等用户手输(不阻塞身份)。
    }
    if (pw != null) {
      try {
        final cipher = await store.readEncryptedMnemonic();
        final keypair = deriveIdentity(decryptSecret(cipher!, pw));
        return IdentityState(
          status: IdentityStatus.unlocked,
          addressEip55: address,
          keypair: keypair,
        );
      } catch (_) {
        // 凭证与密文不匹配(如重设过密码/迁移)→ 降级到 locked,等手输。
      }
    }
    return IdentityState(status: IdentityStatus.locked, addressEip55: address);
  }

  /// 生成全新供应商身份(12 词助记词,只此一次展示给用户)。
  Future<void> generate({
    required String password,
    bool autoRecover = true,
  }) async {
    final mnemonic = generateMnemonic();
    final keypair = deriveIdentity(mnemonic);
    await _persist(mnemonic, password, keypair, autoRecover);
  }

  /// 用既有助记词恢复身份(老供应商用同一助记词在 Dart 重新导入,01 迁移约束)。
  /// 非法助记词抛 [ArgumentError](不落盘,不留半截身份)。
  Future<void> recover({
    required String mnemonic,
    required String password,
    bool autoRecover = true,
  }) async {
    if (!isValidMnemonic(mnemonic)) {
      throw ArgumentError('非法助记词:checksum 或词表校验未通过');
    }
    final keypair = deriveIdentity(mnemonic);
    await _persist(mnemonic, password, keypair, autoRecover);
  }

  Future<void> _persist(
    String mnemonic,
    String password,
    ProviderKeypair keypair,
    bool autoRecover,
  ) async {
    final store = _store;
    await store.saveIdentity(
      encryptedMnemonic: encryptSecret(mnemonic, password),
      addressEip55: keypair.addressEip55,
    );
    if (autoRecover) {
      // keychain 失败不致命:自动恢复只是便利,不应阻断身份创建(见 -34018 沙盒坑)。
      try {
        await store.writeUnlockPassword(password);
      } catch (_) {
        // keychain 失败不致命:自动恢复不可用,身份仍可用(见 -34018 沙盒坑)。
      }
    }
    state = AsyncValue.data(IdentityState(
      status: IdentityStatus.unlocked,
      addressEip55: keypair.addressEip55,
      keypair: keypair,
    ));
  }

  /// 用密码解锁已落盘身份。密码错误抛 [DecryptionException](状态保持 locked)。
  Future<void> unlock({required String password}) async {
    final store = _store;
    final cipher = await store.readEncryptedMnemonic();
    if (cipher == null) {
      throw StateError('无身份可解锁');
    }
    final keypair = deriveIdentity(decryptSecret(cipher, password)); // 错密码抛
    state = AsyncValue.data(IdentityState(
      status: IdentityStatus.unlocked,
      addressEip55: keypair.addressEip55,
      keypair: keypair,
    ));
  }

  /// 锁定:丢弃内存私钥,回到 locked(地址仍可知)。
  Future<void> lock() async {
    state = AsyncValue.data(IdentityState(
      status: IdentityStatus.locked,
      addressEip55: state.value?.addressEip55,
    ));
  }
}

final identityControllerProvider =
    AsyncNotifierProvider<IdentityController, IdentityState>(
  IdentityController.new,
);
