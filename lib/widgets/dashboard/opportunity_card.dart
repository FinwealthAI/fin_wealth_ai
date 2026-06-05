import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../common/fw_mini_button.dart';

enum OpportunityKind { hasSignal, golden, value, wave, waiting }

class OpportunityCard extends StatelessWidget {
  final String ticker;
  final OpportunityKind kind;
  final double score;
  final double changePct;
  final double? close;
  final String? faLabel;
  final String? taLabel;
  final String? strategyName;
  final IconData? strategyIcon;
  final Color? strategyAccent;
  final String? faTier;
  final String? taTier;
  final double? stopLoss;
  final double? takeProfit;
  final double? winRate;
  final double? profitFactor;
  final double? maxDrawdown;
  final VoidCallback? onTap;
  final VoidCallback? onDetail;

  const OpportunityCard({
    super.key,
    required this.ticker,
    required this.kind,
    required this.score,
    required this.changePct,
    this.close,
    this.faLabel,
    this.taLabel,
    this.strategyName,
    this.strategyIcon,
    this.strategyAccent,
    this.faTier,
    this.taTier,
    this.stopLoss,
    this.takeProfit,
    this.winRate,
    this.profitFactor,
    this.maxDrawdown,
    this.onTap,
    this.onDetail,
  });

  static const _tierLabel = {
    'manh': 'Mạnh',
    'chu_y': 'Chú ý',
    'yeu': 'Yếu',
    'unranked': 'N/A',
  };

  static String _fmtPrice(double p) {
    if (p >= 1000) {
      return '${(p / 1000).toStringAsFixed(1)}k';
    }
    return p.toStringAsFixed(1);
  }

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
              // Row 1: ticker + kind badge
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

              // Row 2: price + change% + WS score badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (close != null) ...[
                    Text(
                      _fmtPrice(close!),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
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
                  // WealthScore badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: spec.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'WS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: spec.accent.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          score.toStringAsFixed(1).replaceAll('.', ','),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: spec.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Row 3: FA / TA labels
              if (faTier != null || taTier != null || faLabel != null || taLabel != null)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (faLabel != null || faTier != null)
                      _labelChip('FA', faLabel ?? (_tierLabel[faTier] ?? faTier ?? ''), faTier),
                    if (taLabel != null || taTier != null)
                      _labelChip('TA', taLabel ?? (_tierLabel[taTier] ?? taTier ?? ''), taTier),
                  ],
                ),

              // Row 4: strategy badge (optional)
              if (strategyName != null && strategyName!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _StrategyIconBadge(
                      icon: strategyIcon ?? Icons.flag_outlined,
                      accent: strategyAccent ?? AppColors.brandPrimaryDark,
                      tooltip: _buildStrategyTooltip(),
                    ),
                  ],
                ),
              ],
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

  String _buildStrategyTooltip() {
    final sb = StringBuffer();
    sb.writeln('Chiến lược: $strategyName');
    if (stopLoss != null) {
      sb.writeln('Cắt lỗ: ${stopLoss!.toStringAsFixed(0)}');
    }
    if (takeProfit != null) {
      sb.writeln('Chốt lời: ${takeProfit!.toStringAsFixed(0)}');
    }
    if (winRate != null) {
      sb.writeln('Tỉ lệ thắng: ${(winRate! * 100).toStringAsFixed(1)}%');
    }
    if (profitFactor != null) {
      sb.writeln('Profit Factor: ${profitFactor!.toStringAsFixed(2)}');
    }
    if (maxDrawdown != null) {
      sb.writeln('Sụt giảm tối đa: ${(maxDrawdown! * 100).toStringAsFixed(1)}%');
    }
    return sb.toString().trim();
  }

  static Widget _labelChip(String prefix, String label, String? tier) {
    Color color;
    switch (tier) {
      case 'manh':
        color = AppColors.successDark;
        break;
      case 'chu_y':
        color = AppColors.warningDark;
        break;
      case 'yeu':
        color = AppColors.dangerDark;
        break;
      case 'unranked':
        color = const Color(0xFF8B5CF6);
        break;
      default:
        color = AppColors.brandPrimaryDark;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(prefix,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.darkTextMuted,
              )),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              )),
        ],
      ),
    );
  }

  static _OpportunitySpec _spec(OpportunityKind k) => switch (k) {
        OpportunityKind.hasSignal => const _OpportunitySpec(
            label: 'Có tín hiệu',
            accent: AppColors.successDark,
          ),
        OpportunityKind.golden => const _OpportunitySpec(
            label: 'Hội tụ TA + FA',
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

class _StrategyIconBadge extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String tooltip;
  const _StrategyIconBadge({
    required this.icon,
    required this.accent,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: GestureDetector(
        onTap: () {
          final messenger = ScaffoldMessenger.maybeOf(context);
          if (messenger != null) {
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                content: Text(tooltip),
                action: SnackBarAction(
                  label: 'Đóng',
                  onPressed: () => messenger.hideCurrentSnackBar(),
                ),
              ),
            );
          }
        },
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
          ),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 14, color: accent),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.info_outline,
                      size: 7, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpportunitySpec {
  final String label;
  final Color accent;
  const _OpportunitySpec({required this.label, required this.accent});
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
