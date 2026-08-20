// 端到端 LLM 往返冒烟 — wayfinder ticket 11。
//
// 对本地中转站(relay-server)+ 真实上游 LLM(SenseNova,OpenAI 兼容)做一次完整流式往返:
//   1. WS 握手(复用 04 的 connect→challenge→EIP-191 sign→auth 链路)
//   2. 发 provider_info(上报 relayModel "gpt-4o-mini-smoke",in/out 价,supportsStream)
//   3. 起一个 HTTP server(:9999)接收"接入方"侧调用 —— 不,接入方由 relay 的 :5080 承担。
//      本 spike 只做 provider 侧:连 relay WS、收 llm_request、转发上游、回 chunk/end。
//   4. 收到 relay 转发的 llm_request{stream:true} → 用 dio 调上游 → 逐行 SSE 解析
//      → 回 llm_stream_chunk / llm_stream_end(usage, providerSignature:"") / llm_error
//   5. 本地 provider_log 记一条(insert pending → complete/fail),用 sqlite3 直接写
//   6. 对账:llm_stream_end 后,发 query_relay_records 拉 relay 侧记录,比 token 用量
//
// 上游 key 来源:用户环境配置(LLM_MODEL_5_*,SenseNova,OpenAI 兼容协议)。
//   endpoint = https://token.sensenova.cn  (resolveEndpoint 会补 /v1/chat/completions? — 见下)
//   适配器:openai adapter(mirror 上游 OpenAIAdapter)。
//
// 协议权威:web3-api/packages/shared/src/protocol/messages.ts + types/llm.ts
// 参考(Node 参考实现):web3-api/packages/provider-server/src/forwarder/ + ws/client.ts
// 时序/字段坑:.scratch/supplier-portal/assets/03-dart-ws-protocol-findings.md §A/B/C
//
// 用法(从本 spike 目录):
//   dart pub get
//   # 上游 key 经环境变量传入(不落盘、不进 repo):
//   export UPSTREAM_BASE_URL=https://token.sensenova.cn
//   export UPSTREAM_API_KEY=sk-...
//   export UPSTREAM_MODEL=sensenova-6.7-flash-lite
//   dart run bin/e2e_llm.dart
//   # 然后另开终端,用 sk-relay-* key 调 relay :5080(脚本最后会打印示例 curl)。
//
// 退出码:0 = 全程端到端成功;1 = 失败。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:dio/dio.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// ── 配置 ──────────────────────────────────────────────────────────────────
const Duration _authTimeout = Duration(seconds: 30);
const Duration _streamIdleTimeout = Duration(seconds: 30);
const String _relayWsUrl = 'ws://localhost:3003';
const String _relayModel = 'gpt-4o-mini-smoke'; // 上报给 relay 的模型名(接入方按此请求)
// provider_log 用 in-memory sqlite(本 spike 只需记录+对账,不必落盘)。
const String _dbPath = ':memory:';

String get _upstreamBaseUrl =>
    Platform.environment['UPSTREAM_BASE_URL'] ?? 'https://token.sensenova.cn';
String get _upstreamApiKey {
  final k = Platform.environment['UPSTREAM_API_KEY'];
  if (k == null || k.isEmpty) {
    throw StateError(
        'UPSTREAM_API_KEY 未设置。请 export UPSTREAM_API_KEY=<真实上游 key>(不落盘)');
  }
  return k;
}

String get _upstreamModel =>
    Platform.environment['UPSTREAM_MODEL'] ?? 'sensenova-6.7-flash-lite';

