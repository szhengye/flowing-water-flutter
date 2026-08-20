import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/chain/polygonscan_client.dart';

/// Etherscan V2 响应解析测试 —— 锁定 07 Wallet 交易历史的不变式
/// (方向由 from==account 决定;金额带符号;isError=1→失败;result 非数组→空)。
/// 对齐上游 `polygonscan-client.ts` 的 `toEvmWalletTx`。
const _me = '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _other = '0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

Map<String, dynamic> _raw({
  required String hash,
  required String from,
  required String to,
  String value = '0',
  String timeStamp = '1700000000',
  String blockNumber = '100',
  String gasPrice = '10000000000',
  String gasUsed = '21000',
  String isError = '0',
}) =>
    {
      'hash': hash,
      'from': from,
      'to': to,
      'value': value,
      'timeStamp': timeStamp,
      'blockNumber': blockNumber,
      'gasPrice': gasPrice,
      'gasUsed': gasUsed,
      'isError': isError,
    };

void main() {
  group('toWalletTx(方向 / 金额 / 手续费 / 状态)', () {
    test('支出(from==account):amount 负、对手方=to、direction=out', () {
      final t = toWalletTx(
        _raw(hash: '0xout', from: _me, to: _other, value: '1500000'),
        _me,
        6,
      );
      expect(t.direction, WalletTxDirection.outgoing);
      expect(t.amount, -1.5); // 支出带负号(对齐上游 direction==='out' → -valueHuman)
      expect(t.counterparty, _other);
      expect(t.status, isTrue);
    });

    test('收入(from!=account):amount 正、对手方=from、direction=in', () {
      final t = toWalletTx(
        _raw(hash: '0xin', from: _other, to: _me, value: '2000000'),
        _me,
        6,
      );
      expect(t.direction, WalletTxDirection.incoming);
      expect(t.amount, 2.0);
      expect(t.counterparty, _other);
    });

    test('MATIC(decimals=18):1 ether 解码为 1.0', () {
      final t = toWalletTx(
        _raw(hash: '0xm', from: _other, to: _me, value: '1000000000000000000'),
        _me,
        18,
      );
      expect(t.amount, 1.0);
      expect(t.decimals, 18);
    });

    test('手续费 = gasUsed × gasPrice / 1e18(8 位)', () {
      final t = toWalletTx(_raw(hash: '0xf', from: _me, to: _other), _me, 18);
      // 21000 × 1e10 / 1e18 = 2.1e-4
      expect(t.feeMatic, '0.00021000');
    });

    test('isError=1 → status=false(链上失败)', () {
      final t = toWalletTx(
        _raw(hash: '0xfail', from: _me, to: _other, isError: '1'),
        _me,
        18,
      );
      expect(t.status, isFalse);
    });

    test('块号/时间戳解析;空字符串→null', () {
      final t = toWalletTx(
        _raw(hash: '0xb', from: _me, to: _other, blockNumber: '', timeStamp: ''),
        _me,
        18,
      );
      expect(t.blockNumber, isNull);
      expect(t.blockTimestamp, isNull);
    });
  });

  group('parseEtherscanResponse(result 形态)', () {
    test('result 为数组 → 逐条映射', () {
      final body = {
        'status': '1',
        'message': 'OK',
        'result': [
          _raw(hash: '0x1', from: _me, to: _other),
          _raw(hash: '0x2', from: _other, to: _me),
        ],
      };
      final list = parseEtherscanResponse(body, account: _me, decimals: 6);
      expect(list, hasLength(2));
      expect(list[0].txHash, '0x1');
      expect(list[1].direction, WalletTxDirection.incoming);
    });

    test('result 为字符串("No transactions found")→ 空列表(不抛)', () {
      final body = {'status': '0', 'message': 'No transactions found', 'result': 'No transactions found'};
      expect(parseEtherscanResponse(body, account: _me, decimals: 6), isEmpty);
    });

    test('result 为限流字符串 → 空列表', () {
      final body = {'status': '0', 'message': 'NOTOK', 'result': 'Max rate limit reached'};
      expect(parseEtherscanResponse(body, account: _me, decimals: 6), isEmpty);
    });

    test('result 缺失 → 空列表', () {
      expect(parseEtherscanResponse({}, account: _me, decimals: 6), isEmpty);
    });
  });
}
