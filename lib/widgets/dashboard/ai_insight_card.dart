import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../common/fw_badge.dart';
import '../common/fw_mini_button.dart';

enum MarketSentiment { bullish, neutral, bearish }

class AiInsightCard extends StatelessWidget {
  final String headline;
  final String summary;
  final double vnIndex;
  final double vnIndexChangePct;
  final MarketSentiment sentiment;
  final String publishedAt;
  final VoidCallback? onReadMore;
  final VoidCallback? onAskAI;

  const AiInsightCard({
    super.key,
    required this.headline,
    required this.summary,
    required this.vnIndex,
    required this.vnIndexChangePct,
    required this.sentiment,
    required this.publishedAt,
    this.onReadMore,
    this.onAskAI,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final positive = vnIndexChangePct >= 0;
    final changeColor =
        positive ? AppColors.successDark : AppColors.dangerDark;
    final (sentimentLabel, sentimentTone) = switch (sentiment) {
      MarketSentiment.bullish => ('Tươi sáng', FwBadgeTone.success),
      MarketSentiment.neutral => ('Trung lập', FwBadgeTone.warning),
      MarketSentiment.bearish => ('Bi quan', FwBadgeTone.danger),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandPrimary.withValues(alpha: 0.16),
            AppColors.darkSurface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:
            Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.brandPrimaryDark, width: 1.5),
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.brandPrimary,
                      AppColors.brandSecondary,
                    ],
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/mr_wealth_avatar.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Mr.Wealth',
                        style: text.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text('Nhận định hôm nay · $publishedAt',
                        style: text.labelSmall),
                  ],
                ),
              ),
              FwBadge(label: sentimentLabel, tone: sentimentTone),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            headline,
            style: text.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 8),
            decoration: BoxDecoration(
              color: changeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: changeColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(
                  positive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: changeColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'VN-Index',
                  style: text.labelMedium
                      ?.copyWith(color: AppColors.darkTextSecondary),
                ),
                const SizedBox(width: 6),
                Text(
                  vnIndex.toStringAsFixed(2),
                  style: text.titleSmall?.copyWith(
                    color: AppColors.darkTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${positive ? '+' : ''}${vnIndexChangePct.toStringAsFixed(2)}%',
                  style: text.titleSmall?.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: FwMiniButton.soft(
              label: 'Xem thêm',
              icon: Icons.menu_book_outlined,
              onTap: onReadMore,
            ),
          ),
        ],
      ),
    );
  }
}
