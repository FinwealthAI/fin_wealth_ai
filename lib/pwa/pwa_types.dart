/// Trình duyệt đang mở m.finwealth.vn — quyết định cách hướng dẫn cài app.
enum PwaPlatform {
  /// Chrome/Edge/Samsung Internet trên Android: có hộp cài của trình duyệt.
  android,

  /// Safari/Chrome trên iPhone, iPad: chỉ cài được qua Chia sẻ → Thêm vào MH chính.
  ios,

  /// Trình duyệt nhúng trong Zalo/Facebook/TikTok…: không cài được, phải mở
  /// bằng Safari/Chrome trước.
  inApp,

  /// Máy tính và các trường hợp khác.
  other,
}

/// Kết quả hộp cài của trình duyệt (Chrome Android).
enum PwaInstallOutcome { accepted, dismissed, unavailable }
