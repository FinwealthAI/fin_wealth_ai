import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class FwCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? background;
  final Color? borderColor;
  final double radius;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  const FwCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.background,
    this.borderColor,
    this.radius = AppRadius.lg,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = gradient == null ? (background ?? theme.colorScheme.surface) : null;
    final border = borderColor ?? theme.colorScheme.outline;

    final container = Container(
      decoration: BoxDecoration(
        color: bg,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 1),
        boxShadow: boxShadow ?? AppShadows.subtle,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return container;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: container,
      ),
    );
  }
}
