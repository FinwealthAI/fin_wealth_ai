import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';

class MindmapScreenV2 extends StatefulWidget {
  const MindmapScreenV2({super.key});

  @override
  State<MindmapScreenV2> createState() => _MindmapScreenV2State();
}

class _MindmapScreenV2State extends State<MindmapScreenV2> {
  String _selected = 'Lãi suất điều hành';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FwAppBar(
        title: 'Sơ đồ kinh tế',
        subtitle: 'Tác động vĩ mô đến cổ phiếu',
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_outlined),
            onPressed: _openTreeDrawer,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          FwCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.brandSecondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.trending_up,
                          color: AppColors.brandSecondaryDark, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(_selected,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(height: 240, child: _buildDualAxisChart()),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: const [
                    _LegendDot(color: AppColors.brandSecondaryDark, label: 'Chỉ số vĩ mô'),
                    _LegendDot(color: AppColors.brandPrimaryDark, label: 'VN-Index'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FwCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tác động',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Khi lãi suất điều hành giảm, dòng tiền có xu hướng dịch chuyển sang kênh chứng khoán. Mối tương quan ngược chiều với VN-Index trong 3 năm gần nhất là -0.62.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: const [
                    FwBadge(label: 'Ngân hàng', tone: FwBadgeTone.info),
                    FwBadge(label: 'Bất động sản', tone: FwBadgeTone.primary),
                    FwBadge(label: 'Chứng khoán', tone: FwBadgeTone.success),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualAxisChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.darkBorder,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: const TextStyle(
                    color: AppColors.darkTextMuted, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 5.5),
              FlSpot(1, 5.3),
              FlSpot(2, 5.0),
              FlSpot(3, 4.7),
              FlSpot(4, 4.5),
              FlSpot(5, 4.2),
            ],
            isCurved: true,
            color: AppColors.brandSecondaryDark,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: const [
              FlSpot(0, 1100),
              FlSpot(1, 1140),
              FlSpot(2, 1180),
              FlSpot(3, 1200),
              FlSpot(4, 1220),
              FlSpot(5, 1253),
            ],
            isCurved: true,
            color: AppColors.brandPrimaryDark,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.brandPrimary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  void _openTreeDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            _TreeNode(label: 'Vĩ mô', isCategory: true),
            _TreeNode(label: 'Lãi suất điều hành', depth: 1),
            _TreeNode(label: 'Tỷ giá USD/VND', depth: 1),
            _TreeNode(label: 'Lạm phát CPI', depth: 1),
            _TreeNode(label: 'Ngành', isCategory: true),
            _TreeNode(label: 'Ngân hàng', depth: 1),
            _TreeNode(label: 'Bất động sản', depth: 1),
            _TreeNode(label: 'Năng lượng', depth: 1),
          ],
        ),
      ),
    );
  }
}

class _TreeNode extends StatelessWidget {
  final String label;
  final int depth;
  final bool isCategory;
  const _TreeNode({required this.label, this.depth = 0, this.isCategory = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(depth * 16.0, 4, 0, 4),
      child: Row(
        children: [
          Icon(
            isCategory ? Icons.folder_open : Icons.timeline,
            size: 16,
            color: isCategory
                ? AppColors.brandPrimaryDark
                : AppColors.darkTextSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: isCategory ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.darkTextPrimary,
              fontSize: isCategory ? 14 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary)),
      ],
    );
  }
}
