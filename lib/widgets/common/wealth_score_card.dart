import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'fw_badge.dart';

enum WealthScoreVariant { golden, wave, value }

class WealthScoreCard extends StatelessWidget {
  final WealthScoreVariant variant;
  final String ticker;
  final String name;
  final double score;
  final String tagline;
  final String? changePct;
  final VoidCallback? onTap;

  const WealthScoreCard({
    super.key,
    required this.variant,
    required this.ticker,
    required this.name,
    required this.score,
    required this.tagline,
    this.changePct,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final spec = _spec(variant);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            gradient: LinearGradient(
              colors: [
                spec.bg,
                spec.bg.withValues(alpha: 0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: spec.accent.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: spec.accent.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: spec.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(spec.icon, size: 18, color: spec.accent),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ticker, style: text.titleLarge),
                        Text(
                          name,
                          style: text.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  FwBadge(
                    label: spec.label,
                    tone: spec.tone,
                    icon: spec.badgeIcon,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    score.toStringAsFixed(1),
                    style: text.displayMedium?.copyWith(
                      color: spec.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('/10', style: text.bodySmall),
                  ),
                  const Spacer(),
                  if (changePct != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        changePct!,
                        style: text.titleSmall?.copyWith(color: spec.accent),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(tagline, style: text.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  _VariantSpec _spec(WealthScoreVariant v) => switch (v) {
        WealthScoreVariant.golden => const _VariantSpec(
            bg: AppColors.goldenBg,
            accent: AppColors.goldenAccent,
            label: 'Golden Opportunity',
            tone: FwBadgeTone.primary,
            icon: Icons.workspace_premium,
            badgeIcon: Icons.star,
          ),
        WealthScoreVariant.wave => const _VariantSpec(
            bg: AppColors.waveBg,
            accent: AppColors.waveAccent,
            label: 'Wave Rising',
            tone: FwBadgeTone.success,
            icon: Icons.trending_up,
            badgeIcon: Icons.bolt,
          ),
        WealthScoreVariant.value => const _VariantSpec(
            bg: AppColors.valueBg,
            accent: AppColors.valueAccent,
            label: 'Value Waiting',
            tone: FwBadgeTone.info,
            icon: Icons.account_balance,
            badgeIcon: Icons.savings,
          ),
      };
}

class _VariantSpec {
  final Color bg;
  final Color accent;
  final String label;
  final FwBadgeTone tone;
  final IconData icon;
  final IconData badgeIcon;

  const _VariantSpec({
    required this.bg,
    required this.accent,
    required this.label,
    required this.tone,
    required this.icon,
    required this.badgeIcon,
  });
}
