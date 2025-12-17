import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fin_wealth/respositories/watchlist_repository.dart';
import 'package:fin_wealth/models/watchlist_item.dart';
import 'package:intl/intl.dart';

class StockHeaderSliver extends StatefulWidget {
  final Map<String, dynamic> overviewData;
  final String ticker;

  const StockHeaderSliver({
    super.key,
    required this.overviewData,
    required this.ticker,
  });

  @override
  State<StockHeaderSliver> createState() => _StockHeaderSliverState();
}

class _StockHeaderSliverState extends State<StockHeaderSliver> {
  bool _isFollowing = false;
  int? _watchlistItemId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkWatchlistStatus();
  }

  Future<void> _checkWatchlistStatus() async {
    try {
      final repo = context.read<WatchlistRepository>();
      final items = await repo.getWatchlist();
      final item = items.firstWhere(
        (element) => element.ticker == widget.ticker, 
        orElse: () => WatchlistItem(id: -1, ticker: ''),
      );

      if (mounted) {
        if (item.id != -1) {
          setState(() {
            _isFollowing = true;
            _watchlistItemId = item.id;
          });
        } else {
          setState(() {
            _isFollowing = false;
            _watchlistItemId = null;
          });
        }
      }
    } catch (e) {
      print('Error checking watchlist: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final repo = context.read<WatchlistRepository>();
    try {
      if (_isFollowing) {
        if (_watchlistItemId != null) {
          await repo.removeFromWatchlist(_watchlistItemId!);
          setState(() {
            _isFollowing = false;
            _watchlistItemId = null;
          });
          _showToast('Đã bỏ theo dõi');
        }
      } else {
        await repo.addToWatchlist(widget.ticker);
        // We need to re-fetch to get the ID for the next remove
        await _checkWatchlistStatus();
        _showToast('Đã thêm vào danh sách theo dõi');
      }
    } catch (e) {
      _showToast('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = _parseValue(widget.overviewData['price']);
    final change = _parseValue(widget.overviewData['change']);
    final changePercent = _parseValue(widget.overviewData['change_percent']);

    final priceFmt = NumberFormat('#,##0', 'vi_VN').format(price);
    final changeFmt = NumberFormat('#,##0', 'vi_VN').format(change.abs());
    final changePercentFmt = NumberFormat('0.00', 'vi_VN').format(changePercent.abs());
    
    final isUp = change >= 0;
    final color = isUp ? Colors.green : Colors.red;
    final prefix = isUp ? '+' : '-';

    return SliverAppBar(
      pinned: true,
      expandedHeight: 100.0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      leading: null,

      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
        expandedTitleScale: 1.2,
        title: LayoutBuilder(
          builder: (context, constraints) {
             return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.ticker, 
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold, 
                        color: theme.colorScheme.primary,
                        fontSize: 26, 
                      )
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      icon: _isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(_isFollowing ? Icons.star : Icons.star_border, color: Colors.amber),
                      onPressed: _toggleFollow,
                    ),
                  ],
                ),
              ],
            );
          }
        ),
        background: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.end,
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.end,
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Text(
                         priceFmt,
                         style: theme.textTheme.titleLarge?.copyWith(
                           fontWeight: FontWeight.bold,
                           color: theme.colorScheme.onSurface,
                         ),
                       ),
                       Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Icon(
                             isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                             color: color,
                           ),
                           Text(
                             '$prefix$changeFmt ($prefix$changePercentFmt%)',
                             style: TextStyle(
                               color: color,
                               fontWeight: FontWeight.w600,
                             ),
                           ),
                         ],
                       ),
                     ],
                   ),
                 ],
               )
            ],
          ),
        ),
      ),
    );
  }
}

double _parseValue(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) {
    if (value.isEmpty) return 0.0;
    String clean = value.replaceAll(',', '');
    return double.tryParse(clean) ?? 0.0;
  }
  return 0.0;
}
