import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../common/fw_mini_button.dart';

enum OpportunityKind { golden, value, wave, waiting }

class OpportunityCard extends StatelessWidget {
  final String ticker;
  final OpportunityKind kind;
  final double score;
  final double changePct;
  final String faStrength;
  final String taStrength;
  final List<IconData> contextIcons;
  final VoidCallback? onTap;
  final VoidCallback? onDetail;

  const OpportunityCard({
    super.key,
    required this.ticker,
    required this.kind,
    required this.score,
    required this.changePct,
    required this.faStrength,
    required this.taStrength,
    this.contextIcons = const [Icons.business, Icons.bolt],
    this.onTap,
    this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final spec = _spec(kind);
    final positive = changePct >= 0;
    final changeColor =
        positive ? AppColors.successDark : AppColors.dangerDark;

    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      ticker,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkTextPrimary,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: spec.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                          color: spec.accent.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      spec.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: spec.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    score.toStringAsFixed(1).replaceAll('.', ','),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    positive ? Icons.show_chart : Icons.trending_down,
                    size: 12,
                    color: changeColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${positive ? '+' : ''}${changePct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: changeColor,
                    ),
                  ),
                  const Spacer(),
                  _LabelValue(
                      label: 'FA',
                      value: faStrength,
                      color: AppColors.brandPrimaryDark),
                  const SizedBox(width: AppSpacing.sm),
                  _LabelValue(
                      label: 'TA',
                      value: taStrength,
                      color: _strengthColor(taStrength)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  for (final icon in contextIcons) ...[
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon,
                          size: 12, color: AppColors.brandPrimaryDark),
                    ),
                    const SizedBox(width: 4),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FwMiniButton.soft(
                  label: 'Chi tiết',
                  icon: Icons.arrow_forward,
                  onTap: onDetail ?? onTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _strengthColor(String value) {
    final v = value.toLowerCase();
    if (v.contains('mạnh') || v.contains('tốt')) return AppColors.successDark;
    if (v.contains('chú ý') || v.contains('trung')) return AppColors.warningDark;
    if (v.contains('yếu') || v.contains('xấu')) return AppColors.dangerDark;
    return AppColors.brandPrimaryDark;
  }

  static _OpportunitySpec _spec(OpportunityKind k) => switch (k) {
        OpportunityKind.golden => const _OpportunitySpec(
            label: 'Cơ hội vàng',
            accent: AppColors.brandPrimaryDark,
          ),
        OpportunityKind.value => const _OpportunitySpec(
            label: 'Giá trị đang nổi',
            accent: AppColors.successDark,
          ),
        OpportunityKind.wave => const _OpportunitySpec(
            label: 'Sóng đang nổi',
            accent: AppColors.warningDark,
          ),
        OpportunityKind.waiting => const _OpportunitySpec(
            label: 'Giá trị chờ thời',
            accent: AppColors.brandSecondaryDark,
          ),
      };
}

class _OpportunitySpec {
  final String label;
  final Color accent;
  const _OpportunitySpec({required this.label, required this.accent});
}

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LabelValue({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.darkTextMuted,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class OpportunityFilterBar extends StatelessWidget {
  /// `kind == null` → pill "Tất cả" (neutral).
  final List<({OpportunityKind? kind, int count})> items;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const OpportunityFilterBar({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (ctx, i) {
          final kind = items[i].kind;
          final accent = kind == null
              ? AppColors.darkTextSecondary
              : OpportunityCard._spec(kind).accent;
          final label = kind == null ? 'Tất cả' : OpportunityCard._spec(kind).label;
          final active = activeIndex == i;
          return Material(
            color: active
                ? accent.withValues(alpha: 0.18)
                : AppColors.darkSurface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                      color: active ? accent : AppColors.darkBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? accent : AppColors.darkTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${items[i].count})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
