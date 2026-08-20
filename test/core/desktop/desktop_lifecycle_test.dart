import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/desktop/desktop_lifecycle.dart';

/// 单实例判定逻辑(10 桌面常驻):
/// 取到锁 → proceed;锁已被另一实例持有 → alreadyRunning(调用方据此退出,**绝不** proceed)。
///
/// 为什么只测这个:跨进程文件锁行为不可在单进程单测里复现 —— 故注入伪 acquireLock,
/// 只锁定「判定意图」(锁未取到 ⇒ 视作已运行 ⇒ 必须拦下)。真实 acquireSingleInstanceLock
/// 的双进程行为属手动验证(见票 10 验证清单)。
void main() {
  test('取得锁 → proceed', () async {
    final d = await evaluateSingleInstance(acquireLock: () async => true);
    expect(d, SingleInstanceDecision.proceed);
  });

  test('锁已被持有(另一实例运行) → alreadyRunning,绝不 proceed', () async {
    final d = await evaluateSingleInstance(acquireLock: () async => false);
    expect(d, SingleInstanceDecision.alreadyRunning);
  });
}
