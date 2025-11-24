// lib/screens/search_stock_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import 'package:fin_wealth/respositories/search_stock_repository.dart';
import 'package:fin_wealth/screens/ai_report_screen.dart';
import 'package:url_launcher/url_launcher.dart';


class SearchStockScreen extends StatefulWidget {
  final String ticker;
  const SearchStockScreen({super.key, required this.ticker});

  @override
  State<SearchStockScreen> createState() => _SearchStockScreenState();
}

class _SearchStockScreenState extends State<SearchStockScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SearchStockRepository repo;

  @override
  void initState() {
    super.initState();
    repo = context.read<SearchStockRepository>();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticker = widget.ticker.toUpperCase();
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Phân tích cổ phiếu $ticker',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        elevation: 2,
        shadowColor: theme.colorScheme.shadow.withOpacity(0.3),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withOpacity(0.9),
                  theme.colorScheme.secondaryContainer.withOpacity(0.7),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: theme.colorScheme.onPrimary,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              tabs: const [
                Tab(
                  icon: Icon(Icons.dashboard, size: 18),
                  text: 'Tổng quan',
                ),
                Tab(
                  icon: Icon(Icons.analytics, size: 18),
                  text: 'Định giá CTCK',
                ),
                Tab(
                  icon: Icon(Icons.trending_up, size: 18),
                  text: 'P/E & P/B',
                ),
                Tab(
                  icon: Icon(Icons.show_chart, size: 18),
                  text: 'Tăng trưởng',
                ),
                Tab(
                  icon: Icon(Icons.security, size: 18),
                  text: 'Chỉ số an toàn',
                ),
                Tab(
                  icon: Icon(Icons.article, size: 18),
                  text: 'Tin tức',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface.withOpacity(0.8),
              theme.colorScheme.surfaceContainer.withOpacity(0.9),
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(repo: repo, ticker: ticker),
            _ValuationTab(repo: repo, ticker: ticker),
            _PERatioTab(repo: repo, ticker: ticker),
            _GrowthTab(repo: repo, ticker: ticker),
            _SafetyTab(repo: repo, ticker: ticker),
            _NewsTab(repo: repo, ticker: ticker),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final tab = _OverviewTab(repo: repo, ticker: ticker);
          await tab.generateAiReport(context);
        },
        icon: const Icon(Icons.auto_awesome, size: 22),
        label: const Text(
          'TẠO BÁO CÁO AI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: theme.colorScheme.secondaryContainer,
        foregroundColor: theme.colorScheme.onSecondaryContainer,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

//
// ────────────────────────────────────────────────
// OVERVIEW TAB
// ────────────────────────────────────────────────
//
class _OverviewTab extends StatelessWidget {
  final SearchStockRepository repo;
  final String ticker;
  const _OverviewTab({required this.repo, required this.ticker});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: repo.getOverview(ticker),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final d = snap.data!;
        final entries = {
          'Giá hiện tại': d['price'],
          'Giá kỳ vọng': d['expected_price'],
          'Giá mục tiêu TB': d['avg_target_price'],
          'Giá an toàn': d['safe_investment_price'],
          'P/E': d['price_to_earnings'],
          'P/B': d['price_to_book'],
          'EPS': d['eps_tr'],
          'Cổ tức (%)': d['dividend_yield'],
          'Beta': d['beta'],
        };

        return Column(
          children: [
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                childAspectRatio: 3.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: entries.entries
                    .map((e) => _StatBox(label: e.key, value: e.value))
                    .toList(),
              ),
            ),

          ],
        );
      },
    );
  }

  Future<void> generateAiReport(BuildContext context) async {
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final resp = await repo.startWorkflow(ticker);

    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!context.mounted) return;

    if (resp['success'] != true) {
      _showError(context, resp['message'] ?? 'Không thể tạo báo cáo');
      return;
    }

    final isImmediate = resp['immediate'] == true;
    final hasContent =
        resp['content'] != null && resp['content'].toString().isNotEmpty;

    if (isImmediate && hasContent) {
      final content = resp['content'].toString();
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AiReportScreen(
          ticker: ticker,
          htmlContent: content,
        ),
      ));
      return;
    }

    final taskId = resp['task_id'];
    if (taskId == null || taskId.toString().isEmpty) {
      _showError(context, 'Không có task ID để theo dõi');
      return;
    }

    // 🔔 Hiển thị popup báo người dùng chờ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Đang tạo báo cáo AI'),
        content: const Text(
          'Hệ thống đang tạo báo cáo cho cổ phiếu này.\n'
          'Vui lòng quay lại sau vài phút.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // ✅ Đợi 5 phút rồi kiểm tra lại
    _delayedCheckReport(context, taskId);
  } catch (e) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    _showError(context, 'Lỗi khi tạo báo cáo: $e');
  }
}

