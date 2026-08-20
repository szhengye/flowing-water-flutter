import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flowing_water/core/chain/chain_client.dart';
import 'package:flowing_water/core/chain/chain_watcher_service.dart';
import 'package:flowing_water/core/config/app_config.dart';
import 'package:flowing_water/core/crypto/identity_controller.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/providers.dart';

/// ChainWatcherService 测试 —— 锁定身份门禁 + 配置门禁的编排不变式
/// (身份 / 配置 / 链客户端均 override 注入)。意图:身份未解锁或 Polygon 未配置时,
/// 绝不建链客户端、不发起连接。
void main() {
  const contract = '0x3333333333333333333333333333333333333333';

  AppConfig cfg({String rpc = 'http://rpc', String ws = 'wss://ws'}) => AppConfig(
        network: AppNetwork.dev,
        relayWsUrl: '',
        polygonRpcUrl: rpc,
        polygonRpcUrlWs: ws,
        polygonContractAddress: contract,
        polygonDeployBlock: 0,
        polygonUsdtAddress: '',
        polygonscanApiKey: '',
        upstreamApiKey: '',
      );

  group('ChainWatcherService 身份门禁 + 配置门禁', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('unlocked + 配置齐全 → 起 watcher(running)', () async {
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appConfigProvider.overrideWithValue(cfg()),
        chainClientFactoryProvider.overrideWithValue((_) => _FakeChainClient()),
        identityControllerProvider.overrideWith(_UnlockedIdentity.new),
      ]);
      addTearDown(container.dispose);

      await container.read(identityControllerProvider.future);
      container.read(chainWatcherServiceProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        container.read(chainWatcherStatusProvider),
        ChainWatcherStatus.running,
      );
    });

    test('配置缺失(Polygon RPC 空)→ disabled,不建 client', () async {
      var clientBuilt = false;
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appConfigProvider.overrideWithValue(cfg(rpc: '')),
        chainClientFactoryProvider.overrideWithValue((_) {
          clientBuilt = true;
          return _FakeChainClient();
        }),
        identityControllerProvider.overrideWith(_UnlockedIdentity.new),
      ]);
      addTearDown(container.dispose);

      await container.read(identityControllerProvider.future);
      container.read(chainWatcherServiceProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        container.read(chainWatcherStatusProvider),
        ChainWatcherStatus.disabled,
      );
      expect(clientBuilt, isFalse, reason: '配置缺失不应建链客户端');
    });

    test('locked → stopped,不建 client', () async {
      var clientBuilt = false;
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appConfigProvider.overrideWithValue(cfg()),
        chainClientFactoryProvider.overrideWithValue((_) {
          clientBuilt = true;
          return _FakeChainClient();
        }),
        identityControllerProvider.overrideWith(_LockedIdentity.new),
      ]);
      addTearDown(container.dispose);

      await container.read(identityControllerProvider.future);
      container.read(chainWatcherServiceProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        container.read(chainWatcherStatusProvider),
        ChainWatcherStatus.stopped,
      );
      expect(clientBuilt, isFalse, reason: '身份未解锁不应起链监听');
    });
  });
}

const _addr = '0x58A57ed9d8d624cBD12e2C467D34787555bB1b25';

class _UnlockedIdentity extends IdentityController {
  @override
  Future<IdentityState> build() async => const IdentityState(
        status: IdentityStatus.unlocked,
        addressEip55: _addr,
      );
}

class _LockedIdentity extends IdentityController {
  @override
  Future<IdentityState> build() async => const IdentityState(
        status: IdentityStatus.locked,
        addressEip55: _addr,
      );
}

class _FakeChainClient implements ChainClient {
  @override
  Stream<FilterEvent> events(FilterOptions options) => const Stream.empty();
  @override
  Future<List<FilterEvent>> getLogs(FilterOptions options) async => const [];
  @override
  Future<int> getBlockNumber() async => 100;
  @override
  Future<EtherAmount> getBalance(EthereumAddress address) async =>
      EtherAmount.zero();
  @override
  Future<BigInt> getTokenBalance({
    required EthereumAddress token,
    required EthereumAddress owner,
  }) async =>
      BigInt.zero;
  @override
  Future<void> dispose() async {}
}
