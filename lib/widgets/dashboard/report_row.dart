import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../common/fw_badge.dart';
import '../common/fw_mini_button.dart';

class ReportRow extends StatelessWidget {
  final String ticker;
  final String title;
  final String date;
  final String source;
  final double? targetPrice;
  final VoidCallback? onTap;
  final VoidCallback? onSummarize;
  final VoidCallback? onOpenPdf;

  const ReportRow({
    super.key,
    required this.ticker,
    required this.title,
    required this.date,
    required this.source,
    this.targetPrice,
    this.onTap,
    this.onSummarize,
    this.onOpenPdf,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FwBadge(label: ticker, tone: FwBadgeTone.primary),
                  const SizedBox(width: AppSpacing.sm),
                  FwBadge(label: source, tone: FwBadgeTone.info),
                  const Spacer(),
                  Text(date, style: text.labelSmall),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(title,
                  style: text.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              if (targetPrice != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text('Định giá: ', style: text.bodySmall),
                    Text(
                      targetPrice!.toStringAsFixed(0),
                      style: text.titleSmall
                          ?.copyWith(color: AppColors.successDark),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: FwMiniButton(
                      label: 'Tóm tắt',
                      icon: Icons.auto_awesome,
                      variant: FwMiniButtonVariant.outline,
                      tone: AppColors.brandPrimaryDark,
                      onTap: onSummarize,
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FwMiniButton.primary(
                      label: 'Xem',
                      icon: Icons.arrow_forward,
                      onTap: onTap,
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
