import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../common/fw_badge.dart';

class ProfileBar extends StatelessWidget {
  final String userName;
  final String? avatarUrl;
  final String? riskAppetite;
  final String? goal;
  final String? horizon;

  const ProfileBar({
    super.key,
    required this.userName,
    this.avatarUrl,
    this.riskAppetite,
    this.goal,
    this.horizon,
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
                ? NetworkImage(avatarUrl!)
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
