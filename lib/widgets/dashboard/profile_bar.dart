import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../config/api_config.dart';
import '../common/fw_badge.dart';

class ProfileBar extends StatelessWidget {
  final String userName;
  final String? avatarUrl;
  final String? riskAppetite;
  final String? goal;
  final String? horizon;
  final int? daysLeft;
  final String? expirationDate;
  final bool lowPointsWarning;
  final VoidCallback? onUpgradeTap;

  const ProfileBar({
    super.key,
    required this.userName,
    this.avatarUrl,
    this.riskAppetite,
    this.goal,
    this.horizon,
    this.daysLeft,
    this.expirationDate,
    this.lowPointsWarning = false,
    this.onUpgradeTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandPrimary.withValues(alpha: 0.18),
            AppColors.brandSecondary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.2),
            backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                ? NetworkImage(avatarUrl!.startsWith('http')
                    ? avatarUrl!
                    : '${ApiConfig.baseUrl}$avatarUrl')
                : null,
            child: avatarUrl == null || avatarUrl!.isEmpty
                ? Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: text.titleLarge?.copyWith(color: AppColors.brandPrimaryDark),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chào, $userName 👋', style: text.titleMedium),
                if (daysLeft != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 11,
                          color: lowPointsWarning
                              ? AppColors.warningDark
                              : AppColors.brandPrimaryDark,
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
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onUpgradeTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.warningDark,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Nâng cấp',
                                style: text.labelSmall?.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (riskAppetite != null)
                      FwBadge(label: riskAppetite!, tone: FwBadgeTone.primary),
                    if (goal != null)
                      FwBadge(label: goal!, tone: FwBadgeTone.info),
                    if (horizon != null)
                      FwBadge(label: horizon!, tone: FwBadgeTone.neutral),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
