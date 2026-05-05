import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../common/fw_badge.dart';
import '../common/fw_mini_button.dart';

/// Card cho tab "Đang theo dõi" — focus tín hiệu mới + danh sách ticker.
class FollowingStrategyCard extends StatelessWidget {
  final String title;
  final List<String> tickers;
  final int signalsToday;
  final String lastUpdate;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFollow;

  const FollowingStrategyCard({
    super.key,
    required this.title,
    required this.tickers,
    required this.signalsToday,
    required this.lastUpdate,
    this.onTap,
    this.onToggleFollow,
  });

  static const _chipColors = [
    AppColors.brandPrimaryDark,
    AppColors.brandSecondaryDark,
    AppColors.successDark,
    AppColors.warningDark,
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    AppColors.dangerDark,
    Color(0xFFA78BFA),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hasNew = signalsToday > 0;
    final maxChips = 8;
    final shown = tickers.take(maxChips).toList();
    final remaining = tickers.length - shown.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: hasNew
              ? AppColors.successDark.withValues(alpha: 0.3)
              : AppColors.darkBorder,
        ),
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
                  color: AppColors.successDark.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.notifications_active,
                    color: AppColors.successDark, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: text.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    Text('Cập nhật $lastUpdate', style: text.labelSmall),
                  ],
                ),
              ),
              if (hasNew) ...[
                const SizedBox(width: AppSpacing.sm),
                FwBadge(
                  label: '$signalsToday mới',
                  tone: FwBadgeTone.success,
                  icon: Icons.bolt,
                ),
              ],
            ],
          ),
          const Divider(height: AppSpacing.xl),
          if (shown.isEmpty)
            Text('Chưa có cổ phiếu phù hợp', style: text.bodySmall)
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (int i = 0; i < shown.length; i++)
                  _TickerChip(
                    label: shown[i],
                    color: _chipColors[i % _chipColors.length],
                  ),
                if (remaining > 0) _TickerChip.more(count: remaining),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FwMiniButton.soft(
                  label: 'Xem chi tiết',
                  icon: Icons.arrow_forward,
                  onTap: onTap,
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FwMiniButton.soft(
                label: 'Đã theo dõi',
                icon: Icons.check,
                tone: AppColors.successDark,
                onTap: onToggleFollow,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TickerChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isMore;

  const _TickerChip({required this.label, required this.color}) : isMore = false;

  const _TickerChip.more({required int count})
      : label = '+$count',
        color = AppColors.darkTextMuted,
        isMore = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: isMore
            ? null
            : LinearGradient(
                colors: [
                  color.withValues(alpha: 0.18),
                  color.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isMore ? color.withValues(alpha: 0.15) : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
