import 'package:dio/dio.dart';
import 'package:fin_wealth/models/watchlist_item.dart';

import 'package:fin_wealth/config/api_config.dart';

class WatchlistRepository {
  final Dio dio;

  WatchlistRepository({required this.dio});


  Future<List<WatchlistItem>> getWatchlist() async {
    try {
      final response = await dio.get(
        ApiConfig.watchlistGet,
        options: Options(
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        // Handle format: {"success": true, "data": [...]}
        if (response.data is Map && response.data['data'] is List) {
          final List<dynamic> data = response.data['data'];
          return data.map((json) => WatchlistItem.fromJson(json)).toList();
        } 
        // Handle format: [...] (Direct list)
        else if (response.data is List) {
          final List<dynamic> data = response.data;
          return data.map((json) => WatchlistItem.fromJson(json)).toList();
        } else {
          throw Exception('Invalid response format: Expected Map with "data" or List, got ${response.data.runtimeType}');
        }
      } else {
        throw Exception('Failed to load watchlist: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load watchlist: $e');
    }
  }

  Future<void> addToWatchlist(String ticker) async {
    try {
      final formData = FormData.fromMap({
        'tickers': ticker,
      });
      
      final response = await dio.post(
        ApiConfig.watchlistAdd,
        data: formData,
        options: Options(
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
            // CSRF might be needed if not using JWT or if backend requires it.
            // But AuthRepository adds Bearer token.
            // If backend checks CSRF cookie, we might fail.
            // Let's hope it accepts JWT without CSRF or we need to fetch CSRF token.
          },
        ),
      );

      if (response.statusCode != 200) {
         if (response.data is Map && response.data['success'] == false) {
             throw Exception(response.data['message'] ?? 'Failed to add to watchlist');
        }
      }
    } catch (e) {
      throw Exception('Failed to add to watchlist: $e');
    }
  }

  Future<void> removeFromWatchlist(int id) async {
    try {
      final response = await dio.post(
        ApiConfig.watchlistRemove(id),
         options: Options(
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
          },
        ),
      );
      
      if (response.statusCode != 200) {
         if (response.data is Map && response.data['success'] == false) {
             throw Exception(response.data['message'] ?? 'Failed to remove from watchlist');
        }
      }
    } catch (e) {
      throw Exception('Failed to remove from watchlist: $e');
    }
  }
}
