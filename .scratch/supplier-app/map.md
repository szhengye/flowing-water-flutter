# Map — 流水供应商 App 实现 (flowing-water-flutter)

> wayfinder map。本文件是**索引,不是存储**——决策细节只活在它的 ticket 里,这里只 gist + 链接。开放 ticket 不在此列出,靠查 `issues/` 找。

## Notes

- **本 effort 性质**:产品**实现**(非 spike)。Flutter 桌面 app 完全替换 `../web3-api` 的 provider-server(Node)+ provider-portal(Next.js)。一个 app 实例 = 一个供应商节点 = 一个管理后台。
- **历史**:由 plan `~/.claude/plans/cosmic-giggling-raven.md` 发起,M0/M1 已实现;现转 wayfinder map 管理(plan 降级为历史参考)。
- **每次会话先读**:`../../CONTEXT.md`(领域)、本 map、`../../docs/agents/*.md`(跟踪约定)。基础可行性决议见姊妹 spike map `../supplier-portal/map.md` 与其 01–11 ticket。
- **已建架构基线(M0)**:Riverpod + go_router(`StatefulShellRoute`)+ drift(10 表 1:1 对齐 Node schema)+ feature-first(`lib/{core,features,shared,routing}`)+ 设计 token(C 骨架 208px 侧栏 + 蓝 `#2563EB` accent + light)+ macOS/Windows 桌面 + AppConfig(env + 网络选择器)。
- **身份密钥基线(M1)**:`lib/core/crypto/`(bip39 助记词生成/校验 + bip32 `m/44'/60'/0'/0/0` 派生 + EIP-191 签名 eth_sig_util + AES-256-GCM pointycastle + Keychain flutter_secure_storage)+ `identityControllerProvider`(none/locked/unlocked 门禁,errors-as-state)+ Keypair 页(生成/恢复/解锁 + 首次 setup 强制)。web3dart 锁 `^2.7.3`。
- **web3dart 版本决策(链 ticket 共用,2026-08-08)**:保持 `^2.7.3` —— 链 API(events/getLogs/socketConnector/FilterEvent/getBalance)在 2.7.3 源码核实已具备且形态一致;升 3.x 级联 pointycastle 4.x 冲突 M1 AES,无增益。决策见 [03](issues/03-chain-settlement-reconcile.md) Version decision。
- **运行时必须保留**:WS 到 relay + LLM 中转 + 链上结算对账(姊妹 spike 03/04/09/11 已验证)。
- **安全**:上游 LLM key 经 env 传入**不落盘**;永不复用 ANTHROPIC_* 凭据;助记词永不持久化明文。
- **运行约定**:本地 markdown 跟踪器,本 effort 在 `.scratch/supplier-app/`;ticket = `issues/NN-<slug>.md`,`Type:` / `Blocked by:` 在文件头,`Status:` 记 `claimed`/`resolved`(开放 ticket 无 `Status:`)。**一个会话最多 resolve 一个 ticket。**

## Decisions so far

<!-- M0/M1 为已实现基线(非 ticket,详情见 Notes);本 effort ticket 决议将在此累积。 -->

