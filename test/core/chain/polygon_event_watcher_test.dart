import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/chain/backfill_math.dart';
import 'package:flowing_water/core/chain/chain_client.dart';
import 'package:flowing_water/core/chain/polygon_event_watcher.dart';
import 'package:flowing_water/core/chain/settle_event_syncer.dart';
import 'package:flowing_water/core/db/chain_sync_cursor_dao.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/db/provider_chain_settlement_dao.dart';
import 'package:flowing_water/core/db/provider_log_dao.dart';
import 'package:flowing_water/core/db/unmatched_settled_event_dao.dart';
import 'package:flowing_water/core/relay/ws_client.dart';
import 'package:web3dart/web3dart.dart';

/// PolygonEventWatcher 测试 —— 锁定 03a 的采集不变式:
/// 仅记本 vendor 的 Settled、幂等去重、全程成功才推进游标(失败留游标重试)。
/// 用伪 ChainClient + 内存库,零真实链 IO。
void main() {
  late AppDatabase db;
  late ProviderChainSettlementDao settlementDao;
  late ChainSyncCursorDao cursorDao;
  late ProviderLogDao logDao;
  late UnmatchedSettledEventDao unmatchedDao;

  const mineHex = '0x1111111111111111111111111111111111111111';
  const otherHex = '0x2222222222222222222222222222222222222222';
  const contractHex = '0x3333333333333333333333333333333333333333';
  final mine = EthereumAddress.fromHex(mineHex);
  final contract = EthereumAddress.fromHex(contractHex);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settlementDao = ProviderChainSettlementDao(db);
    cursorDao = ChainSyncCursorDao(db);
    logDao = ProviderLogDao(db);
    unmatchedDao = UnmatchedSettledEventDao(db);
  });
  tearDown(() => db.close());

  PolygonEventWatcher buildWatcher() => PolygonEventWatcher(
        clientFactory: () => throw StateError('tests 用 backfillWith 直接注入'),
        settlementDao: settlementDao,
        cursorDao: cursorDao,
        providerAddress: () => mine,
        contractAddress: contract,
        deployBlock: 100,
      );

  group('handleSettledEvent(解码 + vendor 过滤 + 幂等)', () {
    test('本 vendor 事件 → 落地一行', () async {
      final w = buildWatcher();
      await w.handleSettledEvent(_settledLog(
        vendor: mine, tx: '0xtx1', blockNum: 110, amount: BigInt.from(500),
      ));
      expect(await settlementDao.exists('0xtx1'), isTrue);
    });

    test('他 vendor 事件 → 不落地(客户端兜底过滤)', () async {
      final w = buildWatcher();
      await w.handleSettledEvent(_settledLog(
        vendor: EthereumAddress.fromHex(otherHex),
        tx: '0xtxOther', blockNum: 110,
      ));
      expect(await settlementDao.exists('0xtxOther'), isFalse);
    });

    test('同 tx 二次到达 → 幂等不重复,但补 logIndex', () async {
      final w = buildWatcher();
      await w.handleSettledEvent(_settledLog(
        vendor: mine, tx: '0xtx2', blockNum: 110, logIndex: 5,
      ));
      await w.handleSettledEvent(_settledLog(
        vendor: mine, tx: '0xtx2', blockNum: 110, logIndex: 5,
      ));
      final rows = await db.select(db.providerChainSettlements).get();
      expect(rows, hasLength(1));
      expect(rows.single.logIndex, 5);
    });

    test('金额/计数字段正确解码(uint→BigInt→存储)', () async {
      final w = buildWatcher();
      await w.handleSettledEvent(_settledLog(
        vendor: mine,
        tx: '0xtx3',
        blockNum: 110,
        successCount: BigInt.from(7),
        amount: BigInt.from(123456),
        notSuccessCount: BigInt.from(2),
        notSuccessAmount: BigInt.from(99),
        timestamp: BigInt.from(1700_000_000),
      ));
      final row =
          await (db.select(db.providerChainSettlements)..where((t) => t.tx.equals('0xtx3')))
              .getSingle();
      expect(row.settledCount, 7);
      expect(row.receivedUsdt, '123456');
      expect(row.notSettledCount, 2);
      expect(row.notSettledAmount, '99');
      expect(row.createdAt, 1700_000_000 * 1000); // 秒→毫秒
    });
  });

  group('backfillWith(三层 floor + 分页 + 全程成功才推进)', () {
    test('happy path:跨页补回本 vendor 事件,游标推进至 latest', () async {
      final logs = [
        _settledLog(vendor: mine, tx: '0xa', blockNum: 105),
        _settledLog(vendor: mine, tx: '0xb', blockNum: 118),
        _settledLog(vendor: EthereumAddress.fromHex(otherHex), tx: '0xc', blockNum: 120),
      ];
      final client = _FakeChainClient(blockNumber: 125, logs: logs);
      final w = buildWatcher();
      final processed = await w.backfillWith(client);
      expect(processed, 2); // 他 vendor 的 0c 被过滤
      expect(await settlementDao.exists('0xa'), isTrue);
      expect(await settlementDao.exists('0xb'), isTrue);
      expect(await settlementDao.exists('0xc'), isFalse);
      expect(await cursorDao.get(kProviderSettledScope), 125); // 推进
    });

    test('RPC 中途抛错 → 游标不推进(下次从同一 floor 重试,幂等不重复)', () async {
      final logs = [_settledLog(vendor: mine, tx: '0xa', blockNum: 105)];
      // 第 0 次 getLogs 抛错(deployBlock=100 → 首页 100-109)
      final client = _FakeChainClient(blockNumber: 125, logs: logs, throwOnCall: 0);
      final w = buildWatcher();
      await expectLater(w.backfillWith(client), throwsA(anything));
      expect(await cursorDao.get(kProviderSettledScope), isNull); // 未推进
    });

    test('cursor 存在 → 从 cursor 续点(早于 cursor 的事件不再扫)', () async {
      await cursorDao.set(kProviderSettledScope, 200);
      // latest=205,cursor=200 → 仅扫 200-205;blockNum=150 的事件不该被包含
      final logs = [
        _settledLog(vendor: mine, tx: '0xold', blockNum: 150),
        _settledLog(vendor: mine, tx: '0xnew', blockNum: 203),
      ];
      final client = _FakeChainClient(blockNumber: 205, logs: logs);
      final w = buildWatcher();
      await w.backfillWith(client);
      expect(await settlementDao.exists('0xold'), isFalse);
      expect(await settlementDao.exists('0xnew'), isTrue);
    });
  });

  group('handleSettledEvent → syncer 对账接线(06)', () {
    /// 采集后 unawaited 触发 syncer;泵等对账副作用落地。
    Future<void> pumpUntil(Future<bool> Function() done) async {
      for (var i = 0; i < 200; i++) {
        if (await done()) return;
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      fail('pump 超时:对账副作用未落地');
    }

    Future<String?> chainStatusOf(String requestId) async {
      final row = await (db.select(db.providerLogs)
            ..where((t) => t.requestId.equals(requestId)))
          .getSingleOrNull();
      return row?.chainStatus;
    }

    test('relay 已连 + 反查命中 → 采集后回填 provider_log(chain_status/settle_tx/log_index)',
        () async {
      await logDao.insertRecord(
          requestId: 'req-1',
          modelName: 'gpt',
          inputPricePer1k: 1,
          outputPricePer1k: 2);
      final w = PolygonEventWatcher(
        clientFactory: () => throw StateError('接线测试不建真实 client'),
        settlementDao: settlementDao,
        cursorDao: cursorDao,
        providerAddress: () => mine,
        contractAddress: contract,
        syncer: SettleEventSyncer(
          relayQueryClient: () => _FakeRelayClient([
            {'request_id': 'req-1'},
          ]),
          providerLogDao: logDao,
          unmatchedDao: unmatchedDao,
          maxRetry: 1,
          sleep: (_) async {},
        ),
      );

      await w.handleSettledEvent(_settledLog(
        vendor: mine,
        tx: '0xtx',
        blockNum: 110,
        logIndex: 3,
      ));
      expect(await settlementDao.exists('0xtx'), isTrue); // 采集已落地
      // 对账为 unawaited → pump 等回填:
      await pumpUntil(() async => await chainStatusOf('req-1') == 'on_chain_settled');
      final r1 = await (db.select(db.providerLogs)
            ..where((t) => t.requestId.equals('req-1')))
          .getSingle();
      expect(r1.chainStatus, 'on_chain_settled');
      expect(r1.settleTx, '0xtx');
      expect(r1.logIndex, 3);
    });

    test('无 syncer → 仅采集(05 行为不变;provider_log 不被回填)', () async {
      await logDao.insertRecord(
          requestId: 'req-9',
          modelName: 'gpt',
          inputPricePer1k: 1,
          outputPricePer1k: 2);
      final w = PolygonEventWatcher(
        clientFactory: () => throw StateError(''),
        settlementDao: settlementDao,
        cursorDao: cursorDao,
        providerAddress: () => mine,
        contractAddress: contract,
      );
      await w.handleSettledEvent(_settledLog(
        vendor: mine,
        tx: '0xonly',
        blockNum: 110,
        logIndex: 1,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(await settlementDao.exists('0xonly'), isTrue);
      expect(await chainStatusOf('req-9'), 'not_on_chain'); // 未对账
    });
  });

  group('sync(07:全量同步 /sync-chain-status)', () {
    test('full=false 增量:从 cursor 续点,不重扫 cursor 之前', () async {
      await cursorDao.set(kProviderSettledScope, 200);
      final client = _FakeChainClient(blockNumber: 205, logs: [
        _settledLog(vendor: mine, tx: '0xbefore', blockNum: 150),
        _settledLog(vendor: mine, tx: '0xafter', blockNum: 203),
      ]);
      final processed = await buildWatcher().sync(full: false, client: client);
      expect(processed, 1); // 只 cursor 之后的
      expect(await settlementDao.exists('0xbefore'), isFalse);
      expect(await settlementDao.exists('0xafter'), isTrue);
    });

    test('full=true 全量:重置 cursor 到 deployBlock-1,重扫全部(含 cursor 前)', () async {
      await cursorDao.set(kProviderSettledScope, 200); // 模拟已扫到 200
      final client = _FakeChainClient(blockNumber: 205, logs: [
        _settledLog(vendor: mine, tx: '0xbefore', blockNum: 150), // 增量会漏
        _settledLog(vendor: mine, tx: '0xafter', blockNum: 203),
      ]);
      final processed = await buildWatcher().sync(full: true, client: client);
      expect(processed, 2); // 全量重扫抓到两者
      expect(await settlementDao.exists('0xbefore'), isTrue);
      expect(await settlementDao.exists('0xafter'), isTrue);
      expect(await cursorDao.get(kProviderSettledScope), 205); // 重新推进
    });

    test('无 client(未 start)→ 返回 0,不动游标', () async {
      await cursorDao.set(kProviderSettledScope, 200);
      expect(await buildWatcher().sync(full: true), 0);
      expect(await cursorDao.get(kProviderSettledScope), 200); // 未变
    });
  });
}

/// ---- 测试辅助:构造一条 Settled 的 FilterEvent(手编 ABI topics/data) ----

String _pad32(BigInt v) => v.toRadixString(16).padLeft(64, '0');

FilterEvent _settledLog({
  required EthereumAddress vendor,
  required String tx,
  required int blockNum,
  BigInt? successCount,
  BigInt? amount,
  BigInt? notSuccessCount,
  BigInt? notSuccessAmount,
  BigInt? timestamp,
  int? logIndex,
}) {
  final sc = successCount ?? BigInt.zero;
  final amt = amount ?? BigInt.zero;
  final nsc = notSuccessCount ?? BigInt.zero;
  final nsamt = notSuccessAmount ?? BigInt.zero;
  final ts = timestamp ?? BigInt.zero;
  final vendorTopic = '0x${'0' * 24}${vendor.hexNo0x}'; // 地址右对齐补到 32B
  final data =
      '0x${_pad32(sc)}${_pad32(amt)}${_pad32(nsc)}${_pad32(nsamt)}${_pad32(ts)}';
  return FilterEvent(
    removed: false,
    logIndex: logIndex,
    transactionHash: tx,
    blockNum: blockNum,
    address: EthereumAddress.fromHex('0x0000000000000000000000000000000000000001'),
    data: data,
    topics: ['0x${'0' * 64}', vendorTopic], // topic0 占位(decodeResults 仅跳过)
  );
}

/// 伪 ChainClient:按页 block 范围过滤日志;可在第 [throwOnCall] 次 getLogs 抛错。
class _FakeChainClient implements ChainClient {
  _FakeChainClient({this.blockNumber = 0, List<FilterEvent>? logs, this.throwOnCall})
      : _logs = logs ?? const [];
  final int blockNumber;
  final List<FilterEvent> _logs;
  final int? throwOnCall;
  int _calls = 0;

  @override
  Future<List<FilterEvent>> getLogs(FilterOptions options) async {
    final c = _calls++;
    if (throwOnCall == c) throw Exception('rpc down');
    final from = options.fromBlock!.blockNum;
    final to = options.toBlock!.blockNum;
    return _logs
        .where((l) => l.blockNum != null && l.blockNum! >= from && l.blockNum! <= to)
        .toList();
  }

  @override
  Future<int> getBlockNumber() async => blockNumber;
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
  Stream<FilterEvent> events(FilterOptions options) => const Stream.empty();
  @override
  Future<void> dispose() async {}
}

/// 伪 RelayQueryClient(06 接线测试):固定返回一组 relay 记录。
class _FakeRelayClient implements RelayQueryClient {
  _FakeRelayClient(this.records);
  final List<Map<String, dynamic>> records;

  @override
  Future<List<Map<String, dynamic>>> queryModelParams({String? q}) async =>
      const [];

  @override
  Future<List<Map<String, dynamic>>> queryRelayRecordsByTxLogindex(
          String tx, int logIndex) async =>
      records;
}
