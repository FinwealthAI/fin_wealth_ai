import 'package:flutter/material.dart';
import 'package:fin_wealth/models/investment_opportunities.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fin_wealth/screens/strategy_detail_screen.dart';

class StrategyCard extends StatelessWidget {
  final StrategyCardData data;
  final double width;
  final double? height;

  const StrategyCard({
    Key? key,
    required this.data,
    this.width = 300,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Wrap content
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.tickerCount} mã cổ phiếu',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                 decoration: BoxDecoration(
                   color: const Color(0xFFEFF6FF),
                   borderRadius: BorderRadius.circular(20),
                 ),
                 child: Row(
                   children: [
                     Icon(Icons.add, size: 14, color: Color(0xFF2563EB)),
                     SizedBox(width: 4),
                     Text(
                       "Theo dõi",
                       style: TextStyle(
                         fontSize: 12,
                         fontWeight: FontWeight.w600,
                         color: Color(0xFF2563EB),
                       ),
                     ),
                   ],
                 ),
              )
            ],
          ),
          const Divider(height: 24),
          
          // Content Area (Dynamic height)
          _buildContent(context),
          
          const SizedBox(height: 12),
          
          // Footer / Description
           if (data.description != null && data.description!.isNotEmpty)
            Text(
              data.description!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 12),
            
            // Actions
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StrategyDetailScreen(
                        title: data.title,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  "Xem chi tiết",
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Always return grid as per user request
    return _buildTickerGrid();
  }

  Widget _buildTickerGrid() {
    // Extract tickers from data. 
    final tickers = data.data.map((e) {
      if (e is Map) {
         return e['ticker']?.toString() ?? e['label']?.toString() ?? '';
      }
      return '';
    }).where((t) => t.isNotEmpty).take(12).toList(); // Limit to 12 or more if full width

    if (tickers.isEmpty) {
      return const Center(child: Text("Không có dữ liệu"));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tickers.map((ticker) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          ticker,
          style: const TextStyle(
             fontWeight: FontWeight.w600,
             color: Color(0xFF374151),
          ),
        ),
      )).toList(),
    );
  }

}
