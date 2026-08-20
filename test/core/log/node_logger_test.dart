import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/log/node_logger.dart';

/// NodeLogger 测试(11):锁定分级过滤 + 行格式 + error 附异常。
/// 经 `emit` 注入收集行,绕过 debugPrint / 落盘,免 path_provider。
void main() {
  test('minLevel 过滤:仅 ≥ minLevel 放行', () {
    final out = <String>[];
    final log = NodeLogger(minLevel: LogLevel.warn, emit: out.add);
    log.debug('d');
    log.info('i');
    log.warn('w');
    log.error('e');
    expect(out, hasLength(2)); // warn + error
    expect(out[0], contains('[WARN] w'));
    expect(out[1], contains('[ERROR] e'));
  });

  test('默认 info:debug 被过滤', () {
    final out = <String>[];
    final log = NodeLogger(emit: out.add); // 缺省 minLevel = info
    log.debug('d');
    log.info('i');
    expect(out, hasLength(1));
    expect(out.single, contains('[INFO] i'));
  });

  test('error(ex) 把异常拼到行尾(供落盘排障,不进 UI)', () {
    final out = <String>[];
    final log = NodeLogger(emit: out.add);
    log.error('stream failed', StateError('boom'));
    expect(out.single, contains('[ERROR] stream failed'));
    expect(out.single, contains('boom'));
  });

  test('行以 ISO8601 时间戳开头 + 级别标签', () {
    final out = <String>[];
    NodeLogger(emit: out.add).info('hello');
    expect(
      out.single,
      matches(RegExp(r'^\d{4}-\d{2}-\d{2}T.*\[INFO\] hello$')),
    );
  });
}
