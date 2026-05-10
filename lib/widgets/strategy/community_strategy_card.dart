import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../common/fw_mini_button.dart';

class StrategyCategoryTag {
  final String label;
  final Color color;
  const StrategyCategoryTag({required this.label, required this.color});
}

/// Card cho tab "Cộng đồng" — match đúng template web.
class CommunityStrategyCard extends StatelessWidget {
  final String title;
  final List<StrategyCategoryTag> categoryBadges;
  final String description;
  final int followers;
  final String authorName;
  final String? authorAvatarUrl;
  final List<StrategyCategoryTag> tags;
  final double performance1Y;
  final String performanceLabel;
  final bool followed;
  final VoidCallback? onResult;
  final VoidCallback? onToggleFollow;
  final VoidCallback? onInfo;

  const CommunityStrategyCard({
    super.key,
    required this.title,
    required this.description,
    required this.followers,
    required this.authorName,
    required this.tags,
    required this.performance1Y,
    required this.followed,
    this.categoryBadges = const [],
    this.performanceLabel = '1Y',
    this.authorAvatarUrl,
    this.onResult,
    this.onToggleFollow,
    this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final positive = performance1Y >= 0;
    final perfColor =
        positive ? AppColors.successDark : AppColors.dangerDark;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.darkBorder),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.trending_up,
                    color: AppColors.brandPrimaryDark, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(title, style: text.titleMedium),
                    for (final b in categoryBadges)
                      _CategoryPill(label: b.label, color: b.color),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_alt_outlined,
                      size: 14, color: AppColors.darkTextSecondary),
                  const SizedBox(width: 4),
                  Text(_fmt(followers),
                      style: text.titleSmall
                          ?.copyWith(color: AppColors.darkTextPrimary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  description,
                  style: text.bodyMedium?.copyWith(height: 1.5),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: onInfo,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brandPrimary.withValues(alpha: 0.18),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.info_outline,
                      size: 13, color: AppColors.brandPrimaryDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.2),
                child: Text(
                  authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.brandPrimaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(authorName,
                  style: text.titleSmall
                      ?.copyWith(color: AppColors.darkTextPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in tags)
                _CategoryPill(label: t.label, color: t.color),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: perfColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: perfColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(positive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 12, color: perfColor),
                const SizedBox(width: 4),
                Text(
                  '$performanceLabel: ${positive ? '+' : ''}${performance1Y.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: perfColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FwMiniButton(
                  label: followed ? 'Đang theo dõi' : 'Theo dõi',
                  icon: followed ? Icons.check_circle : Icons.add,
                  variant: FwMiniButtonVariant.outline,
                  tone: followed
                      ? AppColors.successDark
                      : AppColors.brandPrimaryDark,
                  onTap: onToggleFollow,
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FwMiniButton.primary(
                  label: 'Xem chi tiết',
                  icon: Icons.arrow_forward,
                  onTap: onResult,
                  fullWidth: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
