import 'package:dio/dio.dart';
import 'package:fin_wealth/models/market_report.dart';
import 'package:fin_wealth/config/api_config.dart';

class MarketRepository {
  final Dio dio;


  MarketRepository({required this.dio});

  Future<List<MarketReport>> fetchMarketReports() async {
    try {
      final response = await dio.get(ApiConfig.marketReports);
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList.map((json) => MarketReport.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('401: Chưa xác thực hoặc token đã hết hạn.');
      } else {
        throw Exception('Failed to load market reports: ${response.statusCode}');
      }
    } on DioError catch (e) {
      if (e.response != null) {
        if (e.response!.statusCode == 401) {
          throw Exception('401: Chưa xác thực hoặc token đã hết hạn.');
        }
        throw Exception('Failed to load market reports: ${e.response!.statusCode} - ${e.response!.data}');
      } else {
        throw Exception('Failed to load market reports: ${e.message}');
      }
    }
  }
}
