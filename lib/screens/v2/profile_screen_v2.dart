import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../respositories/auth_repository.dart';
import '../../config/api_config.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';

import 'change_password_screen_v2.dart';
import 'economic_charts_screen_v2.dart';
import 'edit_profile_screen_v2.dart';
import 'margin_screen_v2.dart';
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

  Future<void> _editProfile(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const EditProfileScreenV2()));
    if (changed == true && context.mounted) {
      // Ép rebuild để hiện email/sđt mới (BlocBuilder lắng nghe AuthSuccess).
      final repo = context.read<AuthRepository>();
      context.read<AuthBloc>().add(AuthUserUpdated({
            'username': repo.username,
            'email': repo.email,
            'phone': repo.phone,
            'ts': DateTime.now().millisecondsSinceEpoch,
          }));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final authRepo = context.read<AuthRepository>();
        final username = authRepo.username ?? 'Khách';
        final avatarUrl = authRepo.avatar;
        final isGuest = authRepo.accessToken == null;
        final totalPoints = authRepo.totalPoints;
        final email = authRepo.email ?? '';
        final phone = authRepo.phone ?? '';
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
                            ? NetworkImage(avatarUrl.startsWith('http')
                                ? avatarUrl
                                : '${ApiConfig.baseUrl}$avatarUrl')
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
                            if (!isGuest)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.email_outlined,
                                        size: 13,
                                        color: AppColors.darkTextMuted),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        email.isNotEmpty
                                            ? email
                                            : 'Chưa cập nhật',
                                        overflow: TextOverflow.ellipsis,
                                        style: text.labelMedium?.copyWith(
                                            color: AppColors.darkTextMuted,
                                            fontStyle: email.isEmpty
                                                ? FontStyle.italic
                                                : FontStyle.normal),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (!isGuest)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone_outlined,
                                        size: 13,
                                        color: AppColors.darkTextMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      phone.isNotEmpty
                                          ? phone
                                          : 'Chưa cập nhật',
                                      style: text.labelMedium?.copyWith(
                                          color: AppColors.darkTextMuted,
                                          fontStyle: phone.isEmpty
                                              ? FontStyle.italic
                                              : FontStyle.normal),
                                    ),
                                  ],
                                ),
                              ),
                            if (!isGuest)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  authRepo.expirationDate != null
                                      ? 'Hết hạn: ${authRepo.expirationDate}'
                                      : '$totalPoints ngày sử dụng',
                                  style: text.labelMedium?.copyWith(
                                      color: AppColors.darkTextMuted),
                                ),
                              ),
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
                (Icons.calculate_outlined, 'Tính margin',
                    'Công cụ tính toán đòn bẩy',
                    () => _push(context, const MarginScreenV2())),
                (Icons.bar_chart_rounded, 'Biểu đồ kinh tế',
                    'Hàng hóa, tỷ giá & chỉ số',
                    () => _push(context, const EconomicChartsScreenV2())),
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
                  (Icons.edit_outlined, 'Cập nhật thông tin',
                      'Email, số điện thoại', () {
                    _editProfile(context);
                  }),
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
