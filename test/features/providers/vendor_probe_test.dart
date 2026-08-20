import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/db/database.dart';
import 'package:flowing_water/core/forwarder/stream_http.dart';
import 'package:flowing_water/features/providers/vendor_probe.dart';

/// 连通性探测测试 —— 用假 StreamHttpFn 验 200+SSE→ok / 非 200→fail / 非 SSE→fail。
void main() {
  StreamHttpFn fakeHttp(int status, String contentType) =>
      ({required url, required headers, required body, required cancelToken}) async {
        final controller = StreamController<List<int>>();
        Future(() { controller.add([1]); controller.close(); });
        return UpstreamStreamedResponse(status, contentType, controller.stream);
      };

  ProviderLlmVendorRow vendor({
    String endpoint = 'https://x/v1',
    String adapterType = 'openai',
  }) =>
      ProviderLlmVendorRow(
        vendorId: 1,
        vendorName: 'v',
        endpoint: endpoint,
        apiKey: 'sk',
        vendorModels: '[]',
        adapterType: adapterType,
        isActive: true,
        supportsStream: true,
      );

  test('200 + text/event-stream → ok', () async {
    final r = await probeVendor(
      vendor: vendor(),
      providerModel: 'gpt-4o',
      streamHttp: fakeHttp(200, 'text/event-stream'),
    );
    expect(r.ok, isTrue);
    expect(r.message, contains('可达'));
  });

  test('非 200 → fail(HTTP 码)', () async {
    final r = await probeVendor(
      vendor: vendor(),
      providerModel: 'gpt-4o',
      streamHttp: fakeHttp(401, 'application/json'),
    );
    expect(r.ok, isFalse);
    expect(r.message, 'HTTP 401');
  });

  test('200 但非 SSE → fail(假流式检测)', () async {
    final r = await probeVendor(
      vendor: vendor(),
      providerModel: 'gpt-4o',
      streamHttp: fakeHttp(200, 'application/json'),
    );
    expect(r.ok, isFalse);
    expect(r.message, contains('非流式'));
  });

  test('firstVendorModel 解析 JSON array 首项', () {
    expect(firstVendorModel('["gpt-4o", "gpt-3.5"]'), 'gpt-4o');
    expect(firstVendorModel('[]'), isNull);
    expect(firstVendorModel('not json'), isNull);
  });
}
