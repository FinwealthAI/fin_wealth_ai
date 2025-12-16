import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AiInsightCard extends StatelessWidget {
  final Map<String, dynamic> overviewData;
  final Map<String, dynamic> technicalData;
  final Function() onChatPressed;
  final Function() onReportPressed;

  const AiInsightCard({
    super.key,
    required this.overviewData,
    required this.technicalData,
    required this.onChatPressed,
    required this.onReportPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Extract Trend
    final expertView = technicalData['data']?['expert_view'];
    final trend = expertView?['trend']?['direction'] ?? '---';
    
    // Extract Upside (Valuation)
    // Parse using helper
    final upSizeVal = _parseValue(overviewData['up_size']);
    String upsideStr = '---';
    
    // Check if original value exists to decide if we show --- or value
    if (overviewData['up_size'] != null) {
        upsideStr = '${upSizeVal > 0 ? '+' : ''}${NumberFormat("0.##", "en_US").format(upSizeVal)}%';
    }

    // Determine colors
    Color trendColor = Colors.grey;
    if (trend == 'UPTREND' || trend == 'BULLISH') trendColor = Colors.green;
    else if (trend == 'DOWNTREND' || trend == 'BEARISH') trendColor = Colors.red;
    else if (trend == 'SIDEWAY') trendColor = Colors.orange;

    Color upsideColor = Colors.grey;
    if (overviewData['up_size'] != null) {
      if (upSizeVal > 15) upsideColor = Colors.green;
      else if (upSizeVal > 0) upsideColor = Colors.blue;
      else upsideColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badges Section (Left)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Insight',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildBadge('Kỹ thuật', trend, trendColor),
                          _buildBadge('Định giá', upsideStr, upsideColor),
                        ],
                      ),
                    ],
                  ),
                ),
                // Avatar Section (Right)
                CircleAvatar(
                  radius: 32,
                  backgroundImage: const AssetImage('assets/images/mr_wealth_avatar.png'), // Ensure asset exists or use fallback
                  backgroundColor: Colors.blueAccent.withOpacity(0.1),
                  onBackgroundImageError: (_, __) {},
                  child: const Text(''), // Fallback if image fails, transparent
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onChatPressed,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Hỏi M.A.I'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReportPressed,
                    icon: const Icon(Icons.assessment_outlined),
                    label: const Text('Xem Báo cáo'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
             label, 
             style: TextStyle(
               fontSize: 10, 
               color: Colors.grey[600],
               fontWeight: FontWeight.w500
             )
           ),
           const SizedBox(height: 2),
           Text(
             value, 
             style: TextStyle(
               color: color, 
               fontWeight: FontWeight.bold, 
               fontSize: 13
             )
           ),
        ],
      ),
    );
  }
}

double _parseValue(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) {
    if (value.isEmpty) return 0.0;
    String clean = value.replaceAll(',', '');
    return double.tryParse(clean) ?? 0.0;
  }
  return 0.0;
}
