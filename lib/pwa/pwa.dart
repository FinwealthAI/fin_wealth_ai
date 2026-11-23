/// Cầu nối PWA cho bản web m.finwealth.vn — cài app lên màn hình chính và lối
/// tắt mở thẳng một màn (xem docs/pwa.md).
///
/// Phía JS là `window.fwPwa` trong `web/index.html`. Trên Android/iOS native
/// (hoặc khi trang không có cầu nối) mọi hàm trả về "không hỗ trợ".
library;

export 'pwa_types.dart';
export 'pwa_stub.dart' if (dart.library.js_interop) 'pwa_web.dart';
