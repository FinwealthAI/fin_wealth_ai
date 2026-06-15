import 'package:shared_preferences/shared_preferences.dart';

/// Lưu trạng thái "đã xem hướng dẫn" cho từng user (local, theo username).
///
/// MỘT cờ duy nhất cho cả luồng onboarding hợp nhất (tour app → vào thẳng tour
/// chat). Cố ý KHÔNG đồng bộ với backend `Member.onboarding_completed` (cờ đó
/// dành riêng cho web) — onboarding mobile có nội dung & bố cục khác.
class OnboardingPrefs {
  OnboardingPrefs._();

  // Key ổn định theo user; username rỗng (auth load chậm) vẫn dùng key chung
  // để KHÔNG vô tình bỏ qua onboarding (việc chặn khách do màn hình lo qua isGuest).
  static String _key(String username) =>
      'onboarding_seen_${username.isEmpty ? '_' : username}';

  /// Đã xem hướng dẫn (luồng hợp nhất) chưa.
  static Future<bool> hasSeen(String username) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(username)) ?? false;
  }

  /// Đánh dấu đã hoàn thành / bỏ qua hướng dẫn.
  static Future<void> markSeen(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(username), true);
  }

  /// Xóa cờ (debug/test — để hiện lại hướng dẫn).
  static Future<void> reset(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(username));
  }
}
