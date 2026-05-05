import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../common/fw_badge.dart';

enum SignalKind { buy, sell, watch }

class SignalRow extends StatelessWidget {
  final String date;
  final String ticker;
  final SignalKind kind;
  final String strategy;
  final VoidCallback? onTap;

  const SignalRow({
    super.key,
    required this.date,
    required this.ticker,
    required this.kind,
    required this.strategy,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (label, tone, icon) = switch (kind) {
      SignalKind.buy => ('MUA', FwBadgeTone.success, Icons.trending_up),
      SignalKind.sell => ('BÁN', FwBadgeTone.danger, Icons.trending_down),
      SignalKind.watch => ('THEO DÕI', FwBadgeTone.warning, Icons.visibility),
    };

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
            SizedBox(
              width: 56,
              child: Text(date, style: text.bodySmall),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 56,
              child: Text(ticker, style: text.titleMedium),
            ),
            const SizedBox(width: AppSpacing.sm),
            FwBadge(label: label, tone: tone, icon: icon),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                strategy,
                style: text.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
