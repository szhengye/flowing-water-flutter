import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 日志级别(11 本地日志骨架)。
enum LogLevel { debug, info, warn, error }

/// 轻量节点日志:分级 + `debugPrint`(debug 模式)/ 落盘轮转(release 模式)。
///
/// 关键路径(WS 相位 / 链上对账 / forwarder 失败 / 身份)经全局 [nodeLog];
/// **不引重型框架** —— 一个文件、分级、按模式分流。落盘用同步 append(节点日志
/// 低频:相位切换 + 偶发失败),1 MiB 触发单份轮转(`node.log` → `node.log.1`)。
///
/// 测试用 [emit] 注入收集行(绕过 debugPrint / 落盘),免 path_provider。
class NodeLogger {
  NodeLogger({this.minLevel = LogLevel.info, void Function(String line)? emit})
      : _emit = emit;

  /// 低于此级别丢弃。release 默认 info(debug 噪音大),测试可注入 debug。
  final LogLevel minLevel;

  /// 测试收集;`null` → 按模式分流(debugPrint / 落盘)。
  final void Function(String line)? _emit;

  File? _file; // release 落盘文件([init] 后置位;未就位则 release 日志丢弃)
  static const int _maxBytes = 1 << 20; // 1 MiB 触发轮转

  void debug(Object m) => _log(LogLevel.debug, m);
  void info(Object m) => _log(LogLevel.info, m);
  void warn(Object m) => _log(LogLevel.warn, m);

  /// error 可附异常对象(拼到行尾,便于落盘排障;不进 UI)。
  void error(Object m, [Object? ex]) =>
      _log(LogLevel.error, ex == null ? '$m' : '$m :: $ex');

  /// release 模式预热落盘文件路径(debug / 测试 emit 模式 no-op)。
  /// 失败静默 → release 日志降级为丢弃(永不阻断业务)。
  Future<void> init() async {
    if (kDebugMode || _emit != null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/node.log');
    } catch (_) {
      _file = null;
    }
  }

  void _log(LogLevel level, Object m) {
    if (level.index < minLevel.index) return;
    final line = '${DateTime.now().toIso8601String()} '
        '[${level.name.toUpperCase()}] $m';
    final emit = _emit;
    if (emit != null) {
      emit(line);
      return;
    }
    if (kDebugMode) {
      debugPrint(line);
    } else {
      _write(line);
    }
  }

  void _write(String line) {
    final f = _file;
    if (f == null) return;
    try {
      if (f.existsSync() && f.lengthSync() > _maxBytes) {
        final old = File('${f.path}.1');
        if (old.existsSync()) old.deleteSync();
        f.renameSync(old.path); // 当前归档为 .1;f.path 空出,下行重建
      }
      f.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {
      // 落盘失败:静默丢弃。log 永不阻断业务。
    }
  }
}

/// 全局节点日志单例。核心 / 特性代码直接用,无需 Riverpod 注入
/// (核心层如 ws_client / forwarder 不持 ref)。
final nodeLog = NodeLogger();
