# 11 — friendlyError + 本地日志 + 国际化骨架(04 split)

Type: task
Blocked by: (无;横切基础设施)
Status: friendlyError + 本地日志 resolved; i18n → Fog (2026-08-09)

## Question

三类横切基础设施的**骨架**(非全功能):把裸异常/技术错误翻译成供应商可读的 friendlyError;一个轻量本地日志骨架(节点排障);国际化骨架(当前全中文硬编码,留 ARB 切换入口)。

## Done looks like

- **friendlyError**:借 listening-king `error_utils` 模式 —— 统一把 WS / 链 / forwarder 异常映射成 {标题, 可读说明, 是否可重试};现有 SnackBar / 空态 / 门禁文案改用它。
- **本地日志骨架**:轻量 logger(分级 debug/info/warn/error + 落盘轮转),关键路径(WS 相位 / 对账 / forwarder 失败)接上;不引重型框架。
- **i18n 骨架**:`flutter_localizations` + 一个 ARB(中文默认),把页面文案抽到 ARB;英文翻译留 Fog。

## Context

- 04 split(原「friendlyError + 本地日志骨架 + 国际化骨架」块)。
- listening-king `error_utils` 参考模式;视觉 token 已就位(AppColors 语义色)。
- 后端可观测性体系(告警 / 日志聚合)是远期 Fog;v1 仅本地日志 + UI 节点健康面板(04 已交付)。

## Answer

11 三块骨架,本会话实现 **friendlyError + 本地日志骨架**;**i18n 骨架** 经 Rule 2 评估留 Fog(zh-only 产品,i18n 脚手架投机,且需引 `flutter_localizations` + gen-l10n codegen;英文本就是 Fog)。

**代码**:
- `lib/core/errors/friendly_error.dart`(新)—— `String friendlyError(Object e)`,借 listening-king `error_utils` 模式,适配本域:`DioException` 按型分类(timeout/connectionError → 网络;badResponse → 透传服务端 `error`/`message` → 5xx → 429 → 状态码;cancel)+ `RelayQueryException` → 中转站请求失败 + 兜底去 `Exception:` 前缀。
- `lib/core/log/node_logger.dart`(新)—— `NodeLogger`(debug/info/warn/error + `minLevel` 过滤 + `emit` 注入可测)+ 全局 `nodeLog` 单例。debug 走 `debugPrint`,release 走落盘(1 MiB → `node.log.1` 单份轮转,同步 append);`init()` 预热 release 文件路径(debug no-op)。**不引重型框架**。
- `lib/main.dart` —— 加 `WidgetsFlutterBinding.ensureInitialized()` + `await nodeLog.init()`。**注**:10 会话同期重写 main.dart(单实例守卫 + `DesktopTrayController` + `ProviderContainer`),本票仅插入 import + init 行,未动其结构。
- **接线关键路径**:ws_client `_setPhase`(WS 相位)/ chain_watcher_service + providers 的 `[chain-syncer]`·`[unmatched-retry]` log 回调(对账)/ forwarder `stream_read_failed` catch / node_service `syncModels` 静默 catch(→ warn)。
- **friendlyError 应用**:settings「重试失败」/ settlements「同步失败」/ keypair 生成·恢复·解锁 5 处 `catch (e)` 的 `$e` → `friendlyError(e)`,不再把 `DioException`/堆栈抛给供应商。

**关键决策(Rule 2/7 surface)**:
1. **friendlyError 用 String 形态**(镜像 listening-king),非 ticket 所述 `{标题,说明,可重试}` 三字段 —— 现有调用点(SnackBar / 表单错误)只消费 String,且无重试 UI;三字段 + retryable 在无重试动作时是投机。三字段 / 重试动作待真有重试 UI 毕业成 ticket(留 Fog)。
2. **i18n 骨架留 Fog**(Rule 2):产品 zh-only,英文是 Fog;i18n 脚手架对当前是投机。待真有第二语言需求毕业。
3. **logger 全局单例**(非 Riverpod):核心层(ws_client / forwarder)不持 ref,单例 `nodeLog` 任何地方直用。
4. **落盘用同步 append**:节点日志低频(相位切换 + 偶发失败),同步 `writeAsStringSync` 可接受;高吞吐场景才需 async / 隔离 isolate(远期)。

**测试**(本票 +13):friendlyError 9(Dio 各型 / badResponse 透传服务端 / RelayQuery / 兜底去前缀)+ NodeLogger 4(minLevel 过滤 / 默认 info·debug 被滤 / error 附异常 / ISO 时间戳行格式)。全量 **232 测试绿**(含并行 10 桌面托盘测试),lib+test analyze 干净。

**留尾(Fog)**:i18n 骨架(zh-only 投机);friendlyError 三字段 / 重试动作(待重试 UI);落盘 async/隔离 + 日志查看页(远期,并入「可观测性后端」fog)。
