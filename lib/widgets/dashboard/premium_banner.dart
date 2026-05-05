import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../common/fw_button.dart';

class PremiumBanner extends StatelessWidget {
  final int daysLeft;
  final VoidCallback? onUpgrade;
  final VoidCallback? onDismiss;

  const PremiumBanner({
    super.key,
    required this.daysLeft,
    this.onUpgrade,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB45309), Color(0xFFFBBF24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: Colors.white, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Còn $daysLeft ngày dùng thử Premium',
                    style: text.titleMedium?.copyWith(color: Colors.white)),
                Text('Mở khoá WealthScore + AI Insight không giới hạn',
                    style: text.bodySmall
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FwButton(
            label: 'Nâng cấp',
            size: FwButtonSize.sm,
            variant: FwButtonVariant.secondary,
            onPressed: onUpgrade,
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
