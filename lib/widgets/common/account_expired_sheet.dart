import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../blocs/auth/auth_state.dart';
import '../../screens/v2/upgrade_screen_v2.dart';
import '../../theme/theme.dart';
import 'fw_button.dart';

Future<void> _launchUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

void showAccountExpiredSheet(BuildContext context, AuthAccountExpired state) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      final text = Theme.of(context).textTheme;
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.access_time_filled,
                size: 48, color: AppColors.dangerDark),
            const SizedBox(height: 16),
            Text('Tài khoản đã hết hạn',
                style:
                    text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Hãy tiếp tục đồng hành cùng FinWealth để không bỏ lỡ các tín hiệu đầu tư và phân tích chuyên sâu từ chuyên gia.',
              style:
                  text.bodyMedium?.copyWith(color: AppColors.darkTextMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FwButton(
              label: 'Nâng cấp tài khoản ngay',
              icon: Icons.star_rounded,
              fullWidth: true,
              size: FwButtonSize.lg,
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const UpgradeScreenV2()),
                );
              },
            ),
            const SizedBox(height: 10),
            if (state.zaloGroup.isNotEmpty)
              FwButton(
                label: 'Tham gia cộng đồng Zalo',
                icon: Icons.people_alt_outlined,
                variant: FwButtonVariant.secondary,
                fullWidth: true,
                onPressed: () {
                  Navigator.pop(context);
                  _launchUrl(state.zaloGroup);
                },
              ),
            const SizedBox(height: 10),
            if (state.zaloSupport.isNotEmpty)
              FwButton(
                label: 'Liên hệ quản trị viên',
                icon: Icons.chat_bubble_outline,
                variant: FwButtonVariant.ghost,
                fullWidth: true,
                onPressed: () {
                  Navigator.pop(context);
                  _launchUrl(state.zaloSupport);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
