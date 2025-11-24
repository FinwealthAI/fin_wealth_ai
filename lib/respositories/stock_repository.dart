import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:fin_wealth/models/stock_models.dart';
import 'package:fin_wealth/config/api_config.dart';

class StockRepository {
  final Dio dio;


  StockRepository({required this.dio}) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.next(options);
        },
        onResponse: (response, handler) {
          handler.next(response);
        },
        onError: (e, handler) {
          handler.next(e);
        },
      ),
    );
  }

  Future<Stock> searchStocks(String stockSymbol) async {
    try {
      final response = await dio.get(
        ApiConfig.stockReports,
        queryParameters: {'stock': stockSymbol},
      );
      if (response.headers.value('content-type')?.contains('application/json') == true) {
        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonMap = response.data is String
              ? json.decode(response.data)
              : response.data;
          final stock = Stock.fromJson(jsonMap);
          return stock;
        } else {
          throw Exception('Failed to load stocks: ${response.statusCode}');
        }
      } else {
        throw Exception('Unexpected response format: ${response.headers.value('content-type')}');
      }
    } on DioError catch (e) {
      if (e.response != null) {
        throw Exception('Failed to load stocks: ${e.response!.data}');
      } else {
        throw Exception('Failed to load stocks: ${e.message}');
      }
    }
  }

  Future<List<StockValuation>> fetchStockValuations() async {
    final response = await dio.get(ApiConfig.stockReports);
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => StockValuation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load stock valuations');
    }
  }
}
