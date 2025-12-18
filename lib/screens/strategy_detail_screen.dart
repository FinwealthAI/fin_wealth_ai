import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fin_wealth/respositories/investment_opportunities_repository.dart';
import 'package:fin_wealth/screens/search_stock_screen.dart';
import 'package:intl/intl.dart';

class StrategyDetailScreen extends StatefulWidget {
  final String title;
  final List<dynamic>? preloadedData; // Optional pre-loaded data from StrategyCardData

  const StrategyDetailScreen({
    super.key,
    required this.title,
    this.preloadedData,
  });

  @override
  State<StrategyDetailScreen> createState() => _StrategyDetailScreenState();
}

class _StrategyDetailScreenState extends State<StrategyDetailScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _results = [];

  String _searchQuery = '';
  String? _sortKey;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // If preloaded data is available, use it directly
    if (widget.preloadedData != null && widget.preloadedData!.isNotEmpty) {
      // Transform and GROUP preloadedData by ticker
      // The preloadedData from StrategyCardData.data has format: [{ticker: 'ABC', date: '...', value: X}, ...]
      // We need to group by ticker: [{symbol: 'ABC', criteria_values: {merged values}}, ...]
      
      final Map<String, Map<String, dynamic>> groupedData = {};
      
      for (final item in widget.preloadedData!) {
        if (item is Map<String, dynamic>) {
          final symbol = (item['ticker'] ?? item['symbol'] ?? item['label'] ?? '').toString();
          if (symbol.isEmpty) continue;
          
          if (!groupedData.containsKey(symbol)) {
            groupedData[symbol] = <String, dynamic>{};
          }
          
          // Merge all non-ticker/symbol/label fields into criteria_values
          item.forEach((key, value) {
            if (key != 'ticker' && key != 'symbol' && key != 'label') {
              // For duplicate keys, keep the latest non-null value
              if (value != null) {
                groupedData[symbol]![key] = value;
              }
            }
          });
        }
      }
      
      // Convert grouped data to list format
      final transformedData = groupedData.entries.map((entry) {
        return {
          'symbol': entry.key,
          'criteria_values': entry.value,
        };
      }).toList();
      
      setState(() {
        _results = transformedData;
        _isLoading = false;
      });
      print('[DEBUG] Using preloaded data: ${widget.preloadedData!.length} items → grouped into ${_results.length} tickers');
    } else {
      // Fallback to API call if no preloaded data
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    try {
      final repo = context.read<InvestmentOpportunitiesRepository>();
      final results = await repo.fetchStrategyDetails(widget.title);

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> _filterAndSortResults() {
    // 1. Filter by Search Query
    List<dynamic> filtered = _results.where((row) {
      final symbol = (row['symbol'] ?? '').toString().toLowerCase();
      return symbol.contains(_searchQuery.toLowerCase());
    }).toList();

    // 2. Sort
    if (_sortKey != null) {
      filtered.sort((a, b) {
        final valA = (a['criteria_values'] as Map)[_sortKey];
        final valB = (b['criteria_values'] as Map)[_sortKey];

        // Handle nulls
        if (valA == null && valB == null) return 0;
        if (valA == null) return 1; // Nulls last
        if (valB == null) return -1;

        int compareResult = 0;
        if (valA is num && valB is num) {
          compareResult = valA.compareTo(valB);
        } else {
          compareResult = valA.toString().compareTo(valB.toString());
        }

        return _isAscending ? compareResult : -compareResult;
      });
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Đã có lỗi xảy ra', 
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!, 
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _fetchData, 
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      );
    }

    final filteredResults = _filterAndSortResults();
    // Get available sort keys from first valid item
    final sortKeys = (_results.first['criteria_values'] as Map<String, dynamic>? ?? {}).keys.toList();

    return Column(
      children: [
        // Search & Filter Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Search Field
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm cổ phiếu...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // Sort Button
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.sort, color: theme.colorScheme.onPrimaryContainer),
                ),
                tooltip: 'Sắp xếp',
                onSelected: (key) {
                  setState(() {
                    if (_sortKey == key) {
                      _isAscending = !_isAscending; // Toggle order if same key
                    } else {
                       _sortKey = key;
                       _isAscending = false; // Default desc for numbers usually (highest vol/pe etc)
                    }
                  });
                },
                itemBuilder: (context) {
                  return sortKeys.map((key) {
                    return PopupMenuItem(
                      value: key,
                      child: Row(
                        children: [
                          Text(_formatHeader(key)),
                          if (_sortKey == key) ...[
                            const SizedBox(width: 8),
                            Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                          ]
                        ],
                      ),
                    );
                  }).toList();
                },
              ),
            ],
          ),
        ),
        
        // Results List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: filteredResults.length,
            separatorBuilder: (ctx, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final row = filteredResults[index];
              final symbol = row['symbol'] ?? '';
              final values = row['criteria_values'] as Map<String, dynamic>? ?? {};
              final keys = values.keys.toList();

              return Card(
                elevation: 2,
                shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Ticker
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SearchStockScreen(ticker: symbol),
                                  settings: const RouteSettings(name: 'search_stock'),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    symbol,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '#${index + 1}', // Re-index based on filtered list
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate width based on actual available width
                          // (Total available width - spacing) / 2
                          final itemWidth = (constraints.maxWidth - 16) / 2;
                          
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: keys.map((key) {
                              return SizedBox(
                                  width: itemWidth > 0 ? itemWidth : null, // Prevent negative width
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                      Text(
                                          _formatHeader(key),
                                          style: TextStyle(
                                            fontSize: 12,
                                            // Highlight sorted col
                                            color: (_sortKey == key) ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                            fontWeight: (_sortKey == key) ? FontWeight.bold : FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                          _formatValue(values[key]),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: (_sortKey == key) ? theme.colorScheme.primary : null,
                                          ),
                                      ),
                                      ],
                                  ),
                              );
                            }).toList(),
                          );
                        }
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatHeader(String key) {
    // Simple prettify
    // avg_vol_20d -> AVG VOL 20D
    // item_name -> Item Name
    if (key == 'market_cap') return 'Vốn hóa';
    if (key == 'pe') return 'P/E';
    if (key == 'pb') return 'P/B';
    if (key == 'roe') return 'ROE';
    
    // Replace underscore with space and Title Case
    return key.replaceAll('_', ' ').toUpperCase();
  }

  String _formatValue(dynamic value) {
    if (value == null) return '-';
    if (value is num) {
      // Format number
      if (value > 1000000) {
        // e.g. 1.2B
        return NumberFormat.compact(locale: 'vi').format(value);
      }
      if (value is int || value == value.roundToDouble()) {
         return NumberFormat('#,###', 'vi').format(value);
      }
      return NumberFormat('#,##0.00', 'vi').format(value);
    }
    return value.toString();
  }
}
