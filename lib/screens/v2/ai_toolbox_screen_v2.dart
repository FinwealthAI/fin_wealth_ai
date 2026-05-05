import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';
import '../../widgets/dashboard/ai_toolbox_card.dart';
import 'chat_screen_v2.dart';

class AiToolboxScreenV2 extends StatelessWidget {
  const AiToolboxScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FwAppBar(
        title: 'AI Toolbox',
        subtitle: 'Trợ lý nhanh từ Mr.Wealth',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
        children: [
          AiToolboxCard(
            actions: [
              AiToolboxAction(
                icon: Icons.chat_bubble_outline,
                title: 'Chat nhanh',
                description: 'Hỏi đáp & nhận insight',
                color: AppColors.brandPrimaryDark,
                onTap: () => _openChat(context),
              ),
              AiToolboxAction(
                icon: Icons.insights_outlined,
                title: 'Báo cáo sâu',
                description: 'Phân tích đa chiều mã CP',
                color: AppColors.brandSecondaryDark,
                onTap: () {},
              ),
              AiToolboxAction(
                icon: Icons.speed_outlined,
                title: 'Báo cáo TC',
                description: 'Góc nhìn chuyên gia',
                color: AppColors.successDark,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ChatScreenV2()),
    );
  }
}
