import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class WatchlistRow extends StatelessWidget {
  final String ticker;
  final double price;
  final double changePct;
  final String? faTier;
  final String? taTier;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const WatchlistRow({
    super.key,
    required this.ticker,
    required this.price,
    required this.changePct,
    this.faTier,
    this.taTier,
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
            // Ticker + FA/TA chips
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticker,
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (faTier != null && faTier != 'unranked')
                        _TierChip(label: 'FA', tier: faTier!),
                      if (faTier != null && faTier != 'unranked' &&
                          taTier != null && taTier != 'unranked')
                        const SizedBox(width: 4),
                      if (taTier != null && taTier != 'unranked')
                        _TierChip(label: 'TA', tier: taTier!),
                      if ((faTier == null || faTier == 'unranked') &&
                          (taTier == null || taTier == 'unranked'))
                        Text('Chưa có dữ liệu',
                            style: text.bodySmall
                                ?.copyWith(color: AppColors.darkTextMuted)),
                    ],
                  ),
                ],
              ),
            ),
            // Price + change pill
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price >= 1000
                      ? '${(price / 1000).toStringAsFixed(1)}k'
                      : price.toStringAsFixed(2),
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
}

class _TierChip extends StatelessWidget {
  final String label;
  final String tier;

  const _TierChip({required this.label, required this.tier});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (color, tierLabel) = _resolve(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label $tierLabel',
        style: text.labelSmall?.copyWith(color: color, fontSize: 10),
      ),
    );
  }

  static (Color, String) _resolve(String tier) {
    return switch (tier.toLowerCase()) {
      'manh' => (AppColors.successDark, 'Mạnh'),
      'chu_y' => (AppColors.warningDark, 'Chú ý'),
      _ => (AppColors.darkTextMuted, '—'),
    };
  }
}
