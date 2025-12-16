import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fin_wealth/respositories/search_stock_repository.dart';
import 'package:intl/intl.dart';

class MainPriceChart extends StatefulWidget {
  final String ticker;

  const MainPriceChart({super.key, required this.ticker});

  @override
  State<MainPriceChart> createState() => _MainPriceChartState();
}

class _MainPriceChartState extends State<MainPriceChart> {
  late SearchStockRepository _repo;
  Map<String, dynamic>? _technicalData;
  Map<String, dynamic>? _overviewData;
  // Restore missing variables
  Map<String, dynamic>? _chartData;
  bool _isLoading = true;
  String? _error;
  String _selectedRange = '1y';

  final List<String> _timeframes = ['3m', '6m', '1y', '3y'];

  @override
  void initState() {
    super.initState();
    _repo = context.read<SearchStockRepository>();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.getCompanyRatio(widget.ticker, _selectedRange),
        _repo.getTechnicalAnalysis(widget.ticker),
        _repo.getOverview(widget.ticker),
      ]);

      if (!mounted) return;

      setState(() {
        _chartData = results[0] as Map<String, dynamic>?;
        _technicalData = results[1] as Map<String, dynamic>?;
        _overviewData = results[2] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onRangeSelected(String range) {
    if (_selectedRange == range) return;
    setState(() {
      _selectedRange = range;
    });
    // Only re-fetch company ratio (price history) when range changes
    // Technical & Overview are likely range-independent or 'current' state
    _fetchPriceHistoryOnly(); 
  }

  Future<void> _fetchPriceHistoryOnly() async {
     try {
       final data = await _repo.getCompanyRatio(widget.ticker, _selectedRange);
       if (!mounted) return;
       setState(() {
         _chartData = data;
       });
     } catch (e) {
       print('Error fetching price history: $e');
     }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 300, 
        child: Center(child: CircularProgressIndicator())
      );
    }

    if (_error != null) {
       return SizedBox(
        height: 300,
        child: Center(child: Text('Lỗi tải dữ liệu: $_error')),
      );
    }
    
    // Process Price Data
    final priceHistory = _chartData?['price_history'] as Map<String, dynamic>?;
    final labels = List<String>.from(priceHistory?['labels'] ?? []);
    final rawPrices = List<num?>.from(priceHistory?['close'] ?? []);
    
    if (rawPrices.isEmpty) {
       return const SizedBox(
        height: 300,
        child: Center(child: Text('Không có dữ liệu giá.')),
      );
    }

    // Heuristic scaling: if max price < 500, assume it's in 'k' unit, convert to VND
    // Else assume it's already VND
    // Need to handle nulls in rawPrices
    final validPrices = rawPrices.where((p) => p != null).map((p) => p!.toDouble()).toList();
    if (validPrices.isEmpty) return const SizedBox();

    final maxP = validPrices.reduce((curr, next) => curr > next ? curr : next);
    final scaleFactor = maxP < 500 ? 1000.0 : 1.0; 

    final prices = rawPrices.map((p) => p != null ? p.toDouble() * scaleFactor : null).toList();

    // Process Technical Lines
    final expertView = _technicalData?['data']?['expert_view']; // Check nested structure carefully
    final levels = expertView is Map ? expertView['levels'] : null;
    
    double? support;
    double? resistance;
    
    if (levels is Map) {
      if (levels['nearest_support'] != null) {
         support = (levels['nearest_support'] as num).toDouble();
         // Support usually follows price unit logic. If price was < 500 (k), support is likely in k too.
         // We apply same scaleFactor for consistency if it's small.
         if (support < 500) support *= 1000.0;
      }
       if (levels['nearest_resistance'] != null) {
         resistance = (levels['nearest_resistance'] as num).toDouble();
         if (resistance < 500) resistance *= 1000.0;
      }
    }

    // Process Valuation (Avg Target Price)
    double? avgValuation;
    if (_overviewData != null) {
      // Check avg_target_price or expected_price
      var val = _overviewData!['avg_target_price'];
      if (val == null || val == '') {
        val = _overviewData!['expected_price'];
      }
      
      if (val != null) {
        if (val is num) {
          avgValuation = val.toDouble();
        } else if (val is String && val.isNotEmpty) {
           avgValuation = double.tryParse(val.replaceAll(',', ''));
        }
      }
      
      // Fix Scale Mismatch if needed (similar to JS: if target/price > 50 => target is VND, price is k)
      // Here we scaled price to VND already. So avgValuation should be VND.
      // If avgValuation is small (< 500), scale it.
      if (avgValuation != null && avgValuation < 500) {
         avgValuation *= 1000.0;
      }
    }


    final spots = _buildSpots(labels, prices);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Timeframe Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _timeframes.map((tf) {
                final isSelected = _selectedRange == tf;
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: InkWell(
                    onTap: () => _onRangeSelected(tf),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected ? null : Border.all(color: Colors.grey),
                      ),
                      child: Text(
                        tf.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Chart
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                     show: true,
                     rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                     topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                     bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                             // Simple logic to show some dates
                             final index = value.toInt();
                             if (index < 0 || index >= labels.length) return const SizedBox();
                             // Show about 4-5 labels
                             final step = (labels.length / 4).ceil();
                             if (index % step == 0) {
                               return Padding(
                                 padding: const EdgeInsets.only(top: 8.0),
                                 child: Text(
                                   _formatDate(labels[index]),
                                   style: const TextStyle(fontSize: 10, color: Colors.grey),
                                 ),
                               );
                             }
                             return const SizedBox();
                          },
                        ),
                     ),
                     leftTitles: AxisTitles(
                       sideTitles: SideTitles(
                         showTitles: true,
                         reservedSize: 45,
                         getTitlesWidget: (value, meta) {
                            return Text(
                              NumberFormat.compact().format(value),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            );
                         }
                       )
                     )
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      if (support != null)
                        HorizontalLine(
                          y: support,
                          color: Colors.green,
                          strokeWidth: 1.5,
                          dashArray: [5, 5],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(right: 5, bottom: 2),
                            style: const TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
                            labelResolver: (line) => 'HT: ${NumberFormat.compact().format(line.y)}',
                          ),
                        ),
                      if (resistance != null)
                         HorizontalLine(
                          y: resistance,
                          color: Colors.red,
                          strokeWidth: 1.5,
                          dashArray: [5, 5],
                           label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.bottomRight,
                            padding: const EdgeInsets.only(right: 5, top: 2),
                            style: const TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                            labelResolver: (line) => 'KC: ${NumberFormat.compact().format(line.y)}',
                          ),
                        ),
                      if (avgValuation != null)
                        HorizontalLine(
                          y: avgValuation,
                          color: Colors.orange, // #fd7e14
                          strokeWidth: 2.0,
                          dashArray: [10, 5],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topLeft, 
                            padding: const EdgeInsets.only(left: 5, bottom: 2),
                            style: const TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold),
                            labelResolver: (line) => 'Định giá: ${NumberFormat.compact().format(line.y)}',
                          ),
                        ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MM/yy').format(date);
    } catch (_) {
      return dateStr;
    }
  }
  
  // Need to adjust buildSpots to accept nullable data to skip missing points if needed, 
  // but LineChart usually implies contiguous X. For now standard list.
  List<FlSpot> _buildSpots(List<String> labels, List<double?> data) {
    final List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
       if (data[i] != null) {
         spots.add(FlSpot(i.toDouble(), data[i]!));
       }
    }
    return spots;
  }
}
