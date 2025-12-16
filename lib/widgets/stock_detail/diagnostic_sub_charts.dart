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
                      if (i >= 0 && i < labels.length && i % 2 == 0) {
                         return Padding(
                           padding: const EdgeInsets.only(top: 8.0),
                           child: Text(labels[i], style: const TextStyle(fontSize: 10)),
                         );
                      }
                      return const SizedBox();
                    })),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)))),
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
               height: 120,
               child: _SimpleLineChart(labels: labels, data: debt, color: Colors.purple, title: 'Nợ/Vốn chủ sở hữu'),
             ),
             const SizedBox(height: 16),
             SizedBox(
               height: 120,
               child: _SimpleLineChart(labels: labels, data: cfo, color: Colors.teal, title: 'CFO/Doanh thu'),
             ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED CHART WIDGET
// ─────────────────────────────────────────────────────────────
class _SimpleLineChart extends StatelessWidget {
  final List<String> labels;
  final List<num?> data;
  final Color color;
  final double? avgLine;
  final String? title;

  const _SimpleLineChart({
    required this.labels,
    required this.data,
    this.color = Colors.blue,
    this.avgLine,
    this.title,
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
                        if (i == 0 || i == labels.length - 1 || i == labels.length ~/ 2) {
                           if (i >= 0 && i < labels.length) {
                              return Text(labels[i].substring(0, 4), style: const TextStyle(fontSize: 10)); // Just Year for simplicity
                           }
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
