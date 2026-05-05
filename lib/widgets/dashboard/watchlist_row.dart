import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class WatchlistRow extends StatelessWidget {
  final String ticker;
  final double price;
  final double changePct;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const WatchlistRow({
    super.key,
    required this.ticker,
    required this.price,
    required this.changePct,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final positive = changePct >= 0;
    final color = positive ? AppColors.successDark : AppColors.dangerDark;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.darkBorder, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: Text(ticker.substring(0, 1),
                  style: text.titleMedium
                      ?.copyWith(color: AppColors.brandPrimaryDark)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticker, style: text.titleMedium),
                  Text(price.toStringAsFixed(2), style: text.bodySmall),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(positive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      size: 16, color: color),
                  Text(
                    '${positive ? '+' : ''}${changePct.toStringAsFixed(2)}%',
                    style: text.titleSmall?.copyWith(color: color),
                  ),
                ],
              ),
            ),
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.close,
                    size: 18, color: AppColors.darkTextMuted),
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}
