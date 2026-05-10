import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../config/api_config.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String? avatarUrl;
  final String? premiumLabel;
  final int? daysLeft;
  final String? expirationDate;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final bool hasUnreadNotification;
  final bool lowPointsWarning;
  final VoidCallback? onUpgradeTap;

  const HomeAppBar({
    super.key,
    required this.userName,
    this.avatarUrl,
    this.premiumLabel,
    this.daysLeft,
    this.expirationDate,
    this.onAvatarTap,
    this.onSearchTap,
    this.onNotificationTap,
    this.hasUnreadNotification = false,
    this.lowPointsWarning = false,
    this.onUpgradeTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: AppSpacing.lg,
      title: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: avatarUrl == null
                    ? LinearGradient(colors: [
                        AppColors.brandPrimary,
                        AppColors.brandSecondary,
                      ])
                    : null,
                image: avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl!.startsWith('http')
                            ? avatarUrl!
                            : '${ApiConfig.baseUrl}$avatarUrl'),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: avatarUrl == null
                  ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Chào, $userName 👋',
                    style: text.titleMedium, overflow: TextOverflow.ellipsis),
                if (daysLeft != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 10,
                          color: lowPointsWarning
                              ? AppColors.warningDark
                              : AppColors.brandPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          expirationDate != null
                              ? 'Hết hạn: $expirationDate'
                              : '$daysLeft ngày sử dụng',
                          style: text.labelSmall?.copyWith(
                            color: lowPointsWarning
                                ? AppColors.warningDark
                                : AppColors.darkTextMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (lowPointsWarning) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: onUpgradeTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warningDark,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Nâng cấp',
                                style: text.labelSmall?.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (premiumLabel != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium,
                          size: 11, color: AppColors.warningDark),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          premiumLabel!,
                          style: text.labelSmall?.copyWith(
                              color: AppColors.warningDark,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: onSearchTap,
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: onNotificationTap,
            ),
            if (hasUnreadNotification)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.dangerDark,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
