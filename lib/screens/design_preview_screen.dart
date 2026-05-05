import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../widgets/common/common.dart';

class DesignPreviewScreen extends StatelessWidget {
  const DesignPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Hôm nay', style: text.bodySmall),
          const SizedBox(height: 4),
          Text('Cơ hội đầu tư', style: text.displayMedium),
          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'WealthScore TB',
                  value: '7.8',
                  delta: '+0.4',
                  positive: true,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricTile(
                  label: 'Tín hiệu hôm nay',
                  value: '12',
                  delta: '+3',
                  positive: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Cổ phiếu nổi bật', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.md),

          const WealthScoreCard(
            variant: WealthScoreVariant.golden,
            ticker: 'VNM',
            name: 'Vinamilk',
            score: 8.7,
            tagline: 'Cơ hội vàng — định giá hấp dẫn + dòng tiền vào mạnh',
            changePct: '+2.3%',
          ),
          const SizedBox(height: AppSpacing.md),
          const WealthScoreCard(
            variant: WealthScoreVariant.wave,
            ticker: 'FPT',
            name: 'FPT Corporation',
            score: 8.2,
            tagline: 'Sóng tăng — momentum mạnh, breakout MA20',
            changePct: '+3.8%',
          ),
          const SizedBox(height: AppSpacing.md),
          const WealthScoreCard(
            variant: WealthScoreVariant.value,
            ticker: 'HPG',
            name: 'Hòa Phát Group',
            score: 7.4,
            tagline: 'Giá trị chờ đợi — P/E thấp, tích lũy nền',
            changePct: '+0.6%',
          ),

          const SizedBox(height: AppSpacing.xl),
          Text('Filter', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: const [
              FwBadge(label: 'Tất cả', tone: FwBadgeTone.primary, soft: false),
              FwBadge(label: 'Theo dõi', tone: FwBadgeTone.neutral),
              FwBadge(label: 'Pullback', tone: FwBadgeTone.info),
              FwBadge(label: 'Breakout', tone: FwBadgeTone.success),
              FwBadge(label: 'Cảnh báo', tone: FwBadgeTone.warning),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),
          FwCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppColors.brandPrimaryDark,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('AI Insight', style: text.titleMedium),
                    const Spacer(),
                    const FwBadge(label: 'Mới', tone: FwBadgeTone.primary),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Mr.Wealth phát hiện 3 cổ phiếu phù hợp khẩu vị Tăng trưởng của bạn dựa trên phân tích kỹ thuật + cơ bản hôm nay.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    FwButton(
                      label: 'Xem ngay',
                      icon: Icons.arrow_forward,
                      onPressed: () {},
                    ),
                    const SizedBox(width: AppSpacing.md),
                    FwButton(
                      label: 'Bỏ qua',
                      variant: FwButtonVariant.ghost,
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          Text('Loading state', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          const FwSkeleton(height: 80, radius: AppRadius.lg),
          const SizedBox(height: AppSpacing.sm),
          const FwSkeleton.line(width: 200),
          const SizedBox(height: AppSpacing.xs),
          const FwSkeleton.line(width: 140),

          const SizedBox(height: AppSpacing.xl),
          Text('Empty state', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          FwCard(
            child: FwEmptyState(
              icon: Icons.search_off,
              title: 'Chưa có dữ liệu',
              message: 'Thử thay đổi bộ lọc để xem nhiều kết quả hơn.',
              action: FwButton(
                label: 'Đặt lại bộ lọc',
                variant: FwButtonVariant.secondary,
                size: FwButtonSize.sm,
                onPressed: () {},
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final bool positive;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.delta,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = positive ? AppColors.successDark : AppColors.dangerDark;

    return FwCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: text.headlineLarge),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  delta,
                  style: text.labelMedium?.copyWith(color: accent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
