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
      final resp = await dio.get(ApiConfig.unlockWealth);
      if (resp.statusCode == 200 && resp.data != null && resp.data['success'] == true) {
        final data = resp.data['data'];
        if (data != null && data is Map<String, dynamic>) {
          // Flatten data: merge daily_summary + homepage_charts
          final flattened = <String, dynamic>{};
          
          if (data['daily_summary'] != null && data['daily_summary'] is Map<String, dynamic>) {
            flattened.addAll(data['daily_summary']);
          }
          
          if (data['homepage_charts'] != null) {
            flattened['homepage_charts'] = data['homepage_charts'];
          }
          
          return DailySummaryData.fromJson(flattened);
        }
      }
    } catch (e) {
      print('Failed to load daily summary: $e');
    }
    return null;
  }
  Future<List<dynamic>> fetchStrategyDetails(String name) async {
    // Try System Screener First
    try {
      // Correct path: filter-stock/api/v1/system-screener/results/
      final resp = await dio.get('/filter-stock/api/v1/system-screener/results/', queryParameters: {'name': name});
      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is Map && data['results'] is List && (data['results'] as List).isNotEmpty) {
           final firstSet = data['results'][0];
           return firstSet['tickers'] as List<dynamic>? ?? [];
        }
      }
    } catch (_) {
      // Ignore
    }

    // Fallback: User Screener
    try {
      final resp = await dio.get('/filter-stock/api/v1/user-screener/results/', queryParameters: {'name': name});
      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is Map && data['results'] is List && (data['results'] as List).isNotEmpty) {
           final firstSet = data['results'][0];
           return firstSet['tickers'] as List<dynamic>? ?? [];
        }
      }
    } catch (_) {
       // Ignore
    }
    
    return [];
  }
}

/// Data structure for daily market summary
class DailySummaryData {
  final String date;
  final String aiGeneratedSummary;
  final List<dynamic> newsHighlights;
  final List<ReportHighlight> reportHighlights;
  final List<BubbleOpportunity> bubbleOpportunities;
  final List<StrategyCardData> strategyCards;

  DailySummaryData({
    required this.date,
    required this.aiGeneratedSummary,
    required this.newsHighlights,
    required this.reportHighlights,
    required this.bubbleOpportunities,
    required this.strategyCards,
  });

  factory DailySummaryData.fromJson(Map<String, dynamic> j) {
    return DailySummaryData(
      date: j['date'] as String? ?? '',
      aiGeneratedSummary: j['ai_generated_summary'] as String? ?? '',
      newsHighlights: (j['news_highlights'] as List<dynamic>?) ?? [],
      reportHighlights: ((j['report_highlights'] as List<dynamic>?) ?? [])
          .map((e) => ReportHighlight.fromJson(e as Map<String, dynamic>))
          .toList(),
      bubbleOpportunities: [], // Deprecated or mapped from cards if needed
      strategyCards: ((j['homepage_charts'] as List<dynamic>?) ?? [])
          .map((e) => StrategyCardData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
