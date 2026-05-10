import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';
import '../../widgets/dashboard/ai_toolbox_card.dart';
import 'ai_report_screen_v2.dart';
import 'chat_screen_v2.dart';

class AiToolboxScreenV2 extends StatelessWidget {
  const AiToolboxScreenV2({super.key});

  void _openChat(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const ChatScreenV2(),
    ));
  }

  void _openDeepReport(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const AiReportScreenV2(
        mode: AiReportMode.deepReport,
      ),
    ));
  }

  void _openFinancialAnalysis(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const AiReportScreenV2(
        mode: AiReportMode.financialAnalysis,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: const FwAppBar(
        title: 'AI Toolbox',
        subtitle: 'Trợ lý nhanh từ Mr.Wealth',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
        children: [
          // Tool cards
          AiToolboxCard(
            actions: [
              AiToolboxAction(
                icon: Icons.chat_bubble_outline,
                title: 'Chat nhanh',
                description: 'Hỏi đáp & nhận insight từ Mr.Wealth',
                color: AppColors.brandPrimaryDark,
                onTap: () => _openChat(context),
              ),
              AiToolboxAction(
                icon: Icons.insights_outlined,
                title: 'Báo cáo sâu',
                description: 'Phân tích đa chiều mã CP bằng AI',
                color: AppColors.brandSecondaryDark,
                onTap: () => _openDeepReport(context),
              ),
              AiToolboxAction(
                icon: Icons.receipt_long_outlined,
                title: 'Báo cáo TC',
                description: 'Phân tích Báo cáo Tài chính chi tiết',
                color: AppColors.successDark,
                onTap: () => _openFinancialAnalysis(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Tips
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                  color: AppColors.darkBorder.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 6),
                    Text('Mẹo sử dụng',
                        style: text.labelMedium?.copyWith(
                            color: Colors.amber,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildTip(
                    'Báo cáo sâu mất 1–4 phút do AI cần thu thập và tổng hợp nhiều nguồn.'),
                _buildTip(
                    'Báo cáo TC tập trung vào các chỉ số tài chính thực tế của doanh nghiệp.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(
                  color: AppColors.darkTextMuted, fontSize: 13)),
          Expanded(
            child: Text(tip,
                style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 13,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}
