import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/db/provider_log_dao.dart';

/// provider_log DAO 测试 —— 锁定计费三段插桩(insert pending+时点价 → complete 落
/// amount / fail 落 error_message)与 amount 公式。内存库,零 IO。
void main() {
  late AppDatabase db;
  late ProviderLogDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = ProviderLogDao(db);
  });
  tearDown(() => db.close());

  group('computeAmount(公式 round((in×prompt + out×completion)/1000) nUSD)', () {
    test('整数倍', () => expect(ProviderLogDao.computeAmount(1, 1, 1000, 0), 1));
    test('非整数 .5 远离零舍入(2.5→3)', () {
      expect(ProviderLogDao.computeAmount(2, 3, 500, 500), 3);
    });
    test('零用量零金额(即使单价高)', () {
      expect(ProviderLogDao.computeAmount(5, 5, 0, 0), 0);
    });
  });

  test('insert→complete:pending 落时点价;complete 落 token/amount/latency 置 completed', () async {
    await dao.insertRecord(
      requestId: 'r1',
      modelName: 'gpt-4o',
      inputPricePer1k: 2,
      outputPricePer1k: 3,
    );
    var row = await db.select(db.providerLogs).getSingle();
    expect(row.processingStatus, 'pending');
    expect(row.providerInputPrice, 2);
    expect(row.providerOutputPrice, 3);
    expect(row.amount, 0);

    await dao.completeRecord(
      requestId: 'r1',
      promptTokens: 500,
      completionTokens: 500,
      amount: ProviderLogDao.computeAmount(2, 3, 500, 500),
      latencyMs: 123,
    );
    row = await db.select(db.providerLogs).getSingle();
    expect(row.processingStatus, 'completed');
    expect(row.inputTokens, 500);
    expect(row.outputTokens, 500);
    expect(row.amount, 3);
    expect(row.latencyMs, 123);
  });

  test('failRecord:置 failed + error_message', () async {
    await dao.insertRecord(
      requestId: 'r2',
      modelName: 'm',
      inputPricePer1k: 1,
      outputPricePer1k: 1,
    );
    await dao.failRecord(requestId: 'r2', errorMessage: 'upstream 500');
    final row = await db.select(db.providerLogs).getSingle();
    expect(row.processingStatus, 'failed');
    expect(row.errorMessage, 'upstream 500');
  });

  group('getBySettleTx(07:按 settle tx 查关联流水)', () {
    Future<void> settle(String reqId, String settleTx, int logIndex) async {
      await dao.insertRecord(
        requestId: reqId,
        modelName: 'gpt',
        inputPricePer1k: 1,
        outputPricePer1k: 2,
      );
      await dao.updateChainStatus(
        requestId: reqId,
        chainStatus: 'on_chain_settled',
        settleTx: settleTx,
        logIndex: logIndex,
      );
    }

    test('只返回该 settle_tx 的记录(排除他 tx / 未上链)', () async {
      await settle('r1', '0xtx', 1);
      await settle('r2', '0xtx', 2);
      await settle('r3', '0xother', 0);
      // 未上链的记录(settle_tx 仍 null)不应出现
      await dao.insertRecord(
        requestId: 'r4',
        modelName: 'gpt',
        inputPricePer1k: 1,
        outputPricePer1k: 2,
      );

      final rows = await dao.getBySettleTx('0xtx');
      expect(rows, hasLength(2));
      expect(rows.map((r) => r.requestId).toSet(), {'r1', 'r2'});
    });

    test('无匹配 → 空列表', () async {
      await settle('r9', '0xknown', 0);
      expect(await dao.getBySettleTx('0xnone'), isEmpty);
    });
  });

  group('watchRecords(04:Records 筛选,createdAt 倒序)', () {
    Future<void> ins(
      String reqId, {
      String status = 'completed',
      String chain = 'not_on_chain',
      int createdAt = 0,
    }) async {
      await db.into(db.providerLogs).insert(
            ProviderLogsCompanion.insert(
              requestId: reqId,
              modelName: 'm',
              processingStatus: Value(status),
              chainStatus: Value(chain),
              createdAt: Value(createdAt),
            ),
          );
    }

    test('无筛选 → 全部,最新在前', () async {
      await ins('r1', createdAt: 100);
      await ins('r2', createdAt: 300);
      await ins('r3', createdAt: 200);
      final rows = await dao.watchRecords().first;
      expect(rows.map((r) => r.requestId).toList(), ['r2', 'r3', 'r1']);
    });

    test('按处理状态筛(completed)', () async {
      await ins('r1', status: 'completed');
      await ins('r2', status: 'failed');
      await ins('r3', status: 'completed');
      final rows = await dao.watchRecords(processingStatus: 'completed').first;
      expect(rows.map((r) => r.requestId).toSet(), {'r1', 'r3'});
    });

    test('按链态筛 + 状态 双维度(on_chain_settled 且 failed)', () async {
      await ins('r1', status: 'completed', chain: 'on_chain_settled');
      await ins('r2', status: 'failed', chain: 'on_chain_settled');
      await ins('r3', status: 'failed', chain: 'not_on_chain');
      final rows = await dao
          .watchRecords(processingStatus: 'failed', chainStatus: 'on_chain_settled')
          .first;
      expect(rows.map((r) => r.requestId).toList(), ['r2']);
    });
  });

  group('computeLlmMetrics(04:Dashboard 聚合,纯函数)', () {
    Future<List<ProviderLogRow>> seed() async {
      // 两笔 completed(gpt-4o)+ 一笔 failed(claude)+ 一笔 pending(gpt-4o)。
      await db.into(db.providerLogs).insert(ProviderLogsCompanion.insert(
            requestId: 'a', modelName: 'gpt-4o',
            processingStatus: const Value('completed'),
            amount: const Value(10), inputTokens: const Value(100),
            outputTokens: const Value(50), latencyMs: const Value(200),
            createdAt: const Value(1)));
      await db.into(db.providerLogs).insert(ProviderLogsCompanion.insert(
            requestId: 'b', modelName: 'gpt-4o',
            processingStatus: const Value('completed'),
            amount: const Value(5), inputTokens: const Value(50),
            outputTokens: const Value(20), latencyMs: const Value(100),
            createdAt: const Value(2)));
      await db.into(db.providerLogs).insert(ProviderLogsCompanion.insert(
            requestId: 'c', modelName: 'claude',
            processingStatus: const Value('failed'),
            createdAt: const Value(3)));
      await db.into(db.providerLogs).insert(ProviderLogsCompanion.insert(
            requestId: 'd', modelName: 'gpt-4o',
            processingStatus: const Value('pending'),
            createdAt: const Value(4)));
      return db.select(db.providerLogs).get();
    }

    test('完成率/失败率/计费额/用量只计 completed;调用数含全部', () async {
      final m = computeLlmMetrics(await seed());
      expect(m.total, 4);
      expect(m.completed, 2);
      expect(m.failed, 1);
      expect(m.pending, 1);
      // 业务意图:计费额/用量只算最终成功的;failed/pending 无最终用量。
      expect(m.amountNusd, 15);
      expect(m.inputTokens, 150);
      expect(m.outputTokens, 70);
      expect(m.avgLatencyMs, 150); // (200+100)/2
      expect(m.completionRate, 0.5);
      expect(m.failureRate, 0.25);
    });

    test('模型明细按计费额倒序;calls 含失败/pending,completed/amount 仅成功', () async {
      final m = computeLlmMetrics(await seed());
      expect(m.byModel.first.modelName, 'gpt-4o');
      final gpt = m.byModel.firstWhere((e) => e.modelName == 'gpt-4o');
      expect(gpt.calls, 3); // 2 completed + 1 pending
      expect(gpt.completed, 2);
      expect(gpt.amountNusd, 15);
      final claude = m.byModel.firstWhere((e) => e.modelName == 'claude');
      expect(claude.calls, 1);
      expect(claude.completed, 0);
      expect(claude.amountNusd, 0);
    });

    test('空流水 → empty(metrics),不抛', () {
      final m = computeLlmMetrics([]);
      expect(m, LlmMetrics.empty);
      expect(m.total, 0);
      expect(m.completionRate, 0);
    });
  });

  group('computeVendorBreakdown(12:厂商汇总,纯函数)', () {
    test('按厂商聚合 completed 收益/调用;未映射归「未知」;按收益倒序', () async {
      await db.into(db.providerLogs).insert(ProviderLogsCompanion.insert(
            requestId: 'a', modelName: 'gpt-4o',
            processingStatus: const Value('completed'),
            amount: const Value(10), createdAt: const Value(1)));
      await db.into(db.providerLogs).insert(ProviderLogsCompanion.insert(
            requestId: 'b', modelName: 'gpt-4o',
            processingStatus: const Value('completed'),
            amount: const Value(5), createdAt: const Value(2)));
      await db.into(db.providerLogs).insert(ProviderLogsCompanion.insert(
            requestId: 'c', modelName: 'claude',
            processingStatus: const Value('completed'),
            amount: const Value(3), createdAt: const Value(3)));
      await db.into(db.providerLogs).insert(ProviderLogsCompanion.insert(
            requestId: 'd', modelName: 'unknown-model',
            processingStatus: const Value('completed'),
            amount: const Value(2), createdAt: const Value(4)));
      await db.into(db.providerLogs).insert(ProviderLogsCompanion.insert(
            requestId: 'e', modelName: 'gpt-4o',
            processingStatus: const Value('failed'),
            amount: const Value(0), createdAt: const Value(5)));
      final rows = await db.select(db.providerLogs).get();
      final v = computeVendorBreakdown(
          rows, {'gpt-4o': 'OpenAI', 'claude': 'Anthropic'});
      // 收益倒序:OpenAI(15) > Anthropic(3) > 未知(2)
      expect(v.map((e) => e.vendor).toList(), ['OpenAI', 'Anthropic', '未知']);
      final openai = v.firstWhere((e) => e.vendor == 'OpenAI');
      expect(openai.calls, 2); // 2 completed(failed 不计)
      expect(openai.amountNusd, 15);
      expect(v.firstWhere((e) => e.vendor == '未知').amountNusd, 2);
    });

    test('空 rows → 空列表', () {
      expect(computeVendorBreakdown([], {'a': 'X'}), isEmpty);
    });
  });
}
