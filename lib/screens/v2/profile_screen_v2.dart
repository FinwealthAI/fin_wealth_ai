import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';

class ProfileScreenV2 extends StatelessWidget {
  const ProfileScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: const FwAppBar(title: 'Tài khoản'),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: FwCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.2),
                    child: Text('T',
                        style: text.headlineMedium
                            ?.copyWith(color: AppColors.brandPrimaryDark)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tín Phan', style: text.titleLarge),
                        const SizedBox(height: 4),
                        const FwBadge(
                            label: 'Premium · 14 ngày',
                            tone: FwBadgeTone.warning),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Section('Đầu tư của tôi', items: const [
            (Icons.tune, 'Cấu hình đầu tư', 'Khẩu vị, mục tiêu, chu kỳ'),
            (Icons.dashboard_customize, 'Quản lý chiến lược', null),
            (Icons.calculate_outlined, 'Tính margin', null),
            (Icons.bookmark_outline, 'Watchlist', null),
          ]),
          _Section('Tài khoản', items: const [
            (Icons.notifications_outlined, 'Thông báo', null),
            (Icons.lock_outline, 'Đổi mật khẩu', null),
            (Icons.brightness_6_outlined, 'Giao diện', 'Tối'),
            (Icons.language, 'Ngôn ngữ', 'Tiếng Việt'),
          ]),
          _Section('Hỗ trợ', items: const [
            (Icons.help_outline, 'Trung tâm trợ giúp', null),
            (Icons.feedback_outlined, 'Gửi phản hồi', null),
            (Icons.info_outline, 'Về FinWealth', '1.0.0'),
          ]),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: FwButton(
              label: 'Đăng xuất',
              icon: Icons.logout,
              variant: FwButtonVariant.danger,
              fullWidth: true,
              onPressed: () {},
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<(IconData, String, String?)> items;
  const _Section(this.title, {required this.items});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
            child: Text(title.toUpperCase(),
                style: text.labelSmall
                    ?.copyWith(letterSpacing: 1.2, color: AppColors.darkTextMuted)),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 52),
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(items[i].$1,
                          size: 18, color: AppColors.brandPrimaryDark),
                    ),
                    title: Text(items[i].$2),
                    subtitle: items[i].$3 != null ? Text(items[i].$3!) : null,
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.darkTextMuted),
                    onTap: () {},
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
