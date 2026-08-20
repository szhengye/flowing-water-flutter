# 05 — 应用架构与状态管理

Type: grilling
Status: resolved
Blocked by: 03

## Question

应用架构怎么定?逐项决策(用 /grilling 一问一答):

1. **状态管理**:Provider(沿 listening-king)vs Riverpod vs Bloc——本 app 比 listening-king 复杂(实时 WS + 流式转发 + always-on)。
2. **路由**:go_router(深链 / 鉴权守卫 / 嵌套)vs 手动 Navigator。
3. **节点逻辑 vs GUI 分离**:always-on 的 WS + forwarder 跑在**后台 isolate / 服务**,还是与 GUI 同 isolate?移动端后台保活怎么处理(关联 Fog)?——此项依赖 03(WS 能否独立 isolate 运行)。
4. **目录结构**:feature-first vs layer-first。
5. **惯例**:错误处理 / loading / 流式状态 / 单元测试注入(listening-king 的 service 单例 + forTest 模式)。

## Context

- listening-king 参考:`lib/providers/player_controller.dart`(stream-bridge)、`lib/services/api_client.dart`(service 单例 + 拦截器)、`lib/widgets/macos/desktop_scaffold.dart`(桌面 shell)。
- 本 app 是 always-on 节点 + GUI,比 listening-king(消费级,偶发同步)重得多。

## Done looks like

一组架构决策(每项带理由)+ 骨架目录约定。用 /grilling 逐项问清楚,不要拍脑袋。

## Answer

经 /grilling 逐项敲定(flowing-water-flutter 为全新空仓,listening-king 仅作隔壁参考,Rule 11 不约束选型)。**全部决策仅定桌面端(macOS + Windows);移动端延后**——这是本 ticket 的明确 scope 裁定,Fog「移动端后台保活」因此保持原状(推迟,不毕业)。

### 决策集(每项带理由)

**1. 状态管理 → Riverpod**(非 listening-king 的 Provider)。
- 理由:Provider 同作者的现代继任;**自带 DI**(无需 get_it)→ 干净替代 listening-king 脆弱的 `forTest` 缝;**`AsyncValue`** 统一 loading/error/data → 直接填 listening-king 缺口;**override** 机制做测试注入;细粒度重建适合高频流式 chunk。连接状态机用 `Notifier` + enum 表达。心智成本:Provider→Riverpod 迁移低。

**2. 路由 → go_router**(非手动 Navigator)。
- 理由:**`StatefulShellRoute`** 天然支撑「侧栏 shell + 嵌套标签」(替代 listening-king 手搓的 `_tabPageStacks`);**`redirect`** 声明式做鉴权守卫(未注册/未登录/节点未鉴权 → 重定向引导);可深链、可测。屏幕增多不乱。嵌套 shell + 守卫本就是刚需,非镀金。

**3. 节点逻辑 vs GUI → 托盘驻留单进程 / 节点跑主 isolate / 仅桌面**。
- 进程边界:**单进程托盘驻留**——关窗缩系统托盘不退出,进程继续跑节点。契合「单供应商·单 app 实例」「桌面为真常驻节点」,复杂度中等(多数 Flutter 桌面常驻工具做法),避开了独立 daemon 双进程 + IPC 的过重方案。
- isolate 边界:**主 isolate**——`web_socket_channel`/`dio`/`web3dart` 全 async I/O 不卡 UI,EIP-191 签名 sub-ms;唯一 jank 风险是大 `llm_request` JSON(可达 MB 级)→ 用 `compute()` 卸载。单供应商节点负载不大,简单优先(Rule 2),profile 出问题再升级独立 isolate。状态无需跨 isolate,利好 #1/#5。
- 移动端:**整体延后**,不在本架构内。同一供应商身份 = 单 WS 连接(03 实证),双设备同当服务节点必冲突,且 iOS 后台 WS 不可能——故移动端不当服务节点(细节推迟)。

**4. 目录结构 → feature-first + `core/` + `shared/`**(非 layer-first)。
- 理由:`lib/features/<功能>/` 就地共处 widget/provider/service,Riverpod provider 与功能共处;横切基础设施(WS/forwarder/链上/crypto/storage)隔离在 `lib/core/`;设计 token + 通用 widget 在 `lib/shared/`。多功能扩展好、导航与所有权清晰。layer-first 随功能增多会把一个功能的代码撒进多目录。listening-king 的「4 套平台页面重复」维护负担因仅做桌面而消失。

**5. 惯例**:
- **loading/error** → Riverpod `AsyncValue<T>`(`.when(data/loading/error)`)。
- **测试注入** → Riverpod `overrideWith` / `ProviderContainer(overrides:)`,替代 `forTest`。
- **用户态错误文案** → 移植 listening-king `friendlyError()` 到 `shared/utils/`(网络错误 → 友好文案)。
- **节点生命周期与监督 → 鉴权驱动 + supervisor**:`NodeService` = Riverpod `keepAlive` provider;生命周期绑鉴权状态(注册/登录完成且 provider 就绪后自启,登出停);内置 supervisor(事件循环异常自动重启带退避);**连接态对外暴露为显式状态机**(errors-as-state,永不冒泡到 UI 当异常)。状态机 enum:`{ stopped, connecting, authenticating, connected, reconnecting, failed }`(`authenticating` 涵盖收 challenge→发 auth→等 ack;03 握手时序)。

### 骨架目录约定

```
lib/
  main.dart                # 入口: ProviderScope, 托盘初始化, 平台分发
  app.dart                 # MaterialApp.router + GoRouter 装配
  router.dart              # GoRouter: redirect 鉴权守卫 + StatefulShellRoute 桌面 shell
  core/                    # 横切基础设施(always-on 引擎,非 UI)
    node/                  #   NodeService(keepAlive)+ 生命周期 + supervisor
      node_service.dart
      node_status.dart     #   连接状态机 enum
    ws/                    #   中转站 WS 客户端(03 方案): RelayClient + sealed RelayMessage
    forwarder/             #   forwarder + 5 adapter(见 09)
    chain/                 #   web3dart 链上监听/结算/转账(见 02)
    crypto/                #   助记词/keypair/AES-256-GCM(见 01/10)
    storage/               #   本地持久化(选型见 06)
    net/                   #   dio + interceptors
  features/                # feature-first UI + 就地 state
    registration/          #   首次注册/助记词生成(只展示一次)
    auth/                  #   登录/解锁(助记词或密钥)
    dashboard/             #   节点状态/连接态/概览
    forwarding/            #   在飞请求/转发日志/流式
    settlement/            #   链上结算对账
    models_mgmt/           #   模型清单/报价管理(provider_info)
    settings/              #   设置/密钥管理
  shared/
    widgets/               #   通用 widget
    design/                #   设计 token / theme(借 listening-king token 体系,自定专业后台风)
    utils/                 #   friendlyError() 等
```

### 下游影响
- **解锁 09**(forwarder 架构)的架构上下文:forwarder 落 `core/forwarder/`,与 `core/ws/` 的 `RelayClient` 在主 isolate 内通过 Riverpod provider 接入。
- **11(端到端 LLM 往返)** 原本 blocked by 05+09,现仅余 09。
- Fog「移动端后台保活策略」「迁移割接与行为对齐验证」仍依赖本架构已定的桌面基线 + 后续功能成型,保持原状。
