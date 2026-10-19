import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'chat_error.dart';

/// Gửi POST bằng `fetch` và phát từng chunk byte của response (SSE).
///
/// [idleTimeout] áp cho lúc chờ header và giữa hai chunk liên tiếp (tương đương
/// `receiveTimeout` của Dio native) — heartbeat ": ping" của server làm mới nó.
/// Mọi lỗi đều được đổi sang [ChatError]; huỷ subscription sẽ abort request.
Stream<List<int>> postSseStream({
  required String url,
  required Map<String, String> headers,
  required String body,
  required Duration idleTimeout,
}) async* {
  final controller = web.AbortController();
  try {
    final requestHeaders = web.Headers();
    for (final entry in headers.entries) {
      requestHeaders.append(entry.key, entry.value);
    }

    final response = await web.window
        .fetch(
          url.toJS,
          web.RequestInit(
            method: 'POST',
            headers: requestHeaders,
            body: body.toJS,
            // Giống XHR của Dio: không gửi cookie phiên (auth bằng Bearer JWT),
            // tránh DRF SessionAuthentication đòi CSRF.
            credentials: 'omit',
            signal: controller.signal,
          ),
        )
        .toDart
        .timeout(idleTimeout);

    if (!response.ok) {
      String? text;
      try {
        text = (await response.text().toDart.timeout(idleTimeout)).toDart;
      } catch (_) {}
      throw ChatError.fromStatus(response.status,
          serverDetail: _detailOf(text));
    }

    final stream = response.body;
    // Không có thân → để caller coi là stream bị cắt (không có [DONE]) và resume.
    if (stream == null) return;

    final reader = stream.getReader() as web.ReadableStreamDefaultReader;
    while (true) {
      final chunk = await reader.read().toDart.timeout(idleTimeout);
      if (chunk.done) break;
      final value = chunk.value;
      if (value != null) yield (value as JSUint8Array).toDart;
    }
  } on ChatError {
    rethrow;
  } on TimeoutException {
    throw ChatError.timeout();
  } catch (e) {
    // fetch ném TypeError ("Load failed"/"Failed to fetch") khi mất mạng, bị chặn
    // CORS hoặc đứt kết nối giữa chừng.
    throw ChatError.noNetwork(detail: e.toString());
  } finally {
    controller.abort();
  }
}

/// Lấy `detail` từ body lỗi dạng JSON của DRF (vd 403 chưa đủ điểm Wealth).
String? _detailOf(String? text) {
  if (text == null || text.isEmpty) return null;
  try {
    final j = jsonDecode(text);
    if (j is Map && j['detail'] is String) return j['detail'] as String;
  } catch (_) {}
  return null;
}
