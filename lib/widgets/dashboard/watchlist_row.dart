import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class WatchlistRow extends StatelessWidget {
  final String ticker;
  final double price;
  final double changePct;
  final String? faTier;
  final String? taTier;
  final String? faLabel;
  final String? taLabel;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const WatchlistRow({
    super.key,
    required this.ticker,
    required this.price,
    required this.changePct,
    this.faTier,
    this.taTier,
    this.faLabel,
    this.taLabel,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final positive = changePct >= 0;
    final color = positive ? AppColors.successDark : AppColors.dangerDark;

    final showFa = faTier != null && faTier != 'unranked';
    final showTa = taTier != null && taTier != 'unranked';

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
            // Ticker + FA/TA chips
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticker,
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  if (showFa || showTa)
                    Row(
                      children: [
                        if (showFa)
                          _LabelChip(
                            prefix: 'FA',
                            label: faLabel ?? _tierText(faTier!),
                            tier: faTier!,
                          ),
                        if (showFa && showTa) const SizedBox(width: 4),
                        if (showTa)
                          _LabelChip(
                            prefix: 'TA',
                            label: taLabel ?? _tierText(taTier!),
                            tier: taTier!,
                          ),
                      ],
                    )
                  else
                    Text('Chưa có dữ liệu',
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.darkTextMuted)),
                ],
              ),
            ),
            // Price + change pill
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${price.toStringAsFixed(1)}k',
                  style: text.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          positive
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          size: 16,
                          color: color),
                      Text(
                        '${positive ? '+' : ''}${changePct.toStringAsFixed(2)}%',
                        style: text.titleSmall?.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
              ],
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

  static String _tierText(String tier) => switch (tier) {
        'manh' => 'Mạnh',
        'chu_y' => 'Chú ý',
        _ => 'N/A',
      };
}

class _LabelChip extends StatelessWidget {
  final String prefix;
  final String label;
  final String tier;

  const _LabelChip({
    required this.prefix,
    required this.label,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (tier) {
      'manh' => AppColors.successDark,
      'chu_y' => AppColors.warningDark,
      _ => AppColors.brandPrimaryDark,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            prefix,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextMuted,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
