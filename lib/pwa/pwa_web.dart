// Chỉ biên dịch cho web — chọn bằng import có điều kiện ở pwa.dart.
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';

import 'pwa_types.dart';

class _PwaChanges extends ChangeNotifier {
  void bump() => notifyListeners();
}

/// Đọc `window.fwPwa` (web/index.html). Tên hàm JS phải khớp hai bên.
class Pwa {
  Pwa._();

  static JSObject? get _bridge {
    try {
      return globalContext['fwPwa'] as JSObject?;
    } catch (_) {
      return null;
    }
  }

  static JSAny? _call(String method, [JSAny? arg]) {
    final bridge = _bridge;
    if (bridge == null) return null;
    try {
      return arg == null
          ? bridge.callMethod<JSAny?>(method.toJS)
          : bridge.callMethod<JSAny?>(method.toJS, arg);
    } catch (e) {
      debugPrint('[pwa] fwPwa.$method lỗi: $e');
      return null;
    }
  }

  static bool _bool(String method) {
    final r = _call(method);
    return r != null && (r as JSBoolean).toDart;
  }

  static bool get supported => _bridge != null;

  /// Đang chạy trong cửa sổ app đã cài (không phải tab trình duyệt).
  static bool get isStandalone => _bool('isStandalone');

  /// Đã cài (kể cả vừa cài xong ngay trong tab này).
  static bool get isInstalled => _bool('isInstalled');

  /// Trình duyệt đang giữ sẵn hộp cài (Chrome Android, đủ điều kiện).
  static bool get canPrompt => _bool('canPrompt');

  static PwaPlatform get platform {
    final r = _call('platform');
    return switch (r == null ? '' : (r as JSString).toDart) {
      'android' => PwaPlatform.android,
      'ios' => PwaPlatform.ios,
      'inapp' => PwaPlatform.inApp,
      _ => PwaPlatform.other,
    };
  }

  static final _PwaChanges _changes = _PwaChanges();
  static bool _hooked = false;

  /// Báo khi trình duyệt sẵn sàng cho cài, vừa cài xong, hoặc đổi chế độ hiển thị.
  static Listenable get changes {
    if (!_hooked && _bridge != null) {
      _hooked = true;
      _call('onChange', (() => _changes.bump()).toJS);
    }
    return _changes;
  }

  static Future<PwaInstallOutcome> promptInstall() async {
    final r = _call('promptInstall');
    if (r == null) return PwaInstallOutcome.unavailable;
    try {
      final outcome = await (r as JSPromise<JSString>).toDart;
      return switch (outcome.toDart) {
        'accepted' => PwaInstallOutcome.accepted,
        'dismissed' => PwaInstallOutcome.dismissed,
        _ => PwaInstallOutcome.unavailable,
      };
    } catch (_) {
      return PwaInstallOutcome.unavailable;
    }
  }

  static String takeLaunch() {
    final r = _call('takeLaunch');
    return r == null ? '' : (r as JSString).toDart;
  }
}
