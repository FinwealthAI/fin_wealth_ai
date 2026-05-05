import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class FwFilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final IconData? icon;
  final VoidCallback onTap;

  const FwFilterPill({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: active
                ? AppColors.brandPrimary
                : AppColors.darkSurfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: active ? AppColors.brandPrimary : AppColors.darkBorder,
            ),
            boxShadow: active ? AppShadows.purpleGlow : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: active ? Colors.white : AppColors.darkTextSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FwFilterPillBar extends StatelessWidget {
  final List<String> items;
  final int activeIndex;
  final ValueChanged<int> onChanged;
  final EdgeInsetsGeometry padding;

  const FwFilterPillBar({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (ctx, i) => FwFilterPill(
          label: items[i],
          active: activeIndex == i,
          onTap: () => onChanged(i),
        ),
      ),
    );
  }
}
