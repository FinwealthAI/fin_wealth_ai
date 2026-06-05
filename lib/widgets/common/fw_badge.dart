import 'package:flutter/material.dart';
import '../../theme/theme.dart';

enum FwBadgeTone { neutral, primary, success, warning, danger, info }

class FwBadge extends StatelessWidget {
  final String label;
  final FwBadgeTone tone;
  final IconData? icon;
  final bool soft;

  const FwBadge({
    super.key,
    required this.label,
    this.tone = FwBadgeTone.neutral,
    this.icon,
    this.soft = true,
  });

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _resolveColors(tone);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: soft ? bg.withValues(alpha: 0.15) : bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: bg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: soft ? fg : Colors.white),
            const SizedBox(width: 4),
          ],
          // Flexible để nhãn dài co lại và ellipsize khi badge bị bó hẹp
          // (vd trong Row có Flexible) — tránh tràn ngang gây vạch overflow.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: soft ? fg : Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _resolveColors(FwBadgeTone t) {
    return switch (t) {
      FwBadgeTone.neutral => (AppColors.darkTextSecondary, AppColors.darkTextMuted),
      FwBadgeTone.primary => (AppColors.brandPrimaryDark, AppColors.brandPrimary),
      FwBadgeTone.success => (AppColors.successDark, AppColors.success),
      FwBadgeTone.warning => (AppColors.warningDark, AppColors.warning),
      FwBadgeTone.danger => (AppColors.dangerDark, AppColors.danger),
      FwBadgeTone.info => (AppColors.brandSecondaryDark, AppColors.brandSecondary),
    };
  }
}
