import 'package:dio/dio.dart';
import 'package:fin_wealth/config/api_config.dart';
import 'package:fin_wealth/models/market_evaluation.dart';

class MarketEvaluationRepository {
  final Dio dio;

  MarketEvaluationRepository({required this.dio});

  Future<MarketEvaluation> fetchSnapshot() async {
    final response = await dio.get(ApiConfig.marketEvaluation);
    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Lỗi tải dữ liệu thị trường');
    }
    return MarketEvaluation.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<MarketEvaluationHistoryItem>> fetchHistory({int days = 90}) async {
    final response = await dio.get(ApiConfig.marketEvaluationHistory(days: days));
    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Lỗi tải lịch sử thị trường');
    }
    final list = body['data'] as List<dynamic>;
    return list
        .map((e) => MarketEvaluationHistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
