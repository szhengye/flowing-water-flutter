# 10 — 桌面常驻:系统托盘 + 单进程 keep-alive(04 split)

Type: task
Blocked by: (无;依赖 M0 桌面基线 + NodeService keepAlive 已就位)
Status: resolved (2026-08-09)

## Question

关窗最小化到系统托盘(macOS NSStatusItem / Windows 托盘图标),保持单进程常驻 —— 让桌面端成为真正的 always-on 供应商节点(CONTEXT.md 核心承诺)。移动端后台保活受限,仅桌面。

## Done looks like

- **托盘入口**:macOS 菜单栏图标 + 菜单(显示/退出);Windows 系统托盘图标 + 菜单。
- **关窗→托盘**:点关闭按钮拦截成最小化到托盘(不退出进程);托盘点击恢复窗口。
- **单实例**:防止启动第二个进程(同一供应商身份只能一条 WS 连中转站)。
- **显式退出**:托盘菜单退出 = 断 WS + dispose + 进程退出(区别于关窗)。

## Context

- 04 split(原「系统托盘驻留」块);姊妹 spike 05 已定桌面 only、移动整体延后。
- 候选插件:`tray_manager` + `window_manager`(关窗拦截);或自写 platform channel。需评估与 macOS entitlements(M0 已开 debug 出站 client)配合 —— 出站 WS entitlements 本就属 Fog。
- 上游 provider-server 是 Node 守护进程,无托盘参考 —— 净新增。
- NodeService 已 `keepAlive`(进后台即常驻),本票补 UI 层「关窗不死」。

## Answer

已实现 —— 桌面端成为 always-on 供应商节点(关窗不死 + 托盘显隐 + 单实例 + 干净退出)。
依赖 `window_manager ^0.5.2` + `tray_manager ^0.5.3`(leanflutter 标配,对 Dart 3.11.4 解析通过)。

**改动(外科:仅 macOS 1 原生文件 + Dart 接线):**
- **单实例(纯 Dart,双平台)** —— 新 `lib/core/desktop/desktop_lifecycle.dart`:
  `acquireSingleInstanceLock()` 在 `getApplicationSupportDirectory()/.flowing_water.lock` 上
  `RandomAccessFile.lockSync(FileLock.exclusive)`(非阻塞,对端已持 → 抛 FileSystemException → 返回 false)。
  纯 Dart(macOS flock / Windows LockFileEx,Dart 已封装)→ **零原生 mutex、零 network entitlement**,
  进程崩溃 OS 自动释放(无 stale 锁)。`evaluateSingleInstance({acquireLock})` 把判定与副作用分开 → 可单测。
  二启:main 检测 `alreadyRunning` → `stderr.writeln` + `exit(0)`(命中用户选的「二启即退出」)。
  **此机制同时覆盖 Windows(原计划延后的 named-mutex 不再需要 —— 无原生代码即消除不可验证风险)。**
- **托盘 + 关窗拦截** —— `DesktopTrayController`(implements `WindowListener` + `TrayListener`):
  `windowManager.setPreventClose(true)` + `onWindowClose → hide()`(关窗=隐到托盘);
  `trayManager.setIcon('assets/icon/tray_icon.png', isTemplate:true)` + 菜单 `显示窗口 / 退出`;
  `onTrayIconMouseDown → show()`(左键恢复);`onTrayMenuItemClick` 按 key 分发。
  **macOS 原生** `AppDelegate.swift`:`applicationShouldTerminateAfterLastWindowClosed` → **`false`**
  (Flutter 默认 true 会让关窗即退出,与常驻冲突)+ `applicationShouldHandleReopen`(Dock 点击恢复隐窗)。
  **Windows / entitlements / Info.plist:零改动。**
- **干净退出** —— 托盘「退出」→ `quit()`:`container.dispose()`(同步触发 NodeService.onDispose:
  `_client?.dispose()` 断 WS + DB close + watcher 释放)→ `exit(0)`。区别于关窗(关窗=隐)。
- **main.dart 重构** —— `WidgetsFlutterBinding.ensureInitialized()` → 单实例守卫 → `ProviderContainer()` +
  `UncontrolledProviderScope`(持有 container 以便退出 dispose)+ `_tray.init(container)`(顶层 `_tray` 保活 listener)。
- **资产** —— `assets/icon/tray_icon.png`(32×32 黑圆模板图,占位可换)+ pubspec `flutter.assets` 声明。

**关键决策:**
- 单实例用文件锁而非 named-mutex/loopback:纯 Dart 跨平台、无 entitlement、无端口冲突、OS 释放 stale 锁。
- 持有 `ProviderContainer`(UncontrolledProviderScope)而非默认 ProviderScope —— 才能在托盘退出时 dispose
  (NodeService/DB/watcher 全链释放)。
- 仅 macOS AppDelegate 1 行原生;Windows 零原生(关窗靠 window_manager,单实例靠 file-lock)。

**验证(Rule 12:如实标注硬限制):**
- `flutter pub get` 解析 ✓(window_manager 0.5.2 / tray_manager 0.5.3)。
- `flutter analyze`:lib+test **零 issue**(56 个 info 全在 `spikes/` 预存噪声)。
- `flutter test`:全量 **219 绿**(+2:单实例判定逻辑 [取到→proceed / 已持→alreadyRunning 绝不 proceed];
  跨进程锁行为不可单测 → 注入伪 acquireLock 只测判定意图)。
- `flutter build macos`:**✓ 编译通过**(`flowing_water.app` 52.9MB;AppDelegate 改动 + 新插件 pod 干净集成;
  警告全来自 vendored sqlite3 pod 预存 C 代码,无关)。

**硬限制(必说):** 托盘渲染 / 关窗拦截 / 二启拦截 / Cmd+Q 行为属**原生 GUI,本 headless 环境无法运行时验证** ——
只能保证「编译 + 静态分析 + 单实例锁逻辑」。**用户手动核验(macOS 必做):** `flutter run -d macos` →
① 托盘图标出现;② 点关闭按钮 → 窗口隐(`ps`/活动监视器确认进程仍在);③ 托盘左键 → 窗口恢复;
④ 托盘菜单「退出」→ 进程退出;⑤ 再起一个实例 → 「已在运行」+ 退出。
**Windows(另机)** 同 ①–⑤(单实例已由 file-lock 覆盖,无 native mutex)。
**已知 polish(列 Fog):** `preventClose` 下 Cmd+Q 可能也变隐(而非退出)—— 若偏差作后续;WS 关闭可能非优雅
close frame(exit 立即回收 socket,relay 见断开,可接受)。
