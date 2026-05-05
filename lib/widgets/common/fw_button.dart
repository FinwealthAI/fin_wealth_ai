import 'package:flutter/material.dart';
import '../../theme/theme.dart';

enum FwButtonVariant { primary, secondary, ghost, danger }

enum FwButtonSize { sm, md, lg }

class FwButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final FwButtonVariant variant;
  final FwButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  const FwButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = FwButtonVariant.primary,
    this.size = FwButtonSize.md,
    this.icon,
    this.loading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final (bg, fg, border) = switch (variant) {
      FwButtonVariant.primary => (AppColors.brandPrimary, Colors.white, null),
      FwButtonVariant.secondary => (
          cs.surfaceContainerHighest,
          cs.onSurface,
          cs.outline,
        ),
      FwButtonVariant.ghost => (Colors.transparent, cs.primary, null),
      FwButtonVariant.danger => (AppColors.dangerDark, Colors.white, null),
    };

    final height = switch (size) {
      FwButtonSize.sm => 36.0,
      FwButtonSize.md => 44.0,
      FwButtonSize.lg => 52.0,
    };

    final hPad = switch (size) {
      FwButtonSize.sm => AppSpacing.md,
      FwButtonSize.md => AppSpacing.lg,
      FwButtonSize.lg => AppSpacing.xl,
    };

    final fontSize = switch (size) {
      FwButtonSize.sm => 13.0,
      FwButtonSize.md => 14.0,
      FwButtonSize.lg => 15.0,
    };

    final disabled = onPressed == null || loading;

    Widget content = loading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: fontSize + 4, color: fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          );

    final button = Material(
      color: disabled ? bg.withValues(alpha: 0.5) : bg,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: hPad),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: border != null ? Border.all(color: border) : null,
            boxShadow: variant == FwButtonVariant.primary && !disabled
                ? AppShadows.purpleGlow
                : null,
          ),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