Future<void> _delayedCheckReport(BuildContext context, String taskId) async {
  const waitDuration = Duration(minutes: 5);
  debugPrint('⏳ Chờ $waitDuration rồi mới kiểm tra kết quả báo cáo...');
  await Future.delayed(waitDuration);

  if (!context.mounted) return;

  try {
    final statusData = await repo.checkWorkflowStatus(taskId);
    debugPrint('🔁 Kết quả kiểm tra sau 5 phút: $statusData');

    final content = statusData['content']?.toString() ?? '';

    final isValidReport = content.isNotEmpty &&
        !content.toLowerCase().contains('lỗi') &&
        !content.toLowerCase().contains('error') &&
        content.length > 100;

    if (isValidReport) {
      if (!context.mounted) return;
      // 📄 Hiển thị thông báo báo cáo đã sẵn sàng
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Báo cáo AI đã sẵn sàng!')),
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AiReportScreen(
            ticker: ticker,
            htmlContent: content,
          ),
        ),
      );
    } else {
      // ❌ Không có kết quả sau 5 phút
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Tạo báo cáo AI thất bại, vui lòng thử lại sau.')),
      );
      // ⚙️ Quay về trang SearchStockScreen
      Navigator.of(context).pop(); // đóng _OverviewTab, quay lại màn hình trước
    }
  } catch (e) {
    debugPrint('⚠️ Lỗi khi kiểm tra báo cáo sau 5 phút: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi kiểm tra báo cáo: $e')),
      );
      Navigator.of(context).pop();
    }
  }
}

