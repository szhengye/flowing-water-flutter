import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/chain/abi/relay_station.dart';
import 'package:flowing_water/core/chain/settle_event_syncer.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/db/provider_log_dao.dart';
import 'package:flowing_water/core/db/unmatched_settled_event_dao.dart';
import 'package:flowing_water/core/relay/ws_client.dart';
import 'package:web3dart/web3dart.dart';

/// SettleEventSyncer 测试 —— 锁定 06 对账不变式(对齐上游 settle-event-syncer.ts):
/// 命中→强制 on_chain_settled 回填 provider_log;零匹配/失败耗尽/未连接→unmatched;
/// 重试的是 WS 查询(网络错或空响应都重试);永不 ±时间窗。用伪 RelayQueryClient +
/// 内存库,零真实 WS IO。
void main() {
  late AppDatabase db;
  late ProviderLogDao logDao;
  late UnmatchedSettledEventDao unmatchedDao;

  const mineHex = '0x1111111111111111111111111111111111111111';
  final mine = EthereumAddress.fromHex(mineHex);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    logDao = ProviderLogDao(db);
    unmatchedDao = UnmatchedSettledEventDao(db);
  });
  tearDown(() => db.close());

  SettledEventArgs event() => SettledEventArgs(
        vendor: mine,
        successCount: BigInt.two,
        amount: BigInt.from(500),
        notSuccessCount: BigInt.zero,
        notSuccessAmount: BigInt.zero,
        timestamp: BigInt.from(1700000000),
      );

  SettleEventSyncer buildSyncer(RelayQueryClient? Function() supplier) =>
      SettleEventSyncer(
        relayQueryClient: supplier,
        providerLogDao: logDao,
        unmatchedDao: unmatchedDao,
        maxRetry: 3,
        retryDelay: Duration.zero,
        sleep: (_) async {},
      );

  group('命中', () {
    test('反查命中 N 笔 → 回填 provider_log(chain_status/settle_tx/log_index),不写 unmatched',
        () async {
      await logDao.insertRecord(
          requestId: 'req-1', modelName: 'gpt', inputPricePer1k: 1, outputPricePer1k: 2);
      await logDao.insertRecord(
          requestId: 'req-2', modelName: 'gpt', inputPricePer1k: 1, outputPricePer1k: 2);
      final client = _FakeClient([
        [
          {'request_id': 'req-1', 'chain_status': 'on_chain_not_settled'},
          {'request_id': 'req-2'},
        ],
      ]);
      final res = await buildSyncer(() => client)
          .sync(tx: '0xtx', logIndex: 5, event: event());

      expect(res.matched, 2);
      expect(res.matchedRequestIds, ['req-1', 'req-2']);
      expect(res.recordedToUnmatched, isFalse);
      // 强制 on_chain_settled:relay 的 on_chain_not_settled 不穿透(bi-state)。
      final r1 = await _logRow(db, 'req-1');
      expect(r1.chainStatus, 'on_chain_settled');
      expect(r1.settleTx, '0xtx');
      expect(r1.logIndex, 5);
      expect((await _logRow(db, 'req-2')).chainStatus, 'on_chain_settled');
      expect(await _unmatchedCount(db), 0);
    });

    test('反查先抛错后命中 → 重试成功回填', () async {
      await logDao.insertRecord(
          requestId: 'req-1', modelName: 'gpt', inputPricePer1k: 1, outputPricePer1k: 2);
      final client = _FakeClient([
        Exception('网络断'),
        [{'request_id': 'req-1'}],
      ]);
      final res = await buildSyncer(() => client)
          .sync(tx: '0xtx', logIndex: 5, event: event());

      expect(res.matched, 1);
      expect(client.calls, 2); // 第一次抛错 → 重试第二次命中
      expect((await _logRow(db, 'req-1')).chainStatus, 'on_chain_settled');
    });
  });

  group('落 unmatched', () {
    test('反查恒空 → 重试耗尽落 unmatched,不动 provider_log', () async {
      final client = _FakeClient([[]]); // 恒空
      final res = await buildSyncer(() => client)
          .sync(tx: '0xtx', logIndex: 5, event: event());

      expect(res.matched, 0);
      expect(res.recordedToUnmatched, isTrue);
      expect(client.calls, 3); // 重试满 maxRetry
      expect(await _unmatchedCount(db), 1);
    });

    test('反查恒抛错 → 重试耗尽落 unmatched,带 lastError', () async {
      final client = _FakeClient([StateError('relay 500')]);
      final res = await buildSyncer(() => client)
          .sync(tx: '0xtx', logIndex: 7, event: event());

      expect(res.matched, 0);
      expect(res.recordedToUnmatched, isTrue);
      expect(res.lastError, isNotNull);
      expect(await _unmatchedCount(db), 1);
    });

    test('relay 未连接 → 直接落 unmatched,不反查不重试', () async {
      final client = _FakeClient([[]]);
      final res = await buildSyncer(() => null)
          .sync(tx: '0xtx', logIndex: 5, event: event());

      expect(res.matched, 0);
      expect(res.recordedToUnmatched, isTrue);
      expect(client.calls, 0); // 未连接:根本没反查
      expect(await _unmatchedCount(db), 1);
    });

    test('同 (tx,logIndex) 二次 → unmatched 幂等不重', () async {
      final syncer = buildSyncer(() => null);
      await syncer.sync(tx: '0xtx', logIndex: 5, event: event());
      await syncer.sync(tx: '0xtx', logIndex: 5, event: event());
      expect(await _unmatchedCount(db), 1);
    });
  });

  group('不误记', () {
    test('命中只回填匹配的 requestId,未匹配的不动', () async {
      await logDao.insertRecord(
          requestId: 'matched', modelName: 'gpt', inputPricePer1k: 1, outputPricePer1k: 2);
      await logDao.insertRecord(
          requestId: 'untouched', modelName: 'gpt', inputPricePer1k: 1, outputPricePer1k: 2);
      final client = _FakeClient([
        [{'request_id': 'matched'}],
      ]);
      await buildSyncer(() => client).sync(tx: '0xtx', logIndex: 9, event: event());

      expect((await _logRow(db, 'matched')).chainStatus, 'on_chain_settled');
      // 未在反查结果里的 requestId 保持 not_on_chain(不靠 ±时间窗猜配)。
      expect((await _logRow(db, 'untouched')).chainStatus, 'not_on_chain');
      expect((await _logRow(db, 'untouched')).settleTx, isNull);
    });
  });
}

Future<ProviderLogRow> _logRow(AppDatabase db, String requestId) =>
    (db.select(db.providerLogs)..where((t) => t.requestId.equals(requestId)))
        .getSingle();

Future<int> _unmatchedCount(AppDatabase db) async =>
    (await db.select(db.unmatchedSettledEvents).get()).length;

/// 脚本化伪 client:每次调用消费一条(耗尽则重复最后一条)。List→成功返回;
/// 非 List(异常)→抛。让 syncer 的 retry / 命中 / 落 unmatched 路径全可控。
class _FakeClient implements RelayQueryClient {
  _FakeClient(this._script);
  final List<Object> _script;
  int calls = 0;

  @override
  Future<List<Map<String, dynamic>>> queryModelParams({String? q}) async =>
      const [];

  @override
  Future<List<Map<String, dynamic>>> queryRelayRecordsByTxLogindex(
    String tx,
    int logIndex,
  ) async {
    final next = _script[calls.clamp(0, _script.length - 1)];
    calls++;
    if (next is List) return next.cast<Map<String, dynamic>>();
    throw next;
  }
}
