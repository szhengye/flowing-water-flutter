import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flowing_water/core/chain/unmatched_retry_service.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/db/provider_log_dao.dart';
import 'package:flowing_water/core/db/unmatched_settled_event_dao.dart';
import 'package:flowing_water/core/relay/ws_client.dart';

/// UnmatchedRetryService 测试 —— 锁定 09 operator retry-all 不变式(对齐上游
/// `/unmatched-settled-events/retry-all`):
///  - relay 已连:命中→从未匹配表移除 + 回填 provider_log;0 匹配→recordRetry。
///  - relay 超时未连:整体跳过,不动 DAO(不盲重试、不误删)。
/// 伪 client(按 tx/logIndex 键控)+ 内存库 + Duration.zero retryDelay,零真实 WS IO。
void main() {
  late AppDatabase db;
  late ProviderLogDao logDao;
  late UnmatchedSettledEventDao unmatchedDao;

  const mineHex = '0x1111111111111111111111111111111111111111';
  const txA =
      '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const txB =
      '0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    logDao = ProviderLogDao(db);
    unmatchedDao = UnmatchedSettledEventDao(db);
  });
  tearDown(() => db.close());

  /// 落一条 unmatched 行(字段对齐 syncer._recordUnmatched 写入)。
  Future<void> seedUnmatched(String tx, int logIndex) => unmatchedDao.insert(
        tx: tx,
        logIndex: logIndex,
        providerAddress: mineHex,
        receivedUsdt: '500000000',
        settledCount: 2,
        settledAmount: '500000000',
        notSettledCount: 0,
        notSettledAmount: '0',
        blockTimestamp: 1700000000,
      );

  UnmatchedRetryService buildService(
    RelayQueryClient? Function() supplier, {
    Duration timeout = const Duration(seconds: 20),
  }) =>
      UnmatchedRetryService(
        unmatchedDao: unmatchedDao,
        providerLogDao: logDao,
        relayQueryClient: supplier,
        waitForConnectedTimeout: timeout,
        pollInterval: const Duration(milliseconds: 3),
        syncerRetryDelay: Duration.zero,
        sleep: (d) => Future.delayed(d),
      );

  test('命中→remove + 回填 provider_log;0 匹配→recordRetry', () async {
    await logDao.insertRecord(
        requestId: 'req-1',
        modelName: 'gpt',
        inputPricePer1k: 1,
        outputPricePer1k: 2);
    await seedUnmatched(txA, 5); // 将命中
    await seedUnmatched(txB, 7); // 仍 0 匹配

    final client = _KeyedFakeClient({
      '$txA:5': [
        {'request_id': 'req-1'},
      ],
      '$txB:7': const [], // 恒空 → syncer 重试耗尽 → recordRetry
    });
    final summary = await buildService(() => client).retryAll();

    expect(summary.notConnected, isFalse);
    expect(summary.retried, 2);
    expect(summary.matched, 1);
    expect(summary.stillUnmatched, 1);

    // 命中的从未匹配表移除;未命中的留下且 retryCount 累加。
    final rows = await unmatchedDao.list();
    expect(rows.length, 1);
    expect(rows.single.tx, txB);
    expect(rows.single.retryCount, 1);

    // 命中回填 provider_log(强制 on_chain_settled + settle_tx + log_index)。
    final log = await (db.select(db.providerLogs)
          ..where((t) => t.requestId.equals('req-1')))
        .getSingle();
    expect(log.chainStatus, 'on_chain_settled');
    expect(log.settleTx, txA);
    expect(log.logIndex, 5);
  });

  test('relay 超时未连接 → notConnected,不动 DAO', () async {
    await seedUnmatched(txA, 5);
    final summary = await buildService(
      () => null, // 恒未连接
      timeout: const Duration(milliseconds: 10),
    ).retryAll();

    expect(summary.notConnected, isTrue);
    expect(summary.retried, 0);
    expect(summary.matched, 0);

    // 未匹配表未被动过(retryCount 仍 0)。
    final rows = await unmatchedDao.list();
    expect(rows.length, 1);
    expect(rows.single.retryCount, 0);
  });

  test('无未匹配事件 → 空汇总(retried 0,不构造 syncer)', () async {
    final client = _KeyedFakeClient(const {});
    final summary = await buildService(() => client).retryAll();
    expect(summary.retried, 0);
    expect(summary.matched, 0);
    expect(summary.stillUnmatched, 0);
    expect(summary.notConnected, isFalse);
  });
}

/// 按 (tx, logIndex) 键控的伪 client:命中 key 返回其 records;未配置/空 → []
/// (syncer 内部对 [] 重试 maxRetry 次仍空 → 上层 recordRetry)。
class _KeyedFakeClient implements RelayQueryClient {
  _KeyedFakeClient(this.map);
  final Map<String, List<Map<String, dynamic>>> map;

  @override
  Future<List<Map<String, dynamic>>> queryRelayRecordsByTxLogindex(
          String tx, int logIndex) async =>
      map['$tx:$logIndex'] ?? const [];

  @override
  Future<List<Map<String, dynamic>>> queryModelParams({String? q}) async =>
      const [];
}