Future<void> _pollReport(BuildContext context, String taskId) async {
  const pollingInterval = Duration(seconds: 10); // ✅ 10s chạy 1 lần
  const maxPollingTime = Duration(minutes: 5); // ✅ 5 phút timeout
  final startTime = DateTime.now();

  while (DateTime.now().difference(startTime) < maxPollingTime) {
    // ✅ Kiểm tra context trước mỗi lần polling
    if (!context.mounted) {
      debugPrint('⚠️ Context không còn mounted, dừng polling');
      return;
    }

    debugPrint('🔁 Polling task: $taskId, thời gian đã chờ: ${DateTime.now().difference(startTime).inSeconds}s');

    try {
      final statusData = await repo.checkWorkflowStatus(taskId);
      print('🔁 Check task status: $statusData');

            // ✅ Kiểm tra trạng thái success và có content hợp lệ
      if (statusData['success'] == true) {
        final content = statusData['content']?.toString() ?? '';
        
        // ✅ Kiểm tra content có thực sự là báo cáo hợp lệ không
        final isValidReport = content.isNotEmpty && 
                             !content.toLowerCase().contains('lỗi') &&
                             !content.toLowerCase().contains('error') &&
                             content.length > 100; // Báo cáo thực sự phải có độ dài hợp lý
        
        if (isValidReport) {
          debugPrint('✅ Có nội dung báo cáo hợp lệ, độ dài: ${content.length}');
          if (context.mounted) {

            // ❌ THAY ĐỔI: Không dùng rootNavigator: true
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AiReportScreen(
                  ticker: ticker,
                  htmlContent: content,
                ),
              ),
          );
          }
          return; // ✅ Dừng polling khi có nội dung hợp lệ
        } else if (content.isNotEmpty) {
          debugPrint('⚠️ Content không hợp lệ: "$content"');
          debugPrint('⏳ Tiếp tục polling...');
        } else {
          debugPrint('⏳ Chưa có nội dung, tiếp tục polling...');
        }
      } else {
        debugPrint('⚠️ API trả về success: false');
      }
    } catch (error) {
      print('⚠️ Lỗi khi kiểm tra task: $error');
      // Tiếp tục polling nếu có lỗi mạng, không break
    }

    // ✅ Đợi pollingInterval trước khi chạy lần tiếp theo
    await Future.delayed(pollingInterval);
  }

  // ❌ Nếu quá thời gian mà vẫn chưa có báo cáo
  if (context.mounted) {
    debugPrint('❌ Timeout sau 5 phút polling');
    _showError(context, 'Hệ thống mất quá nhiều thời gian xử lý. Vui lòng thử lại sau.');
  }
}


  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final dynamic value;
  const _StatBox({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value?.toString() ?? '-',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

//
// ────────────────────────────────────────────────
// VALUATION TAB
// ────────────────────────────────────────────────
//
class _ValuationTab extends StatelessWidget {
  final SearchStockRepository repo;
  final String ticker;
  const _ValuationTab({required this.repo, required this.ticker});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: repo.getValuation(ticker),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final list = snap.data!['details'] ?? [];
        if (list.isEmpty) return const Center(child: Text('Không có dữ liệu định giá.'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final v = list[i];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(v['firm_new'] ?? ''),
                subtitle: Text('${v['report_date']} — ${v['recommendation']}'),
                trailing: Text(
                  '${v['target_price']} đ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

//
// ────────────────────────────────────────────────
// P/E & P/B TAB
// ────────────────────────────────────────────────
//
class _PERatioTab extends StatefulWidget {
  final SearchStockRepository repo;
  final String ticker;
  const _PERatioTab({required this.repo, required this.ticker});

  @override
  State<_PERatioTab> createState() => _PERatioTabState();
}

class _PERatioTabState extends State<_PERatioTab> {
  String _active = 'pe';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: widget.repo.getCompanyRatio(widget.ticker, '1y'),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final d = snap.data!;
        final labels = List<String>.from(d['labels'] ?? []);
        final pe = List<num>.from(d['pe_data'] ?? []);
        final pb = List<num>.from(d['pb_data'] ?? []);
        final avgPe = d['avg_pe_1y'] ?? 0;
        final avgPb = d['avg_pb_1y'] ?? 0;

        final isPE = _active == 'pe';
        final title = isPE ? 'Biểu đồ P/E (1 năm)' : 'Biểu đồ P/B (1 năm)';
        final data = isPE ? pe : pb;
        final avgLine = isPE ? avgPe : avgPb;

        return Column(
          children: [
            const SizedBox(height: 10),
            ToggleButtons(
              borderRadius: BorderRadius.circular(8),
              isSelected: [_active == 'pe', _active == 'pb'],
              onPressed: (i) => setState(() => _active = i == 0 ? 'pe' : 'pb'),
              children: const [
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('P/E')),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('P/B')),
              ],
            ),
            Expanded(
              child: _buildLineChart(
                title: title,
                labels: labels,
                data: data,
                avgLine: avgLine,
                color: isPE ? Colors.blueAccent : Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }
}

//
// ────────────────────────────────────────────────
// GROWTH TAB
// ────────────────────────────────────────────────
//
class _GrowthTab extends StatelessWidget {
  final SearchStockRepository repo;
  final String ticker;
  const _GrowthTab({required this.repo, required this.ticker});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: repo.getGrowth(ticker, 'year'),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final d = snap.data!;
        final labels = List<String>.from(d['labels'] ?? []);
        final rev = List<num>.from(d['revenue_growth'] ?? []);
        final prof = List<num>.from(d['profit_growth'] ?? []);

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _buildLineChart(
              title: 'Tăng trưởng Doanh thu (%)',
              labels: labels,
              data: rev,
              color: Colors.green,
              useTime: true,
            ),
            const SizedBox(height: 20),
            _buildLineChart(
              title: 'Tăng trưởng Lợi nhuận (%)',
              labels: labels,
              data: prof,
              color: Colors.redAccent,
              useTime: true,
            ),
          ],
        );
      },
    );
  }
}

//
// ────────────────────────────────────────────────
// SAFETY TAB
// ────────────────────────────────────────────────
//
class _SafetyTab extends StatelessWidget {
  final SearchStockRepository repo;
  final String ticker;
  const _SafetyTab({required this.repo, required this.ticker});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: repo.getSafety(ticker, '5y'),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final d = snap.data!;
        final labels = List<String>.from(d['labels'] ?? []);
        final debt = List<num>.from(d['debt_to_equity'] ?? []);
        final cfo = List<num>.from(d['cfo_to_revenue'] ?? []);

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _buildLineChart(
              title: 'Nợ/Vốn chủ sở hữu (%)',
              labels: labels,
              data: debt,
              color: Colors.purple,
              useTime: true,
            ),
            const SizedBox(height: 20),
            _buildLineChart(
              title: 'CFO/Doanh thu (%)',
              labels: labels,
              data: cfo,
              color: Colors.teal,
              useTime: true,
            ),
          ],
        );
      },
    );
  }
}

