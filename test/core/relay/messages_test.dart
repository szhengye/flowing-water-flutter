import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/relay/messages.dart';

/// relay WS 协议消息层测试(wayfinder ticket 01 / Slice A)。
///
/// 协议权威:web3-api/packages/shared/src/protocol/messages.ts。
/// 这些测试锁定两件事——握手消息的 wire 形状(中转站只认这些字段),以及
/// 3 个 query_settlement* 消息**破坏 {type,payload} envelope**(姊妹 spike 03
/// 踩过的坑):decode 必须在按 type 派发前先拦截这三型,否则它们没有 payload 包裹。
void main() {
  group('握手消息(envelope {type, payload})', () {
    test('Auth 往返:address / paymentAddress / signature', () {
      final encoded = encodeMessage(const Auth(
        address: '0xOwner',
        paymentAddress: '0xPayee',
        signature: '0xSig',
      ));

      final decoded = decodeMessage(encoded);
      check(decoded is Auth);
      final auth = decoded as Auth;
      expect(auth.address, '0xOwner');
      expect(auth.paymentAddress, '0xPayee');
      expect(auth.signature, '0xSig');
    });

    test('AuthAck 成功态带 challenge(下一次握手用)', () {
      final decoded = decodeMessage(jsonEncode({
        'type': 'auth_ack',
        'payload': {'success': true, 'challenge': 'next-challenge'},
      }));

      check(decoded is AuthAck);
      final ack = decoded as AuthAck;
      expect(ack.success, isTrue);
      expect(ack.challenge, 'next-challenge');
      expect(ack.error, isNull);
    });

    test('AuthAck 失败态带 error(中转站拒绝鉴权)', () {
      final decoded = decodeMessage(jsonEncode({
        'type': 'auth_ack',
        'payload': {'success': false, 'error': 'bad signature'},
      }));

      final ack = decoded as AuthAck;
      expect(ack.success, isFalse);
      expect(ack.error, 'bad signature');
      expect(ack.challenge, isNull);
    });

    test('ProviderInfo 编码:models[] 只含 relayModel + 价格(不发 name)', () {
      final encoded = encodeMessage(ProviderInfo(
        address: '0xOwner',
        paymentAddress: '0xPayee',
        models: const [
          ProviderModel(
              relayModel: 'gpt-4o-mini',
              inputPricePer1k: 1,
              outputPricePer1k: 2),
        ],
      ));

      // 中转站只读 m.relayModel;TS 多发的 name 被忽略 —— Dart 只发 relayModel。
      final wire = jsonDecode(encoded) as Map<String, dynamic>;
      final payload = wire['payload'] as Map<String, dynamic>;
      final model = (payload['models'] as List).single as Map<String, dynamic>;
      expect(model.keys.toSet(), {'relayModel', 'inputPricePer1k', 'outputPricePer1k'});
      expect(model['relayModel'], 'gpt-4o-mini');
      expect(model['inputPricePer1k'], 1);
      expect(model['outputPricePer1k'], 2);
      expect(payload['supportsStream'], true);
    });

    test('ProviderInfo 空 models 列表(无报价时上报空)', () {
      final encoded = encodeMessage(const ProviderInfo(
        address: '0xOwner',
        paymentAddress: '0xPayee',
        models: [],
      ));

      final wire = jsonDecode(encoded) as Map<String, dynamic>;
      expect((wire['payload'] as Map)['models'], isEmpty);
    });

    test('Heartbeat 往返:timestamp(ms)', () {
      final encoded = encodeMessage(const Heartbeat(1_700_000_000_000));

      final hb = decodeMessage(encoded) as Heartbeat;
      expect(hb.timestamp, 1_700_000_000_000);
    });
  });

  group('query_settlement 三型(破坏 envelope,按 tx 关联)', () {
    test('QuerySettlement 编码:顶层 tx,无 payload 包裹', () {
      final encoded = encodeMessage(const QuerySettlement('0xTxHash'));

      final wire = jsonDecode(encoded) as Map<String, dynamic>;
      expect(wire['type'], 'query_settlement');
      expect(wire['tx'], '0xTxHash');
      expect(wire.containsKey('payload'), isFalse,
          reason: 'query_settlement 把 tx 放在顶层,不在 payload 里');
    });

    test('QuerySettlementResult 解码:非 envelope,records 用 snake_case', () {
      final decoded = decodeMessage(jsonEncode({
        'type': 'query_settlement_result',
        'tx': '0xTxHash',
        'records': [
          {
            'request_id': 'req-1',
            'input_tokens': 100,
            'output_tokens': 50,
            'amount': 3,
            'processing_status': 'completed',
          }
        ],
      }));

      final res = decoded as QuerySettlementResult;
      expect(res.tx, '0xTxHash');
      expect(res.records.single.requestId, 'req-1');
      expect(res.records.single.inputTokens, 100);
      expect(res.records.single.outputTokens, 50);
      expect(res.records.single.amount, 3);
      expect(res.records.single.processingStatus, 'completed');
    });

    test('QuerySettlementError 解码:非 envelope,带 reason', () {
      final decoded = decodeMessage(jsonEncode({
        'type': 'query_settlement_error',
        'tx': '0xTxHash',
        'reason': 'not_found',
      }));

      final err = decoded as QuerySettlementError;
      expect(err.tx, '0xTxHash');
      expect(err.reason, 'not_found');
    });

    test('非 envelope 类型不被误当 envelope 解析(姊妹 03 的坑)', () {
      // query_settlement_result 没有 payload 字段。如果 decode 先无脑读 payload
      // 再按 type 派发,会拿不到 tx/records。此测试守住「先按 type 拦截」的顺序。
      final decoded = decodeMessage(jsonEncode({
        'type': 'query_settlement_result',
        'tx': '0xTxHash',
        'records': <Map<String, dynamic>>[],
      }));

      check(decoded is QuerySettlementResult);
      expect((decoded as QuerySettlementResult).tx, '0xTxHash');
    });
  });

  group('LLM 流式消息(02 提升:llm_request/cancel 入站,chunk/end/error 出站)', () {
    test('LlmRequestMessage 解码:requestId + request body + relaySignature', () {
      final decoded = decodeMessage(jsonEncode({
        'type': 'llm_request',
        'payload': {
          'requestId': 'req-1',
          'request': {
            'model': 'gpt-4o-mini',
            'messages': [
              {'role': 'user', 'content': 'hi'}
            ],
            'temperature': 0.5,
            'max_tokens': 256,
          },
          'relaySignature': '0xRelaySig',
        },
      }));
      check(decoded is LlmRequestMessage);
      final msg = decoded as LlmRequestMessage;
      expect(msg.requestId, 'req-1');
      expect(msg.relaySignature, '0xRelaySig');
      expect(msg.request.model, 'gpt-4o-mini');
      expect(msg.request.messages.single['content'], 'hi');
      // 已知字段(model/messages)不进 extra;其余(temperature/max_tokens)透传进 extra。
      expect(msg.request.extra['temperature'], 0.5);
      expect(msg.request.extra['max_tokens'], 256);
    });

    test('LlmRequest body 往返:extra 透传字段(tools/max_tokens)不丢', () {
      final body = LlmRequest(
        model: 'gpt-4o',
        messages: [
          {'role': 'user', 'content': 'hello'}
        ],
        extra: {
          'tools': [
            {'type': 'function'}
          ],
          'max_tokens': 100,
        },
      );
      final wire = body.toJson();
      expect(wire['model'], 'gpt-4o');
      expect((wire['messages'] as List).single['content'], 'hello');
      expect(wire['tools'], isNotEmpty); // 厂商字段透传
      expect(wire['max_tokens'], 100);
      // 回环:fromJson 再度分流已知/extra。
      final back = LlmRequest.fromJson(Map<String, dynamic>.from(wire));
      expect(back.model, 'gpt-4o');
      expect(back.extra['max_tokens'], 100);
      expect(back.extra['tools'], isNotEmpty);
    });

    test('LlmStreamCancelMessage 解码:reason 透传', () {
      final decoded = decodeMessage(jsonEncode({
        'type': 'llm_stream_cancel',
        'payload': {'requestId': 'req-1', 'reason': 'timeout'},
      })) as LlmStreamCancelMessage;
      expect(decoded.requestId, 'req-1');
      expect(decoded.reason, 'timeout');
    });

    test('LlmStreamChunkMessage 编码:payload.requestId + chunk(透传 choices/delta)', () {
      final encoded = encodeMessage(LlmStreamChunkMessage(
        requestId: 'req-1',
        chunk: LlmStreamChunk(
          id: 'chatcmpl-1',
          object: 'chat.completion.chunk',
          created: 1_700_000_000,
          model: 'gpt-4o-mini',
          choices: [
            {'index': 0, 'delta': {'content': 'Hel'}, 'finish_reason': null}
          ],
        ),
      ));
      final wire = jsonDecode(encoded) as Map<String, dynamic>;
      expect(wire['type'], 'llm_stream_chunk');
      final payload = wire['payload'] as Map<String, dynamic>;
      expect(payload['requestId'], 'req-1');
      final chunk = payload['chunk'] as Map<String, dynamic>;
      expect(chunk['object'], 'chat.completion.chunk');
      expect((chunk['choices'] as List).single['delta']['content'], 'Hel');
    });

    test('LlmStreamEndMessage 编码:usage 用 snake_case + providerSignature', () {
      final encoded = encodeMessage(LlmStreamEndMessage(
        requestId: 'req-1',
        usage: LlmUsage(promptTokens: 10, completionTokens: 5, totalTokens: 15),
        providerSignature: '',
      ));
      final wire = jsonDecode(encoded) as Map<String, dynamic>;
      expect(wire['type'], 'llm_stream_end');
      final payload = wire['payload'] as Map<String, dynamic>;
      expect(payload['requestId'], 'req-1');
      expect(payload['providerSignature'], '');
      final usage = payload['usage'] as Map<String, dynamic>;
      expect(usage['prompt_tokens'], 10);
      expect(usage['completion_tokens'], 5);
      expect(usage['total_tokens'], 15);
    });

    test('LlmErrorMessage 编码:requestId + code + message', () {
      final encoded = encodeMessage(const LlmErrorMessage(
        requestId: 'req-1',
        code: 'upstream_500',
        message: 'boom',
      ));
      final payload =
          (jsonDecode(encoded) as Map)['payload'] as Map<String, dynamic>;
      expect(payload['requestId'], 'req-1');
      expect(payload['code'], 'upstream_500');
      expect(payload['message'], 'boom');
    });

    test('入站信令不可 encode(provider 永不发送 llm_request/cancel)', () {
      expect(
        () => encodeMessage(const LlmStreamCancelMessage(requestId: 'x')),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('relay_log 反查(06:query_relay_records_by_tx_logindex + query_response)', () {
    test('QueryRelayRecordsByTxLogindex 编码:envelope,payload{requestId,tx,logindex 小写}', () {
      final encoded = encodeMessage(const QueryRelayRecordsByTxLogindex(
        requestId: 'q_1_abcd1234',
        tx: '0xTx',
        logindex: 7,
      ));
      final wire = jsonDecode(encoded) as Map<String, dynamic>;
      expect(wire['type'], 'query_relay_records_by_tx_logindex');
      final payload = wire['payload'] as Map<String, dynamic>;
      expect(payload['requestId'], 'q_1_abcd1234');
      expect(payload['tx'], '0xTx');
      expect(payload['logindex'], 7); // wire 小写 logindex,非 logIndex
    });

    test('QueryResponse 解码:data 为数组 → RelayRecord[](snake_case)', () {
      final decoded = decodeMessage(jsonEncode({
        'type': 'query_response',
        'payload': {
          'requestId': 'q_1_abcd1234',
          'ok': true,
          'data': [
            {'request_id': 'req-1', 'amount': 3},
            {'request_id': 'req-2', 'amount': 4},
          ],
        },
      })) as QueryResponse;
      expect(decoded.requestId, 'q_1_abcd1234');
      expect(decoded.ok, isTrue);
      expect(decoded.data, hasLength(2));
      expect(decoded.data[0]['request_id'], 'req-1');
      expect(decoded.data[1]['amount'], 4);
    });

    test('QueryResponse 解码:data 为 {records:[...]} 包裹 → 拆平', () {
      final decoded = decodeMessage(jsonEncode({
        'type': 'query_response',
        'payload': {
          'requestId': 'q_1',
          'ok': true,
          'data': {'records': [{'request_id': 'req-1'}]},
        },
      })) as QueryResponse;
      expect(decoded.data.single['request_id'], 'req-1');
    });

    test('QueryResponse 解码:ok=false 带 error,data 空', () {
      final decoded = decodeMessage(jsonEncode({
        'type': 'query_response',
        'payload': {'requestId': 'q_1', 'ok': false, 'error': 'internal'},
      })) as QueryResponse;
      expect(decoded.ok, isFalse);
      expect(decoded.error, 'internal');
      expect(decoded.data, isEmpty);
    });

    test('QueryResponse 入站不可 encode(provider 永不发送)', () {
      expect(
        () => encodeMessage(const QueryResponse(requestId: 'q_1', ok: true)),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('decode 健壮性', () {
    test('未知 type 解码为 UnknownRelayMessage,不崩溃', () {
      // query_response 已在 06 提升为具名 QueryResponse;用真正未知的 type 守兜底路径。
      final decoded = decodeMessage(jsonEncode({
        'type': 'some_future_type',
        'payload': {'foo': 'bar'},
      }));

      final unknown = decoded as UnknownRelayMessage;
      expect(unknown.type, 'some_future_type');
      expect(unknown.payload!['foo'], 'bar');
    });

    test('畸形 JSON 抛 FormatException(由调用方决定如何处理)', () {
      expect(() => decodeMessage('not-json'), throwsA(isA<FormatException>()));
    });
  });
}

/// 等价于 `expect(x, isA<T>())` 的轻量断言;失败信息更直白。
void check(bool ok) {
  if (!ok) {
    throw TestFailure('类型断言失败');
  }
}