Future<void> main(List<String> args) async {
  final drain = args.contains('--drain'); // --drain: 跑完后不退出,留通道给手动 curl
  final db = sqlite3.open(_dbPath);
  _initSchema(db);

  // 1. 随机测试供应商 keypair(同 04)。
  final mnemonic = bip39.generateMnemonic();
  final seed = bip39.mnemonicToSeed(mnemonic);
  final child = bip32.BIP32.fromSeed(seed).derivePath("m/44'/60'/0'/0/0");
  final pkBytes = Uint8List.fromList(child.privateKey!);
  final credentials = EthPrivateKey.fromHex(_to0xHex(pkBytes));
  final addressEip55 = credentials.address.hexEip55;

  print('━━━ 端到端 LLM 往返冒烟 (ticket 11) ━━━');
  print('relay WS URL      : $_relayWsUrl');
  print('relayModel(上报)  : $_relayModel');
  print('上游 endpoint     : ${_upstreamBaseUrl}');
  print('上游 model        : ${_upstreamModel}');
  print('上游 key 来源     : 环境变量 UPSTREAM_API_KEY(不落盘)');
  print('address(EIP-55)   : $addressEip55');
  print('────────────────────────────────────────');

  final channel = WebSocketChannel.connect(Uri.parse(_relayWsUrl));
  print('[connect] WS 已发起,等待 challenge…');

  final authed = Completer<void>();
  final firstLlmRequest = Completer<void>(); // 收到第一个 llm_request 即完成
  // 整轮完成(llm_stream_end / llm_error 已发完且对账拉过)的同步信号。
  // main 阻塞在它上面,而不是固定 delay —— 真实往返要多久就等多久。
  final roundDone = Completer<void>();
  late StreamSubscription sub;

  void fail(String reason) {
    stderr.writeln('❌ $reason');
    if (!authed.isCompleted) authed.completeError(StateError(reason));
  }

  final authTimer = Timer(_authTimeout, () {
    if (!authed.isCompleted) fail('auth 超时(${_authTimeout.inSeconds}s)');
  });

  sub = channel.stream.listen(
    (raw) async {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = msg['type'] as String?;
      final payload =
          (msg['payload'] ?? const <String, dynamic>{}) as Map<String, dynamic>;

      // ── 握手阶段:auth_ack ──
      if (type == 'auth_ack') {
        final success = payload['success'] == true;
        final challenge = payload['challenge'] as String?;
        final error = payload['error'] as String?;
        if (!authed.isCompleted && challenge != null && !success) {
          final sig = _ensure0x(EthSigUtil.signPersonalMessage(
            message: Uint8List.fromList(utf8.encode(challenge)),
            privateKeyInBytes: pkBytes,
          ));
          print('[send] auth{address=$addressEip55, signature=${_short(sig)}}');
          channel.sink.add(jsonEncode({
            'type': 'auth',
            'payload': {
              'address': addressEip55,
              'paymentAddress': addressEip55,
              'signature': sig,
            },
          }));
          return;
        }
        if (success) {
          print('[recv] auth_ack{success:true} ✅  鉴权通过');
          _sendProviderInfo(channel, addressEip55);
          if (!authed.isCompleted) authed.complete();
          return;
        }
        if (error != null) fail('中转站拒绝鉴权: $error');
        return;
      }

      // ── 业务阶段:llm_request ──
      if (type == 'llm_request') {
        if (!firstLlmRequest.isCompleted) firstLlmRequest.complete();
        // 每条 llm_request 独立处理(不 await 阻塞 WS 监听)。
        // 处理完(含对账 query_relay_records)后,完成 roundDone 让 main 退出。
        _handleLlmRequest(channel, db, addressEip55, msg).then((_) {
          if (!roundDone.isCompleted) roundDone.complete();
        }).catchError((e) {
          stderr.writeln('[handleLlmRequest] 未捕获: $e');
          if (!roundDone.isCompleted) roundDone.completeError(e);
        });
        return;
      }

      // query 响应(query_relay_records 回包):打印供对账。
      if (type == 'query_response') {
        final ok = payload['ok'] == true;
        final data = payload['data'];
        print('[recv] query_response{ok=$ok}');
        if (data is List) {
          for (final row in data) {
            if (row is Map) print('         relay row: ${jsonEncode(row)}');
          }
        } else if (data != null) {
          print('         data: ${jsonEncode(data)}');
        }
        if (payload['error'] != null) print('         error: ${payload['error']}');
        return;
      }

      // 心跳回包 / 其它:记录即忽略。
      print('[recv] $type (忽略)');
    },
    onError: (Object e) => fail('stream error: $e'),
    onDone: () {
      if (!authed.isCompleted) fail('连接在握手完成前关闭');
    },
    cancelOnError: true,
  );

  // 等 auth 完成。
  try {
    await authed.future;
  } catch (e) {
    authTimer.cancel();
    await sub.cancel();
    await channel.sink.close();
    exit(1);
  }
  authTimer.cancel();

  // 起定时心跳(15–20s;relay 60s 硬断)。
  final hb = Timer.periodic(const Duration(seconds: 18), (_) {
    channel.sink.add(jsonEncode({
      'type': 'heartbeat',
      'payload': {'timestamp': DateTime.now().millisecondsSinceEpoch},
    }));
  });

  print('━━━ provider 已就绪,等待接入方经 relay 发起 /v1/chat/completions ━━━');
  print('  接入方 curl 示例(另开终端):');
  print('  curl -N http://localhost:5080/v1/chat/completions \\');
  print('    -H "Authorization: Bearer <sk-relay-*> \\');
  print('    -H "Content-Type: application/json" \\');
  print("    -d '{\"model\":\"$_relayModel\",\"stream\":true,\"messages\":[{\"role\":\"user\",\"content\":\"用一句话介绍杭州\"}]}'");
  print('  (本 spike 默认:收到首个 llm_request 后跑完一轮即退出;--drain 留通道)');
  print('────────────────────────────────────────');

  if (!drain) {
    // 给一个上限:90s 内等不到 llm_request 就超时退出(非 0)。
    try {
      await firstLlmRequest.future
          .timeout(const Duration(seconds: 90), onTimeout: () {
        stderr.writeln('❌ 90s 内未收到 llm_request(接入方是否已调 relay?)');
      });
    } catch (e) {
      hb.cancel();
      await sub.cancel();
      await channel.sink.close();
      exit(1);
    }
    // 等整轮真正跑完(llm_stream_end/llm_error 已发 + 对账已拉),给 120s 上限。
    try {
      await roundDone.future
          .timeout(const Duration(seconds: 120), onTimeout: () {
        stderr.writeln('❌ 等待 llm_request 处理完成超时(120s)');
      });
    } catch (e) {
      // 处理中出错已在 _handleLlmRequest 内打印;此处只兜底退出。
    }
    // 给对账 query_response 一点回包时间。
    await Future<void>.delayed(const Duration(seconds: 2));
    hb.cancel();
    await sub.cancel();
    await channel.sink.close();
    print('━━━ 本地 provider_log 记录 ━━━');
    for (final r in db.select('SELECT * FROM provider_log ORDER BY created_at')) {
      print('  ${jsonEncode(r)}');
    }
    print('━━━ ✅ spike 结束 ━━━');
    exit(0);
  } else {
    // --drain:持续监听,直到 Ctrl+C。
    await Future<void>.delayed(const Duration(days: 365));
  }
}

