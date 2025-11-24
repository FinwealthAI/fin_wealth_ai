import 'package:dio/dio.dart';
import 'package:fin_wealth/config/api_config.dart';

class SearchStockRepository {
  final Dio dio;
  SearchStockRepository(this.dio);


  Future<Map<String, dynamic>> getOverview(String ticker) async {
    final resp = await dio.get('${ApiConfig.mobileApi}/overview/$ticker/');
    return Map<String, dynamic>.from(resp.data);
  }

  

  Future<Map<String, dynamic>> getValuation(String ticker) async {
    final resp = await dio.get('${ApiConfig.mobileApi}/valuation-details/$ticker/');
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> getCompanyRatio(String ticker, [String range = '5y']) async {
    final resp = await dio.get('${ApiConfig.mobileApi}/company-ratio/$ticker/?range=$range');
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> getGrowth(String ticker, [String period = 'quarter']) async {
    final resp = await dio.get('${ApiConfig.mobileApi}/growth/$ticker/?period=$period');
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> getSafety(String ticker, [String range = '5y']) async {
    final resp = await dio.get('${ApiConfig.mobileApi}/safety/$ticker/?range=$range');
    return Map<String, dynamic>.from(resp.data);
  }

  Future<List<dynamic>> getStockNews(String ticker) async {
    final resp = await dio.get('${ApiConfig.mobileApi}/stock-news/$ticker/');
    return List<dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> startWorkflow(String ticker) async {
    final resp = await dio.get('${ApiConfig.mobileApi}/workflow/$ticker/');
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> checkWorkflowStatus(String taskId) async {
    final resp = await dio.get('${ApiConfig.mobileApi}/workflow/status/$taskId/');
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> getUserNews() async {
    final resp = await dio.get(ApiConfig.userNews);
    return Map<String, dynamic>.from(resp.data);
  }


Future<Map<String, dynamic>> markNotification(int pk) async {
  final resp = await dio.get('${ApiConfig.mobileApi}/notifications/mark/$pk/');
  return Map<String, dynamic>.from(resp.data);
}

Future<Map<String, dynamic>> markAllNotifications() async {
  final resp = await dio.get('${ApiConfig.mobileApi}/notifications/mark-all/');
  return Map<String, dynamic>.from(resp.data);
}


}
