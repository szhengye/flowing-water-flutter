#!/usr/bin/env bash
# e2e customer 驱动 —— 腿 4(真实往返)+ 腿 5(计费落库)。
# 打 relay OpenAI 兼容端点,流式拉一次 llm_request,经 supplier-app forwarder→真 LLM。
#
# 用法:
#   API_KEY=sk-relay-xxx MODEL=<relayModel> RELAY_OPENAI_URL=http://localhost:8080/v1/chat/completions \
#     bash customer-request.sh
#
# 前置(见 14 runbook):relay-server 已起、supplier-app 已连+鉴权+provider_info 上报含 MODEL、
# 已用 /admin/api-keys 造好 customer key。MODEL 必须是 supplier 在 app Models 页注册的 relayModel。

set -euo pipefail

API_KEY="${API_KEY:?需要 API_KEY=sk-relay-... (admin /admin/api-keys 生成)}"
MODEL="${MODEL:?需要 MODEL = supplier 在 Models 页注册的 relayModel}"
RELAY_OPENAI_URL="${RELAY_OPENAI_URL:-http://localhost:8080/v1/chat/completions}"

echo "→ POST $RELAY_OPENAI_URL  model=$MODEL  stream=true"
echo

# --no-buffer 让流式 chunk 实时打到终端,验证 llm_stream_chunk×N → llm_stream_end。
curl -sN --no-buffer \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -X POST "$RELAY_OPENAI_URL" \
  -d "{
    \"model\": \"$MODEL\",
    \"stream\": true,
    \"messages\": [
      {\"role\": \"user\", \"content\": \"用一句话解释什么是 WebSocket 长连接。\"}
    ]
  }"

echo
echo "← 流结束。验收:"
echo "  腿 4:上面应看到逐块 SSE data: {...} 流式输出,末尾收尾(非空、完整)。"
echo "  腿 5:supplier-app 的 Records 页应出现一行 completed;DB provider_log 有 amount nUSD。"