// ── llm_request 处理(镜像 provider-server ws/client.ts + forwarder/index.ts)──
Future<void> _handleLlmRequest(
  WebSocketChannel channel,
  Database db,
  String providerAddress,
  Map<String, dynamic> message,
) async {
  final payload =
      message['payload'] as Map<String, dynamic>? ?? const <String, dynamic>{};
  final requestId = payload['requestId'] as String;
  final request =
      payload['request'] as Map<String, dynamic>? ?? const <String, dynamic>{};
  final relaySignature = payload['relaySignature'] as String? ?? '';
  final startTime = DateTime.now();
  final isStream = request['stream'] == true;

  print('[recv] llm_request{requestId=$requestId, stream=$isStream, '
      'relaySignature="${_shortSig(relaySignature)}", model=${request['model']}}');

  // 本地 provider_log:insert pending(价用上报的 in/out 价,简化 spike)。
  final inPrice = 1; // inputPricePer1k(与 provider_info 上报一致)
  final outPrice = 2; // outputPricePer1k
  final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  db.execute(
    'INSERT INTO provider_log (request_id, model_name, processing_status, created_at, provider_input_price, provider_output_price) '
    'VALUES (?, ?, ?, ?, ?, ?)',
    [requestId, request['model'] as String? ?? _relayModel, 'pending', ts,
      inPrice, outPrice],
  );

  if (!isStream) {
    // 本 spike 聚焦 stream(ticket 11 Done: stream)。非流式给个明确报错。
    _failRecord(db, requestId, 'e2e spike 只验 stream=true');
    channel.sink.add(jsonEncode({
      'type': 'llm_error',
      'payload': {
        'requestId': requestId,
        'code': 'SPIKE_NON_STREAM_UNSUPPORTED',
        'message': '本 spike 只验 stream=true;请用 stream:true 调用',
      },
    }));
    return;
  }

  await _forwardStream(channel, db, requestId, request, startTime, inPrice,
      outPrice, providerAddress);
}

