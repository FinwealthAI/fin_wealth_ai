import 'package:dio/dio.dart';
import 'package:fin_wealth/models/watchlist_item.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:fin_wealth/config/api_config.dart';

class WatchlistRepository {
  final Dio dio;

  WatchlistRepository({required this.dio});


  Future<List<WatchlistItem>> getWatchlist() async {
    try {
      // The web endpoint returns HTML
      final response = await dio.get(
        ApiConfig.watchlistGetContent,
        options: Options(
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final htmlContent = response.data.toString();
        print('Watchlist HTML: $htmlContent'); // Debug logging
        return _parseWatchlistHtml(htmlContent);
      } else {
        throw Exception('Failed to load watchlist: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load watchlist: $e');
    }
  }

  List<WatchlistItem> _parseWatchlistHtml(String html) {
    final document = html_parser.parse(html);
    final List<WatchlistItem> items = [];

    // The HTML structure is:
    // <div class="col-6 col-md-3">
    //   <div class="badge ...">
    //     <span>TICKER</span>
    //     <a class="remove-watchlist-item" data-id="ID">×</a>
    //   </div>
    // </div>
    
    // Find all remove buttons
    final removeBtns = document.querySelectorAll('.remove-watchlist-item');
    
    for (var btn in removeBtns) {
      // Get the ID from data-id attribute
      final idStr = btn.attributes['data-id'];
      final id = int.tryParse(idStr ?? '') ?? 0;
      
      // The ticker is in a <span> sibling element
      // Navigate to parent (the badge div) and find the span
      final parent = btn.parent;
      if (parent != null) {
        final spanElement = parent.querySelector('span');
        if (spanElement != null) {
          final ticker = spanElement.text.trim();
          items.add(WatchlistItem(
            id: id,
            ticker: ticker,
            // Price info not available in this HTML
          ));
        }
      }
    }

    return items;
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
