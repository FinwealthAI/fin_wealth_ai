/// POST rồi đọc SSE theo TỪNG CHUNK — chỉ dùng trên web (`kIsWeb`).
///
/// Trên web Dio chạy bằng `XMLHttpRequest(arraybuffer)`: thân response chỉ tới tay
/// Dart khi request đã XONG HẲN, và `xhr.timeout = connect + receive` (45s) là trần
/// TỔNG — heartbeat không gia hạn được. Hệ quả: câu trả lời > 45s bị cắt khi chưa
/// nhận được event nào (không có conversation_id/message_id để resume). `fetch` +
/// `ReadableStream` cho stream thật như app native.
library;

export 'chat_sse_stub.dart' if (dart.library.js_interop) 'chat_sse_web.dart';
