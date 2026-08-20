import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// 单实例判定结果。
enum SingleInstanceDecision { proceed, alreadyRunning }

/// 取得单实例锁则 [SingleInstanceDecision.proceed];否则(另一实例已持有)
/// [SingleInstanceDecision.alreadyRunning] → 调用方应提示并退出。
///
/// **为什么锁**:同一供应商身份只能一条 WS 连中转站(CONTEXT.md),必须防多进程。
/// **为什么这样测**:跨进程文件锁行为不可单测 —— 故把「取锁」注入,只测判定逻辑
/// (锁未取到 ⇒ 必为已运行 ⇒ 不可 proceed)。
Future<SingleInstanceDecision> evaluateSingleInstance({
  required Future<bool> Function() acquireLock,
}) async {
  return await acquireLock()
      ? SingleInstanceDecision.proceed
      : SingleInstanceDecision.alreadyRunning;
}

/// 进程级持有的单实例锁 fd(不释放 = 进程存活;进程退出 OS 自动释放,无 stale 锁)。
/// 写入后不再读取 —— 其职责是被静态字段持有保活(锁 fd 不被 GC 关闭),故 ignore 未读。
// ignore: unused_element
RandomAccessFile? _heldLock;

/// 真实单实例锁:沙盒容器内 `.flowing_water.lock` 排他锁。
/// `FileLock.exclusive` 非阻塞(对端已持 → 抛 [FileSystemException])。
/// 纯 Dart,跨平台(macOS flock / Windows LockFileEx,Dart 已封装),零原生/零 entitlement。
Future<bool> acquireSingleInstanceLock() async {
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, '.flowing_water.lock'));
  try {
    final raf = file.openSync(mode: FileMode.append);
    raf.lockSync(FileLock.exclusive);
    _heldLock = raf;
    return true;
  } on FileSystemException {
    return false; // 已被另一实例持有
  }
}

/// 桌面常驻编排(10):关窗→隐托盘 / 托盘单击→显 / 托盘菜单 显示·退出 /
/// 退出=干净停机(container.dispose 触发 NodeService 断 WS + DB 关 + watcher 释放)→ exit。
///
/// 实现 [WindowListener] + [TrayListener];由 main 持有(顶层引用)保活回调。
class DesktopTrayController with WindowListener, TrayListener {
  ProviderContainer? _container;

  Future<void> init(ProviderContainer container) async {
    _container = container;
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    trayManager.addListener(this);
    // 关窗拦截:由 onWindowClose 改成 hide(不退出进程)。
    await windowManager.setPreventClose(true);
    await _buildTray();
  }

  Future<void> _buildTray() async {
    await trayManager.setIcon(
      'assets/icon/tray_icon.png',
      isTemplate: true, // macOS 模板图:黑白自适 menubar 明暗
    );
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'show', label: '显示窗口'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: '退出'),
    ]));
  }

  /// 关窗按钮 → 隐到托盘(macOS 配 AppDelegate 关最后窗不终止)。
  @override
  void onWindowClose() => windowManager.hide();

  /// 托盘左键单击 → 恢复窗口。
  @override
  void onTrayIconMouseDown() => showWindow();

  /// 托盘菜单回调:按 key 分发(右键点出菜单后点条目)。
  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        showWindow();
      case 'quit':
        quit();
    }
  }

  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  /// 托盘「退出」:尽力释放容器(NodeService/DB/watcher 的 onDispose,dispose 同步触发)
  /// 后退出进程。区别于关窗(关窗=隐,此=真退出)。
  void quit() {
    try {
      _container?.dispose();
    } catch (_) {
      // 退出前尽力释放;释放失败也不阻塞退出(OS 回收 fd,SQLite WAL crash-safe)。
    }
    exit(0);
  }
}
