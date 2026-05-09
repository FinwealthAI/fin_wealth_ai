import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../respositories/auth_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';

import 'change_password_screen_v2.dart';
import 'mindmap_screen_v2.dart';
import 'screener_screen_v2.dart';

class ProfileScreenV2 extends StatelessWidget {
  final bool isDrawer;
  const ProfileScreenV2({super.key, this.isDrawer = false});

  static void _push(BuildContext c, Widget w) {
    Navigator.of(c).push(MaterialPageRoute(builder: (_) => w));
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthRepository>().logout();
    if (context.mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login-v2', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final userData =
            state is AuthSuccess ? state.userData : <String, dynamic>{};
        final username = userData['username'] as String? ?? 'Khách';
        final avatarUrl = userData['avatar'] as String?;
        final isGuest = userData['is_guest'] == true;
        final initial =
            username.isNotEmpty ? username[0].toUpperCase() : '?';

        return Scaffold(
          appBar: isDrawer ? null : const FwAppBar(title: 'Tài khoản'),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: FwCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            AppColors.brandPrimary.withValues(alpha: 0.2),
                        backgroundImage: avatarUrl != null &&
                                avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? Text(initial,
                                style: text.headlineMedium?.copyWith(
                                    color: AppColors.brandPrimaryDark))
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(username, style: text.titleLarge),
                            const SizedBox(height: 4),
                            if (isGuest)
                              const FwBadge(
                                  label: 'Khách',
                                  tone: FwBadgeTone.neutral)
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _Section('Công cụ & Phân tích', items: [
                (Icons.tune_outlined, 'Lọc cổ phiếu', 'Tìm kiếm cơ hội đầu tư',
                    () => _push(context, const ScreenerScreenV2())),
                (Icons.account_tree_outlined, 'Sơ đồ kinh tế',
                    'Mô hình giá trị chuỗi',
                    () => _push(context, const MindmapScreenV2())),
                (Icons.calculate_outlined, 'Tính margin',
                    'Công cụ tính toán đòn bẩy', () {}),
                (Icons.bookmark_outline, 'Watchlist', 'Danh mục quan tâm',
                    () {}),
              ]),
              if (!isGuest) ...[
                _Section('Đầu tư của tôi', items: [
                  (Icons.tune, 'Cấu hình đầu tư', 'Khẩu vị, mục tiêu, chu kỳ',
                      () {}),
                  (Icons.dashboard_customize, 'Quản lý chiến lược',
                      'Theo dõi hiệu quả', () {}),
                ]),
                _Section('Tài khoản', items: [
                  (Icons.notifications_outlined, 'Thông báo', null, () {}),
                  (Icons.lock_outline, 'Đổi mật khẩu', null,
                      () => _push(context, const ChangePasswordScreenV2())),
                  (Icons.brightness_6_outlined, 'Giao diện', 'Tối', () {}),
                  (Icons.language, 'Ngôn ngữ', 'Tiếng Việt', () {}),
                ]),
              ],
              _Section('Hỗ trợ', items: [
                (Icons.help_outline, 'Trung tâm trợ giúp', null, () {}),
                (Icons.feedback_outlined, 'Gửi phản hồi', null, () {}),
                (Icons.info_outline, 'Về FinWealth', '1.0.0', () {}),
              ]),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: isGuest
                    ? FwButton(
                        label: 'Đăng nhập',
                        icon: Icons.login,
                        fullWidth: true,
                        onPressed: () => Navigator.of(context)
                            .pushNamedAndRemoveUntil(
                                '/login-v2', (r) => false),
                      )
                    : FwButton(
                        label: 'Đăng xuất',
                        icon: Icons.logout,
                        variant: FwButtonVariant.danger,
                        fullWidth: true,
                        onPressed: () => _logout(context),
                      ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<(IconData, String, String?, VoidCallback)> items;
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
                    onTap: items[i].$4,
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
