import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../common/fw_badge.dart';

class StrategyTickerCard extends StatelessWidget {
  final String ticker;
  final String name;
  final double faScore;
  final double taScore;
  final String summary;
  final bool followed;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFollow;

  const StrategyTickerCard({
    super.key,
    required this.ticker,
    required this.name,
    required this.faScore,
    required this.taScore,
    required this.summary,
    required this.followed,
    this.onTap,
    this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ticker, style: text.titleLarge),
                        Text(name,
                            style: text.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    icon: Icon(
                      followed ? Icons.bookmark : Icons.bookmark_border,
                      color: followed
                          ? AppColors.brandPrimaryDark
                          : AppColors.darkTextMuted,
                    ),
                    onPressed: onToggleFollow,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _ScoreChip(label: 'FA', value: faScore, tone: FwBadgeTone.info),
                  const SizedBox(width: 6),
                  _ScoreChip(
                      label: 'TA', value: taScore, tone: FwBadgeTone.primary),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(summary,
                  style: text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final double value;
  final FwBadgeTone tone;
  const _ScoreChip({required this.label, required this.value, required this.tone});

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      FwBadgeTone.info => AppColors.brandSecondaryDark,
      FwBadgeTone.primary => AppColors.brandPrimaryDark,
      FwBadgeTone.success => AppColors.successDark,
      _ => AppColors.darkTextSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              )),
          const SizedBox(width: 4),
          Text(value.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              )),
        ],
      ),
    );
  }
}
