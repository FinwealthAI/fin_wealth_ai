import 'package:dio/dio.dart';
import 'package:fin_wealth/models/investment_opportunities.dart';
import 'package:fin_wealth/config/api_config.dart';

class InvestmentOpportunitiesRepository {
  final Dio dio;
  InvestmentOpportunitiesRepository(this.dio);


  Future<InvestmentOpportunities?> fetch() async {
    try {
      final resp = await dio.get(ApiConfig.unlockWealth);
      if (resp.statusCode == 401) {
        return null; // Session invalid, let UI/AuthBloc handle it
      }
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
      if (resp.statusCode == 401) return null;
      
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
    print('[DEBUG] fetchStrategyDetails called with name: "$name"');
    
    // Try System Screener First
    try {
      // Correct path: filter-stock/api/v1/system-screener/results/
      final resp = await dio.get('/filter-stock/api/v1/system-screener/results/', queryParameters: {'name': name});
      print('[DEBUG] System Screener Response status: ${resp.statusCode}');
      print('[DEBUG] System Screener Response data: ${resp.data}');
      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is Map && data['results'] is List && (data['results'] as List).isNotEmpty) {
           final firstSet = data['results'][0];
           final tickers = firstSet['tickers'] as List<dynamic>? ?? [];
           print('[DEBUG] System Screener found ${tickers.length} tickers');
           return tickers;
        }
      }
    } catch (e) {
      print('[DEBUG] System Screener error: $e');
    }

    // Fallback: User Screener
    try {
      final resp = await dio.get('/filter-stock/api/v1/user-screener/results/', queryParameters: {'name': name});
      print('[DEBUG] User Screener Response status: ${resp.statusCode}');
      print('[DEBUG] User Screener Response data: ${resp.data}');
      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is Map && data['results'] is List && (data['results'] as List).isNotEmpty) {
           final firstSet = data['results'][0];
           final tickers = firstSet['tickers'] as List<dynamic>? ?? [];
           print('[DEBUG] User Screener found ${tickers.length} tickers');
           return tickers;
        }
      }
    } catch (e) {
       print('[DEBUG] User Screener error: $e');
    }
    
    print('[DEBUG] No tickers found for strategy: "$name"');
    return [];
  }

  Future<List<dynamic>> fetchStrategyDetailsById(int id) async {
    try {
      // Use marketplace endpoint with ID and full_data=true
      // querying both 'community' (public) and 'following' (system/private) implies we might need to know the tab
      // But filtering by ID is specific. 'community' tab often includes public ones.
      // Let's try 'community' first as it's for public/marketplace strategies.
      final resp = await dio.get(
        '/filter-stock/api/v1/marketplace/results/',
        queryParameters: {'id': id, 'tab': 'community', 'full_data': 'true'},
      );
      
      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is Map && data['results'] is List && (data['results'] as List).isNotEmpty) {
           final strategyData = data['results'][0]; // The strategy object
           // The ticker list is usually in 'data' field or 'tickers'
           // StrategyCardService.get_card_data usually puts tickers in 'data' for charts, or we might need to check.
           // However based on 'StrategyCardData.fromJson', it maps 'data' from JSON.
           return strategyData['data'] ?? [];
        }
      }
    } catch (e) {
      print('Failed to load strategy details by ID $id: $e');
    }
    return [];
  }

  Future<List<StrategyCardData>> fetchStrategies({required String tab}) async {
    try {
      final resp = await dio.get(
        '/filter-stock/api/v1/marketplace/results/',
        queryParameters: {'tab': tab},
      );
      
      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data;
        if (data is Map && data['results'] is List) {
          return (data['results'] as List)
              .map((e) => StrategyCardData.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      print('Failed to load strategies for tab $tab: $e');
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