- **M0 工程脚手架 + 架构地基**(基线,非 ticket)— 见 Notes「已建架构基线」。代码 `lib/{core,features,shared,routing}`,`flutter analyze` 干净,app 可起。
- **M1 身份与密钥**(基线,非 ticket)— 见 Notes「身份密钥基线」。`lib/core/crypto/` + Keypair 页 + 身份门禁已落地。
- [**01 WS 客户端 + 节点核心**](issues/01-ws-client-node-core.md) — relay WS 节点落地:`lib/core/relay/`(协议层 18 型 sealed + `query_settlement` 非 envelope 特判 / ws_client 握手·心跳·full-jitter 重连 / NodeService 6 态状态机 + 身份门禁 + keepAlive)+ Settings 可观测面板。全量 49 测试绿。网络运行时切换 + 可编辑 RPC 被依赖门控(见 Fog)。解除 02/03 阻塞。
- [**02 Forwarder(LLM 中转)**](issues/02-forwarder-llm-relay.md) — 核心收入链路打通:`llm_request`→5 adapter→流式 `llm_stream_chunk`×N→`llm_stream_end{usage}` + provider_log 计费(`amount=round((in×prompt+out×completion)/1000)` nUSD);协议层 LLM 5 型 / dio 流式管线(可注入 StreamHttpFn + 30s idle)/ dispatcher 接线 + 断连 abortAll;Providers/Models 页 CRUD + 连通性测试 + provider_info 即时重报。139 测试。`providerSignature` 恒空。sync/反拉(跨 03/04 query)+ e2e(11)留 Fog。
- [**05 链上事件监听 + backfill**](issues/05-chain-event-watcher-backfill.md) — PolygonEventWatcher(`events()` WS 订阅 + socketConnector + getLogs 分页 + full-jitter 重连)+ 三层 floor backfill(cursor/deploy/window,全程成功才推进)+ Settled 解码 + 幂等采集到 provider_chain_settlement。21 测试绿,lib+test analyze 干净。drift schema 零迁移(三表已在 M0)。**03 拆 05/06/07**;app 生命周期接线留 Fog。web3dart 保持 2.7.3(见 03 Version decision)。
- [**08 链监听 app 接线**](issues/08-chain-watcher-app-wiring.md) — `ChainWatcherService`(镜像 NodeService:identity unlocked+配置齐全 → 起 watcher;locked/缺配置 → 停/disabled)+ `chainClientFactoryProvider`(可注入)+ AppShell 状态卡链监听行;watcher 加 `onPhase` 相位回调 + 幂等 dispose。3 服务测试,全量 163 绿。**watcher 现随 app 跑**(dev 无配置 → disabled)。
- [**06 链上结算对账**](issues/06-chain-reconcile.md) — Settled 经 WS `query_relay_records_by_tx_logindex`(requestId 关联)反查 relay_log → 强制 `chain_status=on_chain_settled` + settle_tx + log_index 回填 provider_log;零匹配/未连接/重试耗尽 → unmatched;5×2s 重试,**无 ±时间窗**。新增 query 两型 + ws_client 请求/响应关联 + `SettleEventSyncer` + unmatched DAO;provider_log 加 log_index 列(drift v2,**打破 1:1 对齐上游**——上游建表缺这列,潜伏 bug,见 Fog)。operator retry-all → 09。177 测试。
- [**07 链上读 + Settlements/Wallet 页**](issues/07-chain-reads-pages.md) — `ChainClient` 端口扩 `getBalance`(MATIC)+ `getTokenBalance`(USDT balanceOf 最小 ABI);`PolygonscanClient`(Etherscan V2 txlist/tokentx);watcher `sync({full})`(= 上游 `/sync-chain-status` 全量重扫:重置 cursor→floor-1 再 backfill);两页:Settlements(stream watchAll + tx 筛选 + 全量同步[按链监听门禁] + 行→关联流水)+ Wallet(余额 + matic/usdt 交易历史 + USDT→关联流水);`getBySettleTx` 关联流水 sheet 双入口;路由 `/settlements`/`/wallet` 接真页。**Rule 7**:端口 getBalance 非"已具备"(扩展);chainid 固 137;[进阶] 延后(手动对账冗余/未匹配重试→09)。198 测试。**解除 04 阻塞**。
- [**04 Dashboard / Records(+ 收尾 split)**](issues/04-dashboard-records-finish.md) — Dashboard(`/` 占位→真实:4 KPI[总调用/完成率/计费额 nUSD/平均延迟] + 节点健康卡 + 链上汇总 + 模型明细 + 周期 24h/7d/30d/累计)+ Records(`provider_log` 处理状态/链态双维度筛选只读列表)+ TopBar「Connected · Xms」pill 接**心跳 RTT**(WsClient 加 `latency`,发-收时刻差)+ 状态映射共享(`status_visuals.dart`)。provider_log DAO 加 `watchRecords`/`watchRecordsSince`/纯函数 `computeLlmMetrics`(计费额/用量只算 completed,完成率=completed/total)。聚合收益按 nUSD/1e9 显示 USDT(镜像上游 `formatNusd`)。209 测试(+11)。**收尾 split**:桌面托盘 keep-alive→10、错误友好/日志/i18n 骨架→11;e2e 割接 + 厂商汇总 / 告警[进阶]→Fog。
- [**09 unmatched operator 手动重试**](issues/09-unmatched-operator-retry.md) — operator 一键重试 06 落地的 unmatched Settled(对齐上游 retry-all):`UnmatchedSettledEventDao` 补 `list`/`watchAll`/`count`/`remove`/`recordRetry`(**零 schema 变更**,retryCount/lastRetryAt 列 06 已声明)+ 新 `UnmatchedRetryService`(`waitForConnected` 轮询 relay client supplier[对齐上游 20s,超时→整体跳过**不盲重试**]+ 内部构造 `SettleEventSyncer`[operator/watcher **共用对账原语**,非共享实例]+ 行→`SettledEventArgs` 重建;命中→`remove`,仍 0→`recordRetry`)+ Settings 新区(count 徽标 + 列表 + 「重试全部」[`connected` 门禁,未连禁用])。217 测试(+8)。e2e 承 05/06/07 Polygon 配置卡点。
- [**10 桌面常驻:托盘 + 关窗拦截 + 单实例 + 干净退出**](issues/10-desktop-tray-keepalive.md) — 关窗不死(常驻供应商节点):`window_manager`/`tray_manager`(0.5.2/0.5.3)+ 新 `lib/core/desktop/desktop_lifecycle.dart`(`DesktopTrayController`:preventClose→hide / 托盘左键→show / 菜单 显示·退出 / 退出=`container.dispose()`[触发 NodeService 断 WS+DB 关+watcher 释放]→`exit`)+ **单实例纯 Dart 文件锁**(`RandomAccessFile.lockSync(FileLock.exclusive)` on `.flowing_water.lock`,双平台零原生零 entitlement,二启即退出)+ main 持 `ProviderContainer`(`UncontrolledProviderScope`)+ macOS `AppDelegate.applicationShouldTerminateAfterLastWindowClosed=false`(**唯一原生改动**;Windows/entitlements 零改)。219 测试(+2 单实例判定逻辑)。**编译验证 `flutter build macos` ✓**;**原生 GUI 行为(托盘/关窗/二启/Cmd+Q)未运行时验证 → 用户手动核验**(见票 + Fog)。
- [**11 friendlyError + 本地日志骨架**](issues/11-error-log-i18n-scaffold.md) — `String friendlyError(Object e)`(借 listening-king `error_utils`,适配本域:DioException 各型 / `RelayQueryException` / 兜底去前缀)+ `NodeLogger`(分级 + minLevel 过滤 + `emit` 注入可测;debug → `debugPrint` / release → 落盘 1 MiB 单份轮转;全局 `nodeLog` 单例)+ main `init()`。接线 ws 相位 / 对账 log 回调 / forwarder 失败 / syncModels;settings·settlements·keypair 5 处 `catch $e`→friendlyError。**Rule 2**:String 形态(非 ticket 三字段,无重试 UI 不投机);i18n 骨架留 Fog(zh-only 投机 + gen-l10n codegen)。本票 +13 测试,全量 232 绿(含并行 10)。
- [**12 Dashboard 厂商维度汇总**](issues/12-dashboard-vendor-breakdown.md) — Dashboard「厂商明细」面板(从 04 Fog 毕业):`QuotationDao.relayModelToVendorMap()`(quotation join vendor,providerId→vendorId)+ 纯函数 `computeVendorBreakdown(rows, map)`(按厂商聚合 completed 收益/调用,未映射归「未知」,倒序;同 computeLlmMetrics 口径)+ `dashboardVendorBreakdownProvider`(`async*` 先取 map 再 map 行流)+ `_VendorBreakdownCard`(USDT /1e9)。完成 04 Done-list「厂商汇总」。+3 测试 → 235 绿。告警[进阶] 仍在 Fog。
- [**13 全链路 e2e 验证 + 割接形状**](issues/13-e2e-cutover.md) — grilling(从 Fog 毕业):定 e2e = **全本地 Amoy、Tier 1+2、真 LLM**(relay-server 兄弟仓本地起 → 你即 operator,消解 operator 依赖)。**割接硬规则(代码级)**:必须**先彻底停旧 provider-server**(确认 relay 日志 `Provider disconnected: <A>`)再起新 app;反过来致死——`removeByWs(oldWs)` 用未清的 `byWs[oldWs]=A` 删 `providers[A]`,停旧会删掉刚覆盖成的新条目,新 app 静默脱池不重连(`web3-api relay-server src/ws/{server,connection-pool}.ts`)。身份=助记词可移植,crypto 互通 = 新 app 同助记词过 SIWE/EIP-191 鉴权。产出配置 checklist(3 组件)+ 9 腿连续验收(identity→WS 鉴权→provider_info→真实往返→计费→手动 settle→采集→对账→页面)+ 已知限制(Wallet Etherscan tx 历史 Amoy 取不到 / backfill 冷启动需 `POLYGON_DEPLOY_BLOCK` / 合约预注资 / WS 端口 :3003 vs :4000)。**实跑 → 14(task,开放,frontier)**;Settings 网络切换(Amoy Etherscan chainid)仍在 Fog。

