import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../common/fw_badge.dart';
import '../common/fw_mini_button.dart';

class StrategySummaryCard extends StatelessWidget {
  final String title;
  final String? description;
  final List<String> tickers;
  final int signalsToday;
  final int? followers;
  final double? winRate;
  final bool followed;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFollow;

  const StrategySummaryCard({
    super.key,
    required this.title,
    required this.tickers,
    required this.followed,
    this.description,
    this.signalsToday = 0,
    this.followers,
    this.winRate,
    this.onTap,
    this.onToggleFollow,
  });

  // Palette dùng cho ticker chips (rotating).
  static const _chipColors = [
    AppColors.brandPrimaryDark,
    AppColors.brandSecondaryDark,
    AppColors.successDark,
    AppColors.warningDark,
    Color(0xFFEC4899), // pink
    Color(0xFF06B6D4), // cyan
    AppColors.dangerDark,
    Color(0xFFA78BFA), // violet
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final maxChips = 8;
    final shown = tickers.take(maxChips).toList();
    final remaining = tickers.length - shown.length;

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
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(title,
                    style: text.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
              if (signalsToday > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                FwBadge(
                  label: '$signalsToday tín hiệu',
                  tone: FwBadgeTone.success,
                ),
              ],
            ],
          ),
          const Divider(height: AppSpacing.xl),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text('Chưa có cổ phiếu phù hợp', style: text.bodySmall),
            )
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
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              description!,
              style: text.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.darkTextMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (followers != null || winRate != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (followers != null)
                  _MiniStat(label: 'Followers', value: '$followers'),
                if (followers != null && winRate != null)
                  const SizedBox(width: AppSpacing.lg),
                if (winRate != null)
                  _MiniStat(
                    label: 'Win-rate',
                    value: '${winRate!.toStringAsFixed(0)}%',
                    color: AppColors.successDark,
                  ),
              ],
            ),
          ],
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
                label: followed ? 'Đang theo dõi' : 'Theo dõi',
                icon: followed ? Icons.check : Icons.add,
                tone: followed
                    ? AppColors.successDark
                    : AppColors.brandSecondaryDark,
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

  const _TickerChip({required this.label, required this.color})
      : isMore = false;

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

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _MiniStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: text.labelSmall),
        const SizedBox(width: 4),
        Text(value,
            style: text.labelMedium?.copyWith(
              color: color ?? AppColors.darkTextPrimary,
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }
}