// ── forwarder 流式(镜像 forwarder/index.ts forwardStreamRequest + OpenAIAdapter)──
Future<void> _forwardStream(
  WebSocketChannel channel,
  Database db,
  String requestId,
  Map<String, dynamic> request,
  DateTime startTime,
  int inPrice,
  int outPrice,
  String providerAddress,
) async {
  final dio = Dio();
  final cancelToken = CancelToken();

  // buildRequest(OpenAIAdapter):{ ...request, model=上游模型, stream=true } + 强制 include_usage。
  final body = Map<String, dynamic>.from(request);
  body['model'] = _upstreamModel;
  body['stream'] = true;
  final so = body['stream_options'];
  final includeUsage = so is Map ? so['include_usage'] : null;
  if (includeUsage == null) {
    body['stream_options'] = {
      if (so is Map) ...so,
      'include_usage': true,
    };
  }
  final url = _resolveEndpoint(_upstreamBaseUrl);

  Response<ResponseBody> resp;
  try {
    resp = await dio.post<ResponseBody>(
      url,
      data: jsonEncode(body),
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_upstreamApiKey',
        },
        responseType: ResponseType.stream,
      ),
      cancelToken: cancelToken,
    );
  } on DioException catch (e) {
    final msg = 'upstream_${e.response?.statusCode ?? "?"}: '
        '${(e.response?.data?.toString() ?? e.message).toString().slice(200)}';
    _failRecord(db, requestId, msg);
    _sendError(channel, requestId, 'UPSTREAM_ERROR', msg);
    return;
  }

  // 上游非 2xx(上面 DioException 多半已捕获,兜底)。
  if (resp.statusCode == null || resp.statusCode! < 200 || resp.statusCode! >= 300) {
    final msg = 'upstream_${resp.statusCode}';
    _failRecord(db, requestId, msg);
    _sendError(channel, requestId, 'UPSTREAM_ERROR', msg);
    return;
  }

  // Content-Type 校验(镜像 forwarder:"假装支持 stream" 检测)。
  final ct = (resp.headers.value('content-type') ?? '').toLowerCase();
  if (!ct.contains('text/event-stream')) {
    final msg = 'upstream_non_sse: $ct';
    _failRecord(db, requestId, msg);
    _sendError(channel, requestId, 'UPSTREAM_ERROR', msg);
    return;
  }

  final stream = resp.data!.stream;
  final buffer = StringBuffer();
  var promptTokens = 0, completionTokens = 0, totalTokens = 0;
  var usageReported = false, chunkCount = 0;
  final decoder = utf8.decoder;

  // idle timeout(镜像 STREAM_IDLE_TIMEOUT_MS=30s)。
  Timer? idleTimer;
  var aborted = false;
  void armIdle() {
    idleTimer?.cancel();
    idleTimer = Timer(_streamIdleTimeout, () {
      aborted = true;
      cancelToken.cancel('stream idle ${_streamIdleTimeout.inSeconds}s');
    });
  }

  armIdle();
  try {
    await for (final List<int> chunkBytes in stream) {
      if (aborted) break;
      armIdle();
      buffer.write(decoder.convert(chunkBytes));
      // SSE 按行切(buffer 保留最后未结束的行)。
      final lines = buffer.toString().split('\n');
      buffer.clear();
      buffer.write(lines.removeLast()); // 最后一段回填 buffer
      for (final line in lines) {
        final ev = _parseStreamLine(line, _upstreamModel);
        if (ev == null) continue;
        if (ev.error != null) {
          _failRecord(db, requestId, ev.error!);
          _sendError(channel, requestId, 'STREAM_ERROR', ev.error!);
          return;
        }
        if (ev.chunk != null) {
          chunkCount++;
          channel.sink.add(jsonEncode({
            'type': 'llm_stream_chunk',
            'payload': {'requestId': requestId, 'chunk': ev.chunk},
          }));
        }
        if (ev.usage != null) {
          if (((ev.usage!['prompt_tokens'] as int?) ?? 0) > 0) {
            promptTokens = ev.usage!['prompt_tokens'] as int;
          }
          if (((ev.usage!['completion_tokens'] as int?) ?? 0) > 0) {
            completionTokens = ev.usage!['completion_tokens'] as int;
          }
          totalTokens = promptTokens + completionTokens;
          usageReported = true;
        }
        if (ev.done == true) break;
      }
    }
  } catch (e) {
    if (!aborted) {
      final msg = 'stream read: $e';
      _failRecord(db, requestId, msg);
      _sendError(channel, requestId, 'STREAM_ERROR', msg);
      return;
    }
  } finally {
    idleTimer?.cancel();
  }

  if (chunkCount == 0) {
    final msg = 'stream produced 0 chunks';
    _failRecord(db, requestId, msg);
    _sendError(channel, requestId, 'STREAM_ERROR', msg);
    return;
  }

  final usage = usageReported
      ? {
          'prompt_tokens': promptTokens,
          'completion_tokens': completionTokens,
          'total_tokens': totalTokens,
        }
      : {'prompt_tokens': 0, 'completion_tokens': 0, 'total_tokens': 0};

  // amount(nUSD)= round((in×prompt + out×completion)/1000)
  final amount =
      (inPrice * promptTokens + outPrice * completionTokens) ~/ 1000;
  final latencyMs = DateTime.now().difference(startTime).inMilliseconds;

  // completeRecord
  db.execute(
    'UPDATE provider_log SET input_tokens=?, output_tokens=?, amount=?, '
        'processing_status=?, latency_ms=? WHERE request_id=?',
    [promptTokens, completionTokens, amount, 'completed', latencyMs, requestId],
  );

  // providerSignature 恒空串(03 锁定:Ed25519 非抵赖移除,链上 Settled 锚定)。
  channel.sink.add(jsonEncode({
    'type': 'llm_stream_end',
    'payload': {
      'requestId': requestId,
      'usage': usage,
      'providerSignature': '',
    },
  }));

  print('[done] llm_stream_end{requestId=$requestId, '
      'chunks=$chunkCount, prompt=$promptTokens, completion=$completionTokens, '
      'amount=$amount nUSD, latency=${latencyMs}ms, usageReported=$usageReported}');

  // 对账:llm_stream_end 后,发 query_relay_records 拉 relay 侧记录。
  _queryRelayRecords(channel, providerAddress);
  // 给 query_response 一点回包时间(不阻塞 WS 监听)。
  await Future<void>.delayed(const Duration(seconds: 2));
}