//
// ────────────────────────────────────────────────
// NEWS TAB
// ────────────────────────────────────────────────
//
class _NewsTab extends StatelessWidget {
  final SearchStockRepository repo;
  final String ticker;
  const _NewsTab({required this.repo, required this.ticker});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: repo.getStockNews(ticker),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final list = snap.data!;
        if (list.isEmpty) return const Center(child: Text('Không có tin tức.'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, i) {
            final n = list[i];
            return ListTile(
              title: Text(n['title']),
              subtitle: Text(n['date'] ?? ''),
            );
          },
        );
      },
    );
  }
}

//
// ────────────────────────────────────────────────
// LINE CHART WIDGET
// ────────────────────────────────────────────────
//
List<FlSpot> _buildSpots(List<String> labels, List<num?> data, {bool useTime = false}) {
  if (labels.isEmpty || data.isEmpty) return [];
  final List<FlSpot> spots = [];
  final firstDate = DateTime.tryParse(labels.first) ?? DateTime(2000);

  for (int i = 0; i < data.length; i++) {
    final y = data[i];
    if (y == null) continue;

    double x;
    if (useTime) {
      final date = DateTime.tryParse(labels[i]) ?? firstDate.add(Duration(days: i * 30));
      x = date.difference(firstDate).inDays.toDouble();
    } else {
      x = i.toDouble();
    }

    spots.add(FlSpot(x, y.toDouble()));
  }
  return spots;
}

Widget _buildLineChart({
  required String title,
  required List<String> labels,
  required List<num?> data,
  required Color color,
  double? avgLine,
  bool useTime = false,
}) {
  final spots = _buildSpots(labels, data, useTime: useTime);
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        if (useTime) {
                          // Khi dùng mốc thời gian, hiển thị các điểm đại diện (đầu, giữa, cuối)
                          final totalX = spots.isNotEmpty ? spots.last.x : 0;
                          if (totalX == 0) return const SizedBox();

                          // Tính tỉ lệ vị trí tương ứng trong labels
                          final index = (v / (totalX / (labels.length - 1))).round();
                          if (index < 0 || index >= labels.length) return const SizedBox();
                          final label = labels[index];

                          // Hiển thị năm hoặc tháng/năm nếu có dạng yyyy-mm-dd
                          try {
                            final parts = label.split('-');
                            if (parts.isNotEmpty) {
                              if (parts.length >= 2) {
                                return Text('${parts[1]}/${parts[0]}', style: const TextStyle(fontSize: 10));
                              } else {
                                return Text(parts[0], style: const TextStyle(fontSize: 10));
                              }
                            }
                          } catch (_) {}
                          return Text(label, style: const TextStyle(fontSize: 10));
                        } else {
                          final i = v.toInt();
                          if (i % 3 != 0 || i >= labels.length) {
                            return const SizedBox();
                          }
                          final dateStr = labels[i];
                          try {
                            final parts = dateStr.split('-');
                            if (parts.length >= 2) {
                              final month = parts[1];
                              final year = parts[0];
                              return Text('$month/$year', style: const TextStyle(fontSize: 10));
                            }
                          } catch (e) {}
                          return Text(dateStr.substring(2, 7), style: const TextStyle(fontSize: 10));
                        }
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles:
                        SideTitles(showTitles: true, reservedSize: 36, interval: 10),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    color: color,
                    isCurved: true,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                  ),
                  if (avgLine != null)
                    LineChartBarData(
                      spots: [
                        FlSpot(0, avgLine.toDouble()),
                        FlSpot(data.length.toDouble(), avgLine.toDouble())
                      ],
                      color: Colors.redAccent,
                      isCurved: false,
                      barWidth: 1.2,
                      dashArray: [6, 4],
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