## Fog

<!-- 看得见但还说不精确的决策/调查;能精确成问题时就毕业成 ticket -->

- **02 进阶(未做,sync/反拉/探测/e2e)** — Models `sync-model-params`(向 relay 查模型参数)+ 反拉报价覆盖:依赖 WS `query_model_params` / relay API,属 03/04 的 query 型消息范畴(现归 UnknownRelayMessage),待 03/04 的 query 消息落地后毕业。Providers endpoint 自动探测候选(web3-api endpoint-probe.ts 候选 URL 反推)。e2e 真实往返由姊妹 11(需 LLM API key)。
- **告警[进阶](04)** — 失败率告警 / Dashboard 低余额告警[进阶] 未做(数据齐,缺阈值/通道)。厂商汇总已落地(12,quotation→vendor join);nUSD→USDT 换算已应用(/1e9,镜像 portal `formatNusd`,`NUSD_PER_USDT=1e9`)。
- **移动端** — 姊妹 05 已定桌面 only,移动整体延后(AppShell 有响应式视觉占位、无逻辑)。远期。
- **暗色模式** — 姊妹 08 定 light 默认,暗色延后(A terminal 色板作蓝本)。远期。
- **打包/签名/entitlements** — macOS/Windows 代码签名、出站 WS entitlements(M0 已开 debug client)。远期。
- **可观测性后端** — 告警/日志聚合体系;v1 仅 UI 节点健康面板(04 已交付)+ 本地日志骨架(11 已交付,落盘 `node.log`)+ 日志查看页。远期。
- **i18n 骨架(11 split)+ friendlyError 三字段/重试** — i18n 需 flutter_localizations + gen-l10n + zh.arb;zh-only 产品投机(Rule 2),待第二语言需求毕业。friendlyError 现为 String 形态(镜像 listening-king);三字段 {标题,说明,可重试} + 重试 SnackBar 动作待真有重试 UI 时毕业。
- **Settings 网络运行时切换 + 可编辑 RPC** — 被 mainnet/testnet relay URL(合约 `wsUrl()`)+ M4 Polygon RPC 门控;01 暂只读展示。依赖就绪后毕业成 ticket。
- **链 backfill 冷启动代价(Alchemy 免费层)** — Amoy smoke(08)实测 `eth_getLogs` **10 块/请求**上限;watcher `page=10` 正确,但 72h window(129,600 块)冷 backfill ≈ 12,960 请求,免费层极慢/限流。真实部署需 `POLYGON_DEPLOY_BLOCK`(贴近当前)或 PAYG/dedicated RPC;或减小 `recentWindowHours`。06/07 真跑通前定。
- **provider_log log_index 上游分叉(06)** — 上游 syncer 写 log_index,但其 provider_log 建表**无此列**(潜伏 bug,链上 0 Settled 未触发);本仓 drift v2 **补了列**(忠实 syncer 意图),暂偏离 tables.dart 的"1:1 对齐上游 schema"声明。待上游补列后回归对齐(决策见 [06](issues/06-chain-reconcile.md) 关键决策 2)。
- **链上读 / Etherscan 真实往返未验(07)** — getBalance/balanceOf + Etherscan txlist/tokentx 已实现(端口/纯解析有单测),但 dev 无 Polygon 配置 → 未端到端;真跑需 `POLYGON_RPC_URL`+`POLYGON_USDT_ADDRESS`+`POLYGONSCAN_API_KEY` + 身份 unlocked(承 05/06 的 operator-settle e2e 卡点)。MATIC/USDT 转账(发币)上游无参考、净新增,未做(若做需重评 web3dart 版本,见 03)。
- **Amoy testnet Etherscan chainid(07)** — `PolygonscanClient` chainid 固 137(mainnet);Amoy(80002)交易历史待 Settings 网络运行时切换 ticket(与下条「Settings 网络门控」同批毕业)。
- **桌面常驻运行时验证 + Cmd+Q polish(10)** — 10 已编译验证(`flutter build macos` ✓)但托盘渲染/关窗拦截/二启拦截属原生 GUI,headless 未运行时验证 → **需用户 `flutter run -d macos` 手动核验**(清单见 [10](issues/10-desktop-tray-keepalive.md) Answer)。已知 polish:`preventClose` 下 Cmd+Q 可能也变隐(而非退出)—— 若偏差需区分关窗 vs Cmd+Q(如监听 app 终止或加退出菜单快捷键);WS 退出可能非优雅 close frame(exit 立即回收 socket,relay 见断开,可接受)。Windows 同需另机手验(单实例已由 file-lock 覆盖,无 native mutex)。
