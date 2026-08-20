# relay 启动 runbook — ticket 04 握手冒烟

> 目标:在本地以最小配置启动 `web3-api/packages/relay-server`,使 WS 端口(`:3003`)
> 可达,然后用 `spikes/ws-handshake/dart-spike` 跑通一次完整握手。
>
> 本 runbook 只起 relay 本地业务、**不部署合约、不加载 operator keypair**——
> 空合约地址下 relay 跳过链上调用(`config.ts` 全 env 有默认值),WS 握手不需要它们。
> 所有命令从 `flowing-water-flutter` 仓库根执行。

## 0. 前置

- `node` ≥ 22、`pnpm` 9.x(本机已具备:v25.8.1 / 9.15.0)。
- `dart` 在 PATH(本机:`~/flutter/bin/dart`)。
- `../web3-api` 存在。

## 1. 安装依赖 + 构建(仅 shared + relay-server)

> 不用 `pnpm -r build`:它会顺带构建两个 Next.js portal,缺 `NEXT_PUBLIC_*` 会失败。
> 握手只需要 `@web3-api/shared` + `relay-server`。

```bash
cd ../web3-api
pnpm install                                   # 首次约 2–5 min
pnpm --filter ./packages/shared build          # tsc → dist/
pnpm --filter ./packages/relay-server build    # tsc → dist/index.js
```

## 2. 写最小 `.env`(WS 在 :3003,空合约)

```bash
cd packages/relay-server
cat > .env <<'EOF'
RELAY_OPENAI_PORT=5080
RELAY_ADMIN_PORT=3000
RELAY_WS_PORT=3003
ADMIN_API_KEY=dev-smoke-key
POLYGON_RPC_URL=https://polygon-amoy.drpc.org
POLYGON_CONTRACT_ADDRESS=0x0000000000000000000000000000000000000000
POLYGON_USDT_ADDRESS=0x0000000000000000000000000000000000000000
SETTLE_MIN_AMOUNT_USDT=0
MATIC_BALANCE_LOW_NOISE=1
EOF
```

- `POLYGON_CONTRACT_ADDRESS=0x0…0` → relay 跳过链上调用,只做本地业务(含 WS 握手)。
- 不需要 operator 助记词/keypair(那只在 settle / setWsUrl 时用)。

## 3. 启动 relay(前台,看日志)

```bash
# 仍在 packages/relay-server
node --env-file=.env dist/index.js
```

看到三个端口就绪(OpenAI `:5080` / Admin `:3000` / WS `:3003`)即成功。
**另开一个终端**做下面的验证。

## 4. 验证 relay 已起

```bash
curl -s http://localhost:3000/health
# 期望: {"status":"ok", ...}
```

## 5. 跑 Dart 握手冒烟

```bash
cd <flowing-water-flutter>/spikes/ws-handshake/dart-spike
dart pub get
dart run bin/handshake.dart                  # 默认 ws://localhost:3003
```

期望结尾:`✅ 握手成功 — connect → challenge → EIP-191 sign → auth → auth_ack{success:true}`
退出码 0。

## 6. 收尾

- relay 终端 `Ctrl+C` 停止。
- `.env` 是本地配置,勿提交(若仓库纳入 git,确认 `.gitignore` 覆盖)。
