import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Standard mini action button — DÙNG CHO TẤT CẢ button nhỏ trên các card.
///
/// **Quy ước thiết kế (mobile design system v2)**:
/// - Padding: 8h / 6v (compact)
/// - Icon: 13px
/// - Text: 11px / FontWeight w600
/// - Border radius: AppRadius.sm (8)
/// - Spacing icon→label: 4px
///
/// **Ba variants**:
/// - `gradient` — primary action (purple→blue gradient bg, white text). Vd: "Xem thêm", "Chi tiết".
/// - `soft` — secondary action (tinted bg theo `tone`, text màu tone). Vd: "Phân tích", "Sơ đồ".
/// - `outline` — tertiary action (border + text màu tone). Vd: "Bỏ qua".
enum FwMiniButtonVariant { gradient, soft, outline }

class FwMiniButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final FwMiniButtonVariant variant;
  final Color tone;
  final bool fullWidth;

  const FwMiniButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.variant = FwMiniButtonVariant.soft,
    this.tone = AppColors.brandPrimaryDark,
    this.fullWidth = false,
  });

  /// Shortcut: gradient primary button (purple→blue).
  const FwMiniButton.primary({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.fullWidth = false,
  })  : variant = FwMiniButtonVariant.gradient,
        tone = AppColors.brandPrimaryDark;

  /// Shortcut: soft tinted button (default purple tone).
  const FwMiniButton.soft({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.tone = AppColors.brandPrimaryDark,
    this.fullWidth = false,
  }) : variant = FwMiniButtonVariant.soft;

  @override
  Widget build(BuildContext context) {
    final bgColor = switch (variant) {
      FwMiniButtonVariant.gradient => Colors.transparent,
      FwMiniButtonVariant.soft => tone.withValues(alpha: 0.12),
      FwMiniButtonVariant.outline => Colors.transparent,
    };
    final fgColor = switch (variant) {
      FwMiniButtonVariant.gradient => Colors.white,
      _ => tone,
    };

    final inner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: variant == FwMiniButtonVariant.gradient
            ? const LinearGradient(colors: [
                AppColors.brandPrimary,
                AppColors.brandSecondary,
              ])
            : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: variant == FwMiniButtonVariant.outline
            ? Border.all(color: tone.withValues(alpha: 0.5))
            : null,
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fgColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    final btn = Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: inner,
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
