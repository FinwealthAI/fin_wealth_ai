import 'package:shared_preferences/shared_preferences.dart';

/// Lưu trạng thái "đã xem hướng dẫn" cho từng user (local, theo username).
///
/// Tương tự pattern conversation-id trong [ChatHistoryService]; cố ý KHÔNG
/// đồng bộ với backend `Member.onboarding_completed` (cờ đó dành riêng cho web)
/// — onboarding mobile có nội dung & bố cục khác nên giữ cờ riêng phía client.
class OnboardingPrefs {
  OnboardingPrefs._();

  // Key ổn định theo user; username rỗng (auth load chậm) vẫn dùng key chung
  // để KHÔNG vô tình bỏ qua onboarding (việc chặn khách do màn hình lo qua isGuest).
  static String _key(String scope, String username) =>
      '${scope}_onboarding_seen_${username.isEmpty ? '_' : username}';

  static Future<bool> _hasSeen(String scope, String username) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(scope, username)) ?? false;
  }

  static Future<void> _markSeen(String scope, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(scope, username), true);
  }

  static Future<void> _reset(String scope, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(scope, username));
  }

  // --- Tour cấp ứng dụng (bottom nav + FAB), chạy lần đầu vào app ---
  static Future<bool> hasSeenApp(String username) => _hasSeen('app', username);
  static Future<void> markAppSeen(String username) => _markSeen('app', username);
  static Future<void> resetApp(String username) => _reset('app', username);

  // --- Tour màn Chat (Mr.Wealth), chi tiết hơn, chạy khi vào màn chat ---
  static Future<bool> hasSeenChat(String username) => _hasSeen('chat', username);
  static Future<void> markChatSeen(String username) => _markSeen('chat', username);
  static Future<void> resetChat(String username) => _reset('chat', username);

  /// Xóa tất cả cờ onboarding của user (debug/test).
  static Future<void> resetAll(String username) async {
    await resetApp(username);
    await resetChat(username);
  }
}
