import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });
}

class QuickActionsGrid extends StatelessWidget {
  final List<QuickAction> actions;
  const QuickActionsGrid({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          for (final a in actions) ...[
            Expanded(child: _Tile(action: a)),
            if (a != actions.last) const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final QuickAction action;
  const _Tile({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: action.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md, horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(action.icon, color: action.color, size: 18),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                action.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
