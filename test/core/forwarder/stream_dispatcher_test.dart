import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/db/provider_log_dao.dart';
import 'package:flowing_water/core/forwarder/stream_dispatcher.dart';
import 'package:flowing_water/core/forwarder/model_mapping.dart';
import 'package:flowing_water/core/forwarder/stream_http.dart';
import 'package:flowing_water/core/relay/messages.dart';

/// StreamDispatcher 测试 —— 锁定计费插桩(insert pending → complete 落 amount /
/// fail 落 error)、relay 回吐消息序列(chunk 即时、end/error 在主流程)、providerSignature 恒空串。
/// 真 DAO(内存库)+ 真 mapping + 假 send(记录)+ 假 streamHttp(预设 SSE)。
void main() {
  late AppDatabase db;
  late ProviderLogDao dao;
  late List<RelayMessage> sent;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = ProviderLogDao(db);
    sent = [];
  });
  tearDown(() => db.close());

  StreamDispatcher makeDispatcher(StreamHttpFn http) => StreamDispatcher(
        send: sent.add,
        dao: dao,
        resolveMapping: (m) => resolveProviderMapping(db, m),
        streamHttp: http,
      );

  Future<int> seedVendor({String adapterType = 'openai'}) =>
      db.into(db.providerLlmVendors).insert(
            ProviderLlmVendorsCompanion.insert(
              vendorName: 'v',
              endpoint: 'https://api.openai.com/v1',
              apiKey: 'sk-x',
              adapterType: Value(adapterType),
            ),
          );

  Future<void> seedQuotation(
    int vendorId,
    String relayModel, {
    int inputPrice = 2,
    int outputPrice = 3,
  }) =>
      db.into(db.providerQuotations).insert(
            ProviderQuotationsCompanion.insert(
              relayModelName: relayModel,
              providerId: Value(vendorId),
              providerModel: Value(relayModel),
              inputPricePer1k: Value(inputPrice),
              outputPricePer1k: Value(outputPrice),
            ),
          );

  StreamHttpFn okHttp(String sse) => ({required url, required headers, required body, required cancelToken}) async {
        final controller = StreamController<List<int>>();
        Future(() {
          controller.add(utf8.encode(sse));
          controller.close();
        });
        return UpstreamStreamedResponse(200, 'text/event-stream', controller.stream);
      };

  StreamHttpFn errorHttp(int status) => ({required url, required headers, required body, required cancelToken}) async {
        final controller = StreamController<List<int>>();
        Future(() {
          controller.add(utf8.encode('boom'));
          controller.close();
        });
        return UpstreamStreamedResponse(status, 'text/plain', controller.stream);
      };

  group('成功往返(计费 + 回吐序列)', () {
    test('chunk 即时回吐;end 在主流程(providerSignature 恒空);落 completed+amount', () async {
      final vid = await seedVendor();
      await seedQuotation(vid, 'gpt-4o'); // in=2,out=3
      final dispatcher = makeDispatcher(okHttp(
        'data: {"id":"x","object":"chat.completion.chunk","created":1,"model":"gpt-4o",'
            '"choices":[{"index":0,"delta":{"content":"Hi"},"finish_reason":null}]}\n\n'
        'data: {"choices":[],"usage":{"prompt_tokens":500,"completion_tokens":500,'
            '"total_tokens":1000}}\n\n'
        'data: [DONE]\n\n',
      ));

      await dispatcher.handleLlmRequest(LlmRequestMessage(
        requestId: 'r1',
        request: LlmRequest(model: 'gpt-4o', messages: []),
      ));

      // 回吐序列:chunk(s) + end。
      final chunks = sent.whereType<LlmStreamChunkMessage>().toList();
      final ends = sent.whereType<LlmStreamEndMessage>().toList();
      expect(chunks, isNotEmpty);
      expect(ends.single.usage.promptTokens, 500);
      expect(ends.single.providerSignature, '', reason: '01:结算锚链上,恒空串');
      expect(sent.whereType<LlmErrorMessage>(), isEmpty);

      // 计费落库:completed + amount=round((2×500+3×500)/1000)=round(2.5)=3。
      final row = await db.select(db.providerLogs).getSingle();
      expect(row.processingStatus, 'completed');
      expect(row.inputTokens, 500);
      expect(row.outputTokens, 500);
      expect(row.amount, 3);
      expect(row.providerInputPrice, 2);
      expect(row.providerOutputPrice, 3);
    });
  });

  group('错误路径', () {
    test('无 mapping → send LlmErrorMessage(no_mapping),无 provider_log 行', () async {
      final dispatcher = makeDispatcher(okHttp('data: [DONE]\n\n'));
      await dispatcher.handleLlmRequest(LlmRequestMessage(
        requestId: 'r2',
        request: LlmRequest(model: 'unknown', messages: []),
      ));
      final errs = sent.whereType<LlmErrorMessage>().toList();
      expect(errs.single.code, 'no_mapping');
      expect(errs.single.requestId, 'r2');
      expect(await db.select(db.providerLogs).get(), isEmpty);
    });

    test('upstream 500 → fail 落 error_message + send LlmErrorMessage(upstream_500)', () async {
      final vid = await seedVendor();
      await seedQuotation(vid, 'gpt-4o');
      final dispatcher = makeDispatcher(errorHttp(500));
      await dispatcher.handleLlmRequest(LlmRequestMessage(
        requestId: 'r3',
        request: LlmRequest(model: 'gpt-4o', messages: []),
      ));
      final errs = sent.whereType<LlmErrorMessage>().toList();
      expect(errs.single.code, 'upstream_500');
      final row = await db.select(db.providerLogs).getSingle();
      expect(row.processingStatus, 'failed');
      expect(row.errorMessage, contains('upstream_500'));
    });
  });

  group('取消/abort', () {
    test('handleStreamCancel 对未知 requestId 是 no-op(不抛)', () {
      final dispatcher = makeDispatcher(okHttp('data: [DONE]\n\n'));
      expect(() => dispatcher.handleStreamCancel('nonexistent'), returnsNormally);
    });

    test('abortAll 清空活跃流集合(初始即空)', () {
      final dispatcher = makeDispatcher(okHttp('data: [DONE]\n\n'));
      dispatcher.abortAll();
      expect(dispatcher.hasActive, isFalse);
    });
  });
}
