import 'package:flutter/foundation.dart';

import 'pwa_types.dart';

/// Bản cho Android/iOS native: không có PWA.
class Pwa {
  Pwa._();

  static bool get supported => false;
  static bool get isStandalone => false;
  static bool get isInstalled => false;
  static bool get canPrompt => false;
  static PwaPlatform get platform => PwaPlatform.other;

  /// Báo khi trạng thái cài đặt đổi (không bao giờ bắn trên native).
  static final Listenable changes = ChangeNotifier();

  static Future<PwaInstallOutcome> promptInstall() async =>
      PwaInstallOutcome.unavailable;

  /// Lối tắt đã mở app (`chat` | `strategy` | `market`), lấy một lần; rỗng nếu không có.
  static String takeLaunch() => '';
}
