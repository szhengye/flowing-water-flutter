import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/desktop/desktop_lifecycle.dart';
import 'core/log/node_logger.dart';

/// 顶层引用:保活 [DesktopTrayController] 的 window/tray listener 回调(防 GC 回收)。
final DesktopTrayController _tray = DesktopTrayController();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await nodeLog.init(); // release 预热落盘文件(debug no-op → 走 debugPrint)

  // 单实例守卫(10):同一供应商身份只能一条 WS 连中转站 → 第二个进程即退出。
  final decision = await evaluateSingleInstance(
    acquireLock: acquireSingleInstanceLock,
  );
  if (decision == SingleInstanceDecision.alreadyRunning) {
    stderr.writeln('流水供应商已在运行,本次启动退出。');
    exit(0);
  }

  // 持有 container,以便托盘「退出」时干净 dispose
  // (NodeService 断 WS + AppDatabase 关 + ChainWatcher 释放)。
  final container = ProviderContainer();
  await _tray.init(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FlowingWaterApp(),
    ),
  );
}