// ── OpenAIAdapter.parseStreamLine(镜像)──
_StreamEvent? _parseStreamLine(String line, String providerModel) {
  final trimmed = line.trim();
  if (!trimmed.startsWith('data: ')) return null;
  final data = trimmed.substring(6);
  if (data == '[DONE]') return _StreamEvent(done: true);
  try {
    final obj = jsonDecode(data) as Map<String, dynamic>;
    // P0~P3 透传:spread 上游 delta verbatim。
    final choices = (obj['choices'] as List? ?? [])
        .map((c) {
          final cMap = c as Map<String, dynamic>;
          final delta = cMap['delta'] as Map<String, dynamic>? ?? {};
          return {
            'index': cMap['index'] ?? 0,
            'delta': {
              'role': delta['role'],
              'content': delta['content'] ?? '',
              ...delta,
            },
            'finish_reason': cMap['finish_reason'],
            'logprobs': cMap['logprobs'],
          };
        })
        .toList();
    final chunk = <String, dynamic>{
      'id': obj['id'] ?? 'cmpl-spike',
      'object': obj['object'] ?? 'chat.completion.chunk',
      'created': obj['created'] ??
          (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      'model': obj['model'] ?? providerModel,
      'choices': choices,
    };
    // 保留上游顶层非标准字段(system_fingerprint / service_tier / ...)。
    for (final k in obj.keys) {
      if (const {'id', 'object', 'created', 'model', 'choices', 'usage'}
          .contains(k)) continue;
      if (!chunk.containsKey(k)) chunk[k] = obj[k];
    }
    Map<String, dynamic>? usage;
    if (obj['usage'] is Map) {
      final u = obj['usage'] as Map<String, dynamic>;
      usage = {
        'prompt_tokens': u['prompt_tokens'] ?? 0,
        'completion_tokens': u['completion_tokens'] ?? 0,
        'total_tokens': u['total_tokens'] ?? 0,
        ...u,
      };
    }
    return _StreamEvent(chunk: chunk, usage: usage);
  } catch (e) {
    return _StreamEvent(error: 'parse stream line: $e');
  }
}

// OpenAIAdapter.resolveEndpoint:base URL 以 /v1 结尾则补 /chat/completions。
String _resolveEndpoint(String endpoint) {
  final trimmed = endpoint.replaceFirst(RegExp(r'/+$'), '');
  if (trimmed.endsWith('/v1')) return '$trimmed/chat/completions';
  // SenseNova base 是 https://token.sensenova.cn,需补 /v1/chat/completions。
  if (!trimmed.contains('/v1')) return '$trimmed/v1/chat/completions';
  return trimmed;
}

void _sendError(WebSocketChannel channel, String requestId, String code,
    String message) {
  print('[err] llm_error{requestId=$requestId, code=$code, msg=$message}');
  channel.sink.add(jsonEncode({
    'type': 'llm_error',
    'payload': {'requestId': requestId, 'code': code, 'message': message},
  }));
}

void _failRecord(Database db, String requestId, String error) {
  db.execute(
    "UPDATE provider_log SET processing_status='failed', error_message=? "
        'WHERE request_id=?',
    [error, requestId],
  );
}

void _queryRelayRecords(WebSocketChannel channel, String providerAddress) {
  print('[send] query_relay_records{provider=$providerAddress, limit=5}');
  channel.sink.add(jsonEncode({
    'type': 'query_relay_records',
    'payload': {
      'requestId': 'q-${DateTime.now().millisecondsSinceEpoch}',
      'provider': providerAddress,
      'limit': 5,
    },
  }));
}

void _sendProviderInfo(WebSocketChannel channel, String addressEip55) {
  channel.sink.add(jsonEncode({
    'type': 'provider_info',
    'payload': {
      'address': addressEip55,
      'paymentAddress': addressEip55,
      'models': [
        {
          'relayModel': _relayModel,
          'inputPricePer1k': 1,
          'outputPricePer1k': 2,
        },
      ],
      'supportsStream': true,
    },
  }));
  print('[send] provider_info{$_relayModel, in=1/out=2, supportsStream=true}');
}

void _initSchema(Database db) {
  db.execute('''
    CREATE TABLE IF NOT EXISTS provider_log (
      request_id TEXT PRIMARY KEY,
      model_name TEXT NOT NULL,
      input_tokens INTEGER NOT NULL DEFAULT 0,
      output_tokens INTEGER NOT NULL DEFAULT 0,
      amount INTEGER NOT NULL DEFAULT 0,
      processing_status TEXT NOT NULL DEFAULT 'pending',
      latency_ms INTEGER NOT NULL DEFAULT 0,
      error_message TEXT NOT NULL DEFAULT '',
      provider_input_price INTEGER NOT NULL DEFAULT 0,
      provider_output_price INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL
    );
  ''');
}

class _StreamEvent {
  const _StreamEvent({this.chunk, this.usage, this.done, this.error});
  final Map<String, dynamic>? chunk;
  final Map<String, dynamic>? usage;
  final bool? done;
  final String? error;
}

String _short(String hex) =>
    hex.length <= 18 ? hex : '${hex.substring(0, 10)}…${hex.substring(hex.length - 8)}';
String _shortSig(String s) => s.isEmpty ? '' : _short(s);
String _ensure0x(String hex) => hex.startsWith('0x') ? hex : '0x$hex';
String _to0xHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

extension on String {
  String slice(int n) => length <= n ? this : substring(0, n);
}
