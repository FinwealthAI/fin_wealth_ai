import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme.dart';
import 'pwa.dart';

/// "Để sau" ở thẻ mời cài app: ẩn 14 ngày (lưu trên máy).
class PwaPrefs {
  PwaPrefs._();

  static const _kDismissedAt = 'pwa_install_card_dismissed_at';
  static const snooze = Duration(days: 14);

  static Future<bool> isSnoozed() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kDismissedAt);
    if (ms == null) return false;
    return DateTime.now()
        .isBefore(DateTime.fromMillisecondsSinceEpoch(ms).add(snooze));
  }

  static Future<void> snoozeNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDismissedAt, DateTime.now().millisecondsSinceEpoch);
  }
}

/// Đáng mời cài chưa: đang ở tab trình duyệt (chưa cài) và trình duyệt cài được.
/// Trình duyệt trong Zalo/Facebook không mời (khách vãng lai) — vẫn có mục
/// "Cài FinWealth" ở tab Khác.
bool pwaInstallWorthOffering() {
  if (!Pwa.supported || Pwa.isInstalled) return false;
  return Pwa.canPrompt || Pwa.platform == PwaPlatform.ios;
}

/// Cài app: Chrome Android có hộp cài sẵn thì mở luôn; các trường hợp khác hiện
/// hướng dẫn theo trình duyệt. Trả về true khi người dùng đã đồng ý cài.
Future<bool> startPwaInstall(BuildContext context) async {
  if (Pwa.canPrompt) {
    final outcome = await Pwa.promptInstall();
    if (outcome != PwaInstallOutcome.unavailable) {
      if (outcome == PwaInstallOutcome.accepted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đang cài FinWealth lên màn hình chính…'),
        ));
      }
      return outcome == PwaInstallOutcome.accepted;
    }
  }
  if (!context.mounted) return false;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.darkSurface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => _PwaGuideSheet(platform: Pwa.platform),
  );
  return false;
}

class _PwaGuideSheet extends StatelessWidget {
  final PwaPlatform platform;
  const _PwaGuideSheet({required this.platform});

  @override
  Widget build(BuildContext context) {
    final (String title, List<String> steps) = switch (platform) {
      PwaPlatform.ios => (
          'Cài FinWealth trên iPhone',
          [
            'Nhấn nút Chia sẻ (ô vuông có mũi tên hướng lên) của trình duyệt — '
                'ở thanh dưới Safari, hoặc góc trên bên phải Chrome.',
            'Kéo xuống, chọn "Thêm vào MH chính".',
            'Nhấn "Thêm". Biểu tượng FinWealth sẽ có trên màn hình chính.',
          ],
        ),
      PwaPlatform.inApp => (
          'Mở bằng trình duyệt để cài',
          [
            'Trình duyệt trong Zalo/Facebook không cài được ứng dụng.',
            'Nhấn nút ⋯ ở góc trên, chọn "Mở bằng trình duyệt" (Safari hoặc Chrome) '
                '— hoặc sao chép liên kết bên dưới rồi dán vào trình duyệt.',
            'Trong trình duyệt, vào tab Khác → "Cài FinWealth lên điện thoại".',
          ],
        ),
      PwaPlatform.android => (
          'Cài FinWealth trên Android',
          [
            'Nhấn nút ⋮ ở góc trên bên phải Chrome.',
            'Chọn "Cài đặt ứng dụng" (hoặc "Thêm vào màn hình chính").',
            'Nhấn "Cài đặt". FinWealth sẽ mở toàn màn hình như một ứng dụng.',
          ],
        ),
      PwaPlatform.other => (
          'Cài FinWealth',
          [
            'Mở menu của trình duyệt.',
            'Chọn "Cài đặt FinWealth" hoặc "Thêm vào màn hình chính".',
          ],
        ),
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppColors.darkTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Mở nhanh từ màn hình chính, toàn màn hình, không lẫn với các tab trình duyệt.',
              style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.brandPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(steps[i],
                          style: const TextStyle(
                              color: AppColors.darkTextPrimary,
                              fontSize: 14,
                              height: 1.45)),
                    ),
                  ],
                ),
              ),
            if (platform == PwaPlatform.inApp)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('Sao chép liên kết'),
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: Uri.base.origin));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Đã sao chép liên kết FinWealth')));
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ mời cài app, nổi trên thanh điều hướng của RootShellV2.
class PwaInstallCard extends StatelessWidget {
  final VoidCallback onInstall;
  final VoidCallback onDismiss;

  const PwaInstallCard(
      {super.key, required this.onInstall, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkSurfaceElevated,
      elevation: 8,
      shadowColor: Colors.black,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.xs, AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Image.asset('assets/images/logo_standard.jpg',
                  width: 40, height: 40, fit: BoxFit.cover),
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cài app FinWealth',
                      style: TextStyle(
                          color: AppColors.darkTextPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text('Mở nhanh từ màn hình chính, toàn màn hình',
                      style: TextStyle(
                          color: AppColors.darkTextSecondary, fontSize: 12)),
                ],
              ),
            ),
            FilledButton(
              onPressed: onInstall,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Cài đặt'),
            ),
            IconButton(
              tooltip: 'Để sau',
              onPressed: onDismiss,
              icon: const Icon(Icons.close,
                  size: 18, color: AppColors.darkTextMuted),
            ),
          ],
        ),
      ),
    );
  }
}
