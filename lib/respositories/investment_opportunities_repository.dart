import 'package:dio/dio.dart';
import 'package:fin_wealth/models/investment_opportunities.dart';
import 'package:fin_wealth/config/api_config.dart';

class InvestmentOpportunitiesRepository {
  final Dio dio;
  InvestmentOpportunitiesRepository(this.dio);


  Future<InvestmentOpportunities?> fetch() async {
    try {
      final resp = await dio.get(ApiConfig.unlockWealth);
      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data;
        // Check if response has new format {success: true, data: {...}}
        if (data is Map<String, dynamic> && data['success'] == true && data['data'] != null) {
          // New API format - extract bubble data from homepage_charts or daily_summary
          final innerData = data['data'] as Map<String, dynamic>;
          
          // If no bubble/gap/rankings in new format, return null and handle gracefully
          if (innerData['bubble'] == null) {
            print('unlock-wealth API: No bubble data in new format');
            return null;
          }
          return InvestmentOpportunities.fromJson(innerData);
        }
        // Old API format - direct parsing
        if (data is Map<String, dynamic> && data['bubble'] != null) {
          return InvestmentOpportunities.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      print('Failed to load opportunities: $e');
      return null;
    }
  }

  Future<DailySummaryData?> fetchDailySummary() async {
    try {
      final resp = await dio.get(ApiConfig.dailyMarketSummary);
      if (resp.statusCode == 200 && resp.data != null && resp.data['success'] == true) {
        final data = resp.data['data'];
        if (data != null && data is Map<String, dynamic>) {
          return DailySummaryData.fromJson(data);
        }
      }
    } catch (e) {
      print('Failed to load daily summary: $e');
    }
    return null;
  }
}

/// Data structure for daily market summary
class DailySummaryData {
  final String date;
  final String aiGeneratedSummary;
  final List<dynamic> newsHighlights;
  final List<ReportHighlight> reportHighlights;
  final List<BubbleOpportunity> bubbleOpportunities;

  DailySummaryData({
    required this.date,
    required this.aiGeneratedSummary,
    required this.newsHighlights,
    required this.reportHighlights,
    required this.bubbleOpportunities,
  });

  factory DailySummaryData.fromJson(Map<String, dynamic> j) {
    return DailySummaryData(
      date: j['date'] as String? ?? '',
      aiGeneratedSummary: j['ai_generated_summary'] as String? ?? '',
      newsHighlights: (j['news_highlights'] as List<dynamic>?) ?? [],
      reportHighlights: ((j['report_highlights'] as List<dynamic>?) ?? [])
          .map((e) => ReportHighlight.fromJson(e as Map<String, dynamic>))
          .toList(),
      bubbleOpportunities: ((j['investment_opportunities'] as Map<String, dynamic>?)?['bubble_opportunities'] as List<dynamic>? ?? [])
          .map((e) => BubbleOpportunity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
