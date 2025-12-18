import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fin_wealth/respositories/search_stock_repository.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────
// SUB CHART: VALUATION (P/E & P/B)
// ─────────────────────────────────────────────────────────────
class SubChartValuation extends StatefulWidget {
  final String ticker;
  const SubChartValuation({super.key, required this.ticker});

  @override
  State<SubChartValuation> createState() => _SubChartValuationState();
}

class _SubChartValuationState extends State<SubChartValuation> {
  late SearchStockRepository _repo;
  bool _isLoading = true;
  String _activeType = 'pe'; // 'pe' or 'pb'
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _repo = context.read<SearchStockRepository>();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await _repo.getCompanyRatio(widget.ticker, '1y');
      if (mounted) {
        setState(() {
          _data = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(child: SizedBox(height: 250, child: Center(child: CircularProgressIndicator())));
    }

    if (_data == null) return const SizedBox.shrink();

    final labels = List<String>.from(_data!['labels'] ?? []);
    final isPE = _activeType == 'pe';
    final lineData = List<num?>.from(_data![isPE ? 'pe_data' : 'pb_data'] ?? []);
    final avgVal = _data![isPE ? 'avg_pe_1y' : 'avg_pb_1y'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Định giá', style: Theme.of(context).textTheme.titleMedium),
                ToggleButtons(
                  isSelected: [isPE, !isPE],
                  onPressed: (idx) => setState(() => _activeType = idx == 0 ? 'pe' : 'pb'),
                  borderRadius: BorderRadius.circular(8),
                  constraints: const BoxConstraints(minHeight: 30, minWidth: 40),
                  children: const [Text('P/E'), Text('P/B')],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _SimpleLineChart(
                labels: labels,
                data: lineData,
                avgLine: avgVal is num ? avgVal.toDouble() : null,
                color: isPE ? Colors.blue : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUB CHART: GROWTH (Revenue & Profit)
// ─────────────────────────────────────────────────────────────
class SubChartGrowth extends StatefulWidget {
  final String ticker;
  const SubChartGrowth({super.key, required this.ticker});

  @override
  State<SubChartGrowth> createState() => _SubChartGrowthState();
}

class _SubChartGrowthState extends State<SubChartGrowth> {
  late SearchStockRepository _repo;
  bool _isLoading = true;
  String _period = 'quarter'; // 'quarter' or 'year'
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _repo = context.read<SearchStockRepository>();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await _repo.getGrowth(widget.ticker, _period);
      if (mounted) {
        setState(() {
          _data = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onPeriodChanged(String p) {
    if (_period == p) return;
    _period = p;
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(child: SizedBox(height: 250, child: Center(child: CircularProgressIndicator())));
    }
    if (_data == null) return const SizedBox.shrink();

    final labels = List<String>.from(_data!['labels'] ?? []);
    final revenue = List<num?>.from(_data!['revenue_growth'] ?? []);
    final profit = List<num?>.from(_data!['profit_growth'] ?? []);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tăng trưởng (%)', style: Theme.of(context).textTheme.titleMedium),
                DropdownButton<String>(
                  value: _period,
                  items: const [
                    DropdownMenuItem(value: 'quarter', child: Text('Quý')),
                    DropdownMenuItem(value: 'year', child: Text('Năm')),
                  ],
                  onChanged: (v) => _onPeriodChanged(v!),
                  underline: const SizedBox(),
                )
              ],
            ),
            const SizedBox(height: 16),
            // We can show two lines or bars. Let's show lines for growth trend.
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) {
                      final i = v.toInt();
                      if (i >= 0 && i < labels.length && i % 3 == 0) { // Giảm mật độ: 3 điểm hiện 1
                         String text = labels[i];
                         try {
                           // Thử parse date để format ngắn gọn hơn (MM/yy)
                           final date = DateTime.tryParse(text);
                           if (date != null) {
                             text = '${date.month}/${date.year.toString().substring(2)}';
                           }
                         } catch (_) {}
                         
                         return Padding(
                           padding: const EdgeInsets.only(top: 8.0),
                           child: Text(text, style: const TextStyle(fontSize: 10)),
                         );
                      }
                      return const SizedBox();
                    })),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)))),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final i = spot.x.toInt();
                          String label = '';
                          if (i >= 0 && i < labels.length) label = labels[i];
                          final val = NumberFormat("#,##0.##").format(spot.y);
                          return LineTooltipItem(
                            '$label\n',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(
                                text: val, 
                                style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.w800)
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(spots: _makeSpots(revenue), color: Colors.green, barWidth: 2, isCurved: true, dotData: FlDotData(show: true)),
                    LineChartBarData(spots: _makeSpots(profit), color: Colors.redAccent, barWidth: 2, isCurved: true, dotData: FlDotData(show: true)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.circle, color: Colors.green, size: 10), SizedBox(width: 4), Text('Doanh thu', style: TextStyle(fontSize: 12)),
                SizedBox(width: 16),
                Icon(Icons.circle, color: Colors.redAccent, size: 10), SizedBox(width: 4), Text('Lợi nhuận', style: TextStyle(fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }

  List<FlSpot> _makeSpots(List<num?> data) {
    final spots = <FlSpot>[];
    for(int i=0; i<data.length; i++) {
      if(data[i] != null) spots.add(FlSpot(i.toDouble(), data[i]!.toDouble()));
    }
    return spots;
  }
}

// ─────────────────────────────────────────────────────────────
// SUB CHART: SAFETY (Debt & CFO)
// ─────────────────────────────────────────────────────────────
class SubChartSafety extends StatefulWidget {
  final String ticker;
  const SubChartSafety({super.key, required this.ticker});

  @override
  State<SubChartSafety> createState() => _SubChartSafetyState();
}

class _SubChartSafetyState extends State<SubChartSafety> {
  late SearchStockRepository _repo;
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _repo = context.read<SearchStockRepository>();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await _repo.getSafety(widget.ticker, '5y');
       if (mounted) {
        setState(() {
          _data = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(child: SizedBox(height: 250, child: Center(child: CircularProgressIndicator())));
    }
    if (_data == null) return const SizedBox.shrink();

    final labels = List<String>.from(_data!['labels'] ?? []);
    final debt = List<num?>.from(_data!['debt_to_equity'] ?? []);
    final cfo = List<num?>.from(_data!['cfo_to_revenue'] ?? []);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
             Text('Sức khỏe tài chính', style: Theme.of(context).textTheme.titleMedium),
             const SizedBox(height: 16),
             SizedBox(
               height: 250, 
               child: _DualLineChart(
                 labels: labels, 
                 data1: debt, 
                 data2: cfo,
                 title1: 'Nợ/Vốn chủ sở hữu',
                 title2: 'CFO/Doanh thu',
                 color1: Colors.purple,
                 color2: Colors.teal,
               ),
             ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DUAL LINE CHART (For Safety)
// ─────────────────────────────────────────────────────────────
class _DualLineChart extends StatelessWidget {
  final List<String> labels;
  final List<num?> data1; // Left Axis
  final List<num?> data2; // Right Axis
  final String title1;
  final String title2;
  final Color color1;
  final Color color2;

  const _DualLineChart({
    super.key,
    required this.labels,
    required this.data1,
    required this.data2,
    required this.title1,
    required this.title2,
    this.color1 = Colors.purple,
    this.color2 = Colors.teal,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Min/Max for scaling
    double min1 = double.maxFinite, max1 = -double.maxFinite;
    double min2 = double.maxFinite, max2 = -double.maxFinite;

    for (var v in data1) {
      if (v != null) {
        if (v < min1) min1 = v.toDouble();
        if (v > max1) max1 = v.toDouble();
      }
    }
    for (var v in data2) {
      if (v != null) {
        if (v < min2) min2 = v.toDouble();
        if (v > max2) max2 = v.toDouble();
      }
    }

    // Handle edge cases
    if (min1 == double.maxFinite) { min1 = 0; max1 = 100; }
    if (min2 == double.maxFinite) { min2 = 0; max2 = 100; }
    if (max1 == min1) { max1 += 1; min1 -= 1; }
    if (max2 == min2) { max2 += 1; min2 -= 1; }
    
    final range1 = max1 - min1;
    final range2 = max2 - min2;
    // Normalize data2 to range of data1
    // val2_norm = (val2 - min2) / range2 * range1 + min1
    
    final spots1 = <FlSpot>[];
    for(int i=0; i<data1.length; i++) {
      if(data1[i] != null) spots1.add(FlSpot(i.toDouble(), data1[i]!.toDouble()));
    }

    final spots2 = <FlSpot>[];
    for(int i=0; i<data2.length; i++) {
        if(data2[i] != null) {
          final val = data2[i]!.toDouble();
          final normalized = (val - min2) / range2 * range1 + min1;
          spots2.add(FlSpot(i.toDouble(), normalized));
        }
    }

    return Column(
      children: [
        Row(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Container(width: 10, height: 10, color: color1),
             const SizedBox(width: 4),
             Text(title1, style: TextStyle(color: color1, fontWeight: FontWeight.bold, fontSize: 12)),
             const SizedBox(width: 16),
             Container(width: 10, height: 10, color: color2),
             const SizedBox(width: 4),
             Text(title2, style: TextStyle(color: color2, fontWeight: FontWeight.bold, fontSize: 12)),
           ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LineChart(
             LineChartData(
               gridData: FlGridData(show: true, drawVerticalLine: false),
               titlesData: FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, 
                      reservedSize: 22, 
                      getTitlesWidget: (v, m) {
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox();
                        if (i % 3 == 0) {
                           String text = labels[i];
                           if (text.contains('-')) {
                             try {
                               final date = DateTime.tryParse(text);
                               if (date != null) {
                                  text = '${date.month}/${date.year.toString().substring(2)}';
                               }
                             } catch (_) {}
                           } else if (text.length > 4) {
                             text = text.substring(0, 4);
                           }
                           return Padding(
                             padding: const EdgeInsets.only(top: 4.0),
                             child: Text(text, style: const TextStyle(fontSize: 9)),
                           );
                        }
                        return const SizedBox();
                      }
                    )
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, 
                      reservedSize: 40,
                      getTitlesWidget: (v, m) => Text(NumberFormat.compact().format(v), style: TextStyle(fontSize: 9, color: color1))
                    )
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, 
                      reservedSize: 40,
                      getTitlesWidget: (v, m) {
                         // Un-normalize to show correct value
                         final denorm = (v - min1) / range1 * range2 + min2;
                         return Text(NumberFormat.compact().format(denorm), style: TextStyle(fontSize: 9, color: color2));
                      }
                    )
                  ),
               ),
               borderData: FlBorderData(show: false),
               lineTouchData: LineTouchData(
                 touchTooltipData: LineTouchTooltipData(
                   getTooltipColor: (_) => Colors.blueGrey,
                   tooltipRoundedRadius: 8,
                   getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final i = spot.x.toInt();
                        String dateStr = '';
                         if (i >= 0 && i < labels.length) {
                             final rawDate = labels[i];
                             try {
                               final d = DateTime.parse(rawDate);
                               dateStr = DateFormat('dd/MM/yyyy').format(d) + '\n';
                             } catch (_) {
                               dateStr = '$rawDate\n';
                             }
                        }

                        if (spot.barIndex == 0) {
                           // Data 1
                           return LineTooltipItem(
                             dateStr,
                             const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                             children: [
                               TextSpan(
                                 text: '${title1}: ${NumberFormat("#,##0.##").format(spot.y)}',
                                 style: TextStyle(color: color1, fontWeight: FontWeight.w800, fontSize: 12),
                               ),
                             ],
                           );
                        } else {
                           // Data 2 -> denormalize
                           final denorm = (spot.y - min1) / range1 * range2 + min2;
                           return LineTooltipItem(
                             '', 
                             const TextStyle(color: Colors.white, fontSize: 0),
                             children: [
                               TextSpan(
                                 text: '${title2}: ${NumberFormat("#,##0.##").format(denorm)}',
                                 style: TextStyle(color: color2, fontWeight: FontWeight.w800, fontSize: 12),
                               ),
                             ],
                           );
                        }
                      }).toList();
                   }
                 )
               ),
               lineBarsData: [
                 LineChartBarData(spots: spots1, color: color1, isCurved: true, barWidth: 2, dotData: FlDotData(show: false)),
                 LineChartBarData(spots: spots2, color: color2, isCurved: true, barWidth: 2, dotData: FlDotData(show: false)),
               ],
             )
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED CHART WIDGET
// ─────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────
// SHARED CHART WIDGET
// ─────────────────────────────────────────────────────────────
class _SimpleLineChart extends StatelessWidget {
  final List<String> labels;
  final List<num?> data;
  final Color color;
  final double? avgLine;
  final String? title;
  final bool showDateTooltip; // New parameter

  const _SimpleLineChart({
    super.key, // Added super.key for linting
    required this.labels,
    required this.data,
    this.color = Colors.blue,
    this.avgLine,
    this.title,
    this.showDateTooltip = true, // Default to true
  });

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      if (data[i] != null) spots.add(FlSpot(i.toDouble(), data[i]!.toDouble()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) Text(title!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        Expanded(
          child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.blueGrey, // Fixed: use callback instead of tooltipBgColor
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final i = spot.x.toInt();
                        String label = '';
                        if (showDateTooltip && i >= 0 && i < labels.length) {
                          final originalLabel = labels[i];
                           // Try format if needed
                           if (originalLabel.contains('-')) {
                             try {
                               final date = DateTime.tryParse(originalLabel);
                               if (date != null) {
                                  label = '${date.day}/${date.month}/${date.year}\n';
                               }
                             } catch (_) {}
                           } else {
                              label = '$originalLabel\n';
                           }
                        }
                        
                        // Round and format with thousands (image style)
                        final val = NumberFormat("#,##0.##").format(spot.y);
                        return LineTooltipItem(
                          label,
                          const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 11
                          ),
                          children: [
                            TextSpan(
                              text: val,
                              style: TextStyle(
                                color: color, // Use line color for value like image
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, 
                      reservedSize: 22, 
                      getTitlesWidget: (v, m) {
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox();

                        // Logic giống chart tăng trưởng: 3 điểm hiện 1
                        if (i % 3 == 0) {
                           String text = labels[i];
                           if (text.contains('-')) {
                             try {
                               final date = DateTime.tryParse(text);
                               if (date != null) {
                                  text = '${date.month}/${date.year.toString().substring(2)}';
                               }
                             } catch (_) {}
                           } else if (text.length > 4) {
                             text = text.substring(0, 4);
                           }

                           return Padding(
                             padding: const EdgeInsets.only(top: 4.0),
                             child: Text(text, style: const TextStyle(fontSize: 9)),
                           );
                        }
                        return const SizedBox();
                      }
                    )
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35, getTitlesWidget: (v, m) => Text(NumberFormat.compact().format(v), style: const TextStyle(fontSize: 9)))),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(spots: spots, color: color, isCurved: true, barWidth: 2, dotData: FlDotData(show: false)),
                  if (avgLine != null)
                     LineChartBarData(
                        spots: [FlSpot(0, avgLine!), FlSpot(labels.length.toDouble(), avgLine!)],
                        color: Colors.redAccent,
                        dashArray: [5, 5],
                        barWidth: 1,
                        isCurved: false,
                        dotData: FlDotData(show: false)
                     )
                ],
              ),
            ),
        ),
      ],
    );
  }
}
