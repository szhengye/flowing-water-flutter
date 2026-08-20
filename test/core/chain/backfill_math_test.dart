import 'dart:math';

import 'package:flowing_water/core/chain/backfill_math.dart';
import 'package:flutter_test/flutter_test.dart';

/// backfill 纯逻辑测试 —— 锁定三层 floor 续点语义、分页边界、full-jitter 退避界。
/// 这些是 watcher 跨重启不错过事件 / 不重复 / 不打爆 RPC 的不变式。
void main() {
  group('backfillFloor(三层 floor:cursor > deployBlock > recent window)', () {
    test('有 cursor → 从 cursor 续点(重扫该块幂等兜底)', () {
      expect(backfillFloor(latest: 200, cursor: 150), 150);
    });

    test('cursor 为 0(异常) → 不当首跑,落 deployBlock', () {
      expect(backfillFloor(latest: 200, cursor: 0, deployBlock: 100), 100);
    });

    test('无 cursor 有 deployBlock → 从部署块(不错过部署以来事件)', () {
      expect(backfillFloor(latest: 500, deployBlock: 42), 42);
    });

    test('无 cursor 无 deployBlock → recent window(latest - 72h×1800 块/h)', () {
      // 72 * 1800 = 129600
      expect(backfillFloor(latest: 200000), 200000 - 129600);
    });

    test('window 大于 latest → 从 0(别下溢成负数)', () {
      expect(backfillFloor(latest: 100), 0);
    });

    test('window 可调', () {
      expect(
        backfillFloor(latest: 200000, recentWindowHours: 24),
        200000 - 24 * 1800,
      );
    });
  });

  group('logPages(分页 [fromBlock, latest],每页 page 块)', () {
    test('latest < fromBlock → 空', () {
      expect(logPages(100, 50), isEmpty);
    });

    test('整页 + 尾页', () {
      final pages = logPages(100, 125); // 26 块 → 100-109,110-119,120-125
      expect(pages, [
        (from: 100, to: 109),
        (from: 110, to: 119),
        (from: 120, to: 125),
      ]);
    });

    test('恰好整除(无尾页)', () {
      expect(logPages(100, 119), [
        (from: 100, to: 109),
        (from: 110, to: 119),
      ]);
    });

    test('单块单页', () {
      expect(logPages(100, 100), [(from: 100, to: 100)]);
    });

    test('page 可调', () {
      expect(logPages(100, 105, page: 2), [
        (from: 100, to: 101),
        (from: 102, to: 103),
        (from: 104, to: 105),
      ]);
    });
  });

  group('fullJitterDelaySeconds(delay ∈ [0, min(cap, base·2^attempt)])', () {
    test('attempt 0 → [0,1]', () {
      for (var i = 0; i < 50; i++) {
        final d = fullJitterDelaySeconds(0);
        expect(d, inInclusiveRange(0, 1));
      }
    });

    test('attempt 增长不超 cap 60', () {
      for (var attempt = 0; attempt < 12; attempt++) {
        final upper = min(60, 1 << attempt);
        final d = fullJitterDelaySeconds(attempt);
        expect(d, inInclusiveRange(0, upper));
      }
    });

    test('固定种子可复现(可注入测试用固定值)', () {
      expect(
        fullJitterDelaySeconds(5, random: Random(123)),
        fullJitterDelaySeconds(5, random: Random(123)),
      );
    });
  });
}
