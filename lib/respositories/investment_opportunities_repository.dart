import 'package:dio/dio.dart';
import 'package:fin_wealth/models/investment_opportunities.dart';
import 'package:fin_wealth/config/api_config.dart';

class InvestmentOpportunitiesRepository {
  final Dio dio;
  InvestmentOpportunitiesRepository(this.dio);


  Future<InvestmentOpportunities> fetch() async {
    final resp = await dio.get(ApiConfig.unlockWealth); // JWT đã được gắn sẵn bởi AuthRepository
    if (resp.statusCode == 200) {
      return InvestmentOpportunities.fromJson(resp.data as Map<String, dynamic>);
    }
    throw Exception('Failed to load opportunities: ${resp.statusCode}');
  }

  Future<DailySummaryData> fetchDailySummary() async {
    final resp = await dio.get(ApiConfig.dailyMarketSummary);
    if (resp.statusCode == 200 && resp.data['success'] == true) {
      return DailySummaryData.fromJson(resp.data['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to load daily summary');
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
