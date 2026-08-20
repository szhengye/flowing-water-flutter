import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/errors/friendly_error.dart';
import 'package:flowing_water/core/relay/ws_client.dart';

/// friendlyError 测试(11):锁定「裸异常 → 供应商可读提示」的映射意图 ——
/// 上游 HTTP 错误按型分类、relay 反查失败显式提示、其余去技术前缀。
RequestOptions _req() => RequestOptions(path: '/x');

void main() {
  group('friendlyError(DioException)', () {
    test('timeout 型 → 超时提示', () {
      expect(
        friendlyError(DioException(
            type: DioExceptionType.connectionTimeout, requestOptions: _req())),
        contains('网络连接超时'),
      );
    });

    test('connectionError → 无法连接上游', () {
      expect(
        friendlyError(DioException(
            type: DioExceptionType.connectionError, requestOptions: _req())),
        contains('无法连接到上游服务'),
      );
    });

    test('badResponse 5xx → 上游不可用', () {
      expect(
        friendlyError(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: _req(),
          response: Response(requestOptions: _req(), statusCode: 500),
        )),
        contains('上游服务暂时不可用'),
      );
    });

    test('badResponse 429 → 过于频繁', () {
      expect(
        friendlyError(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: _req(),
          response: Response(requestOptions: _req(), statusCode: 429),
        )),
        contains('过于频繁'),
      );
    });

    test('badResponse 透传服务端 error 文案(优先于状态码兜底)', () {
      expect(
        friendlyError(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: _req(),
          response: Response(
            requestOptions: _req(),
            statusCode: 400,
            data: {'error': 'model not found'},
          ),
        )),
        'model not found',
      );
    });

    test('cancel → 已取消', () {
      expect(
        friendlyError(DioException(
            type: DioExceptionType.cancel, requestOptions: _req())),
        contains('已取消'),
      );
    });
  });

  test('friendlyError(RelayQueryException) → 中转站请求失败', () {
    expect(
      friendlyError(const RelayQueryException('relay 反查超时')),
      contains('中转站请求失败'),
    );
  });

  group('friendlyError(兜底)', () {
    test('Exception → 去 "Exception: " 前缀,留消息', () {
      expect(friendlyError(Exception('boom')), 'boom');
    });

    test('非异常对象 → toString 原样', () {
      expect(friendlyError('plain string'), 'plain string');
    });
  });
}
