import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class AiToolboxAction {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback? onTap;

  const AiToolboxAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.onTap,
  });
}

/// AI Toolbox — bộ công cụ AI nhanh trên home screen.
/// Match đúng template web: Chat nhanh / Báo cáo sâu / Báo cáo TC.
class AiToolboxCard extends StatelessWidget {
  final List<AiToolboxAction> actions;
  final VoidCallback? onCollapse;

  const AiToolboxCard({
    super.key,
    required this.actions,
    this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandPrimary.withValues(alpha: 0.14),
            AppColors.brandSecondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.brandPrimary,
                      AppColors.brandSecondary,
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.auto_awesome,
                    size: 16, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('AI Toolbox',
                        style: text.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text('Trợ lý nhanh từ Mr.Wealth',
                        style: text.labelSmall),
                  ],
                ),
              ),
              if (onCollapse != null)
                IconButton(
                  onPressed: onCollapse,
                  icon: const Icon(Icons.unfold_less,
                      size: 18, color: AppColors.darkTextMuted),
                  tooltip: 'Thu gọn',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (int i = 0; i < actions.length; i++) ...[
            _ToolboxTile(action: actions[i]),
            if (i != actions.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// Compact pill-button hiển thị mặc định trên home — bấm để bung AI Toolbox.
class AiToolboxCompactButton extends StatelessWidget {
  final VoidCallback? onTap;
  const AiToolboxCompactButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.brandPrimary.withValues(alpha: 0.15),
                  AppColors.brandSecondary.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.brandPrimary.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.brandPrimary,
                        AppColors.brandSecondary,
                      ],
                    ),
                    boxShadow: AppShadows.purpleGlow,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.smart_toy_outlined,
                      size: 16, color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Mở AI Toolbox',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandPrimaryDark,
                    ),
                  ),
                ),
                const Icon(Icons.expand_more,
                    size: 18, color: AppColors.brandPrimaryDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolboxTile extends StatelessWidget {
  final AiToolboxAction action;
  const _ToolboxTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.darkSurface.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: action.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: action.color.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: action.color.withValues(alpha: 0.35),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(action.icon, color: action.color, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      action.title,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.description,
                      style: text.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.darkTextMuted),
            ],
          ),
        ),
      ),
    );
  }
}
