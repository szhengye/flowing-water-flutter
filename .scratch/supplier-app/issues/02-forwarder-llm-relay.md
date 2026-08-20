# 02 — Forwarder(LLM 中转)

Type: task
Blocked by: 01
Status: resolved (2026-08-08)

## Question

端到端 LLM 流式中转打通并计费(核心收入链路):relay `llm_request{stream}` → adapter → 上游 → 流式 `llm_stream_chunk` × N → `llm_stream_end{usage}` 回 relay;本地 `provider_log` 记一条并计费。

## Done looks like

- **StreamDispatcher**(Riverpod,持 `Map<requestId, CancelToken>`):`llm_stream_cancel`→`cancel()`→dio 中止→onError(不回 error);WS 断开 → `abortAll()`。
- **5 adapter**(三方法 `buildRequest`/`parseResponse`/`parseStreamLine`,逐调用新实例;Anthropic 带 per-stream `openToolUses`;DeepSeek/Azure 委托 OpenAI)。
- **dio 流式管线**:`ResponseType.stream` + SSE 逐行(Gemini 走 JSON 流分支)+ 30s 空闲 `Timer` + Content-Type 校验(必含 `text/event-stream`,Gemini 例外)。
- **provider_log 插桩**(dispatcher 层):insert 时 `processing_status=pending` + 价快照 → complete `amount=round((in×prompt+out×completion)/1000)` nUSD → fail `error_message`。`providerSignature` 恒 `""`。
- **Providers 页**:vendor CRUD + Hi 连通性测试 + endpoint 自动探测候选[进阶]。
- **Models 页**:relay_model↔vendor/model/price CRUD + 报送 `provider_info` + `sync-model-params` + 反拉报价覆盖本地[进阶]。

## Context

- 依赖 01(`llm_request` 收发)。
- forwarder 架构见姊妹 `../supplier-portal/issues/09-forwarder-adapter-architecture.md`;端到端验证参照 `11-e2e-llm-roundtrip-smoke.md`(对真实 relay + SenseNova 流式往返 + 对账)。
- 逐 adapter 移植 Node `../web3-api` 的 `forwarder/adapters/*.ts`(dio 替 fetch;verbatim 透传非标准字段如 `reasoning`/`role:null`)。
- provider_log schema 已在 M0 drift 定义(`lib/core/db/tables.dart`)。

## Progress

**2026-08-08 会话 — 核心纵切落地(未 resolve,02 仍开放):** LLM 流式中转主干打通 —

- **协议层提升** `relay/messages.dart`:LLM 5 型(LlmRequest/LlmStreamChunk/LlmUsage 数据类[强类型核心+extra 透传] + LlmRequestMessage/LlmStreamCancelMessage 入站 + LlmStreamChunkMessage/LlmStreamEndMessage/LlmErrorMessage 出站),encode/decode 分支齐。
- **adapter(5 型全就绪)** `forwarder/adapters/{types,openai,deepseek,azure_openai,anthropic,gemini,factory}.dart`:ProviderAdapter 抽象 + 5 适配器逐行移植 web3-api —— OpenAI 系(OpenAI/DeepSeek/Azure:resolveEndpoint/stream_options 注入/delta 透传,DeepSeek 委托、Azure 仅覆写 buildRequest)、Anthropic(per-stream openToolUses 状态 + 事件流 message_start/content_block_*/message_delta/stop + thinking_delta→reasoning_content)、Gemini(JSON 流非 SSE + OpenAI messages→contents 转换 + systemInstruction)。factory makeAdapter 全型就绪。
- **forwarder 管线** `forwarder/{forwarder,stream_http,model_mapping}.dart`:dio 流式经**可注入 StreamHttpFn** + SSE 逐行 + 30s idle Timer + Content-Type 校验 + usage 累积(取最后>0)+ 0-chunk/onError/abort 语义。
- **计费** `db/provider_log_dao.dart`(insert pending+时点价 / complete 落 amount=round((in×prompt+out×completion)/1000) / fail)+ mapping(relayModel→vendor+providerModel+时点价)。
- **dispatcher+接线** `forwarder/stream_dispatcher.dart`(handleLlmRequest/handleStreamCancel/abortAll + 计费插桩 + relay 回吐,providerSignature 恒空)+ node_service inbound 接线 + phase 断连 abortAll。
- **Providers 页** `features/providers/providers_screen.dart` + `db/vendor_dao.dart` + `vendor_probe.dart`:vendor CRUD(列表/新增/编辑/删除 + watch)+ **连通性测试**(复用 forwarder 路径:adapter.buildRequest minimal 流式 + 验 200/SSE)+ `/providers` 路由。
- **Models 页** `features/models/models_screen.dart` + `db/quotation_dao.dart`:provider_quotation CRUD(relayModel/providerModel/vendor/prices)+ CRUD 后即时 `node_service.reportProviderInfo` 重报 + `/models` 路由。
- **测试** 139 绿(新增 90),lib+test analyze 干净(spikes/ 预存不动)。

## Answer

**核心收入链路打通并计费(02 主问题已答)** —— 端到端:relay `llm_request` → StreamDispatcher → forwarder(5 adapter 之一)→ 上游流式 → `llm_stream_chunk`×N → `llm_stream_end{usage}` + provider_log 计费(insert pending+时点价 → complete 落 `amount=round((in×prompt+out×completion)/1000)` nUSD / fail)。`providerSignature` 恒空(01:结算锚链上)。Providers/Models 页 CRUD + 连通性测试 + provider_info 即时重报联动。139 测试绿。

**未做(非 02 forwarder 核心,毕业后续;见 map Fog)**:
- Models sync-model-params / 反拉报价:依赖 WS `query_model_params` / relay API —— 属 03/04 的 query 型消息范畴,跨 ticket。
- Providers endpoint 自动探测候选(web3-api endpoint-probe.ts 候选 URL 反推),更进阶。
- 真实 e2e 往返由姊妹 11(需 LLM API key + relay operator 触发 settle)。
