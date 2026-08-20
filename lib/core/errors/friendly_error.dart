import 'package:dio/dio.dart';

import '../relay/ws_client.dart';

/// 把裸异常翻译成供应商可读的提示(11 friendlyError)。
///
/// 借 listening-king `error_utils` 模式(集中式 `String friendlyError(Object e)`,
/// DioException 按型分类、其余去 `Exception:` 前缀),适配本域异常:上游 HTTP
/// (forwarder / Polygonscan / 厂商探测走 dio)、relay WS 反查/同步(`RelayQueryException`)。
///
/// **Rule 2 取舍**:ticket 想要 `{标题, 说明, 可重试}` 三字段模型,但现有调用点
/// (SnackBar / 表单错误)只消费一个 String,且尚无「重试」UI —— 三字段 + retryable
/// 在没有重试动作时是投机。故镜像 listening-king 的 String 形态;三字段 / 重试动作
/// 待真有重试 UI 时毕业(见 map Fog)。
///
/// 用于所有 `catch (e)` 的用户可见处,避免把 `DioException` / `RelayQueryException`
/// /堆栈字符串直接抛给供应商。
String friendlyError(Object e) {
  // relay WS 反查 / 同步模型失败(06 对账 / 02 模型同步)。
  if (e is RelayQueryException) {
    return '中转站请求失败:${e.message}(请确认节点已连接后重试)';
  }
  if (e is DioException) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '网络连接超时,请检查网络后重试';
      case DioExceptionType.connectionError:
        return '无法连接到上游服务,请检查网络或厂商配置';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final data = e.response?.data;
        // 优先透传上游返回的错误信息。
        if (data is Map) {
          final serverMsg =
              data['error']?.toString() ?? data['message']?.toString();
          if (serverMsg != null && serverMsg.isNotEmpty) return serverMsg;
        }
        if (status != null && status >= 500) return '上游服务暂时不可用,请稍后重试';
        if (status == 429) return '请求过于频繁,请稍后重试';
        return status == null ? '上游返回错误,请重试' : '上游返回错误($status),请重试';
      case DioExceptionType.cancel:
        return '请求已取消';
      default:
        return '网络异常,请检查网络后重试';
    }
  }
  // 兜底:去掉 "Exception: " 前缀,保留消息本身。
  return e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
}
