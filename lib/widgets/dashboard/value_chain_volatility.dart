import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../common/fw_mini_button.dart';

class ValueChainItem {
  final String node;
  final double changePct;
  final List<String> impactedSectors;
  final String? note;

  const ValueChainItem({
    required this.node,
    required this.changePct,
    required this.impactedSectors,
    this.note,
  });
}

class ValueChainVolatilityList extends StatelessWidget {
  final List<ValueChainItem> items;
  final ValueChanged<ValueChainItem>? onAnalysis;
  final ValueChanged<ValueChainItem>? onMindmap;

  const ValueChainVolatilityList({
    super.key,
    required this.items,
    this.onAnalysis,
    this.onMindmap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (ctx, i) => _ValueChainCard(
          item: items[i],
          onAnalysis: onAnalysis == null ? null : () => onAnalysis!(items[i]),
          onMindmap: onMindmap == null ? null : () => onMindmap!(items[i]),
        ),
      ),
    );
  }
}

class _ValueChainCard extends StatelessWidget {
  final ValueChainItem item;
  final VoidCallback? onAnalysis;
  final VoidCallback? onMindmap;

  const _ValueChainCard({
    required this.item,
    this.onAnalysis,
    this.onMindmap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final positive = item.changePct >= 0;
    final color = positive ? AppColors.successDark : AppColors.dangerDark;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.darkBorder),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.10),
            AppColors.darkSurface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  positive ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item.node,
                  style: text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${positive ? '+' : ''}${item.changePct.toStringAsFixed(2)}%',
                style: text.titleMedium?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (item.note != null)
            Text(
              item.note!,
              style: text.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            item.impactedSectors.join(' · '),
            style: text.labelSmall?.copyWith(color: AppColors.darkTextMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: FwMiniButton.soft(
                  label: 'Phân tích',
                  icon: Icons.insights,
                  tone: AppColors.brandPrimaryDark,
                  onTap: onAnalysis,
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: FwMiniButton.soft(
                  label: 'Sơ đồ',
                  icon: Icons.account_tree_outlined,
                  tone: AppColors.brandSecondaryDark,
                  onTap: onMindmap,
                  fullWidth: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

