import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fin_wealth/models/investment_opportunities.dart';
import 'package:fin_wealth/respositories/investment_opportunities_repository.dart';
import 'package:fin_wealth/screens/search_stock_screen.dart';
import 'package:fin_wealth/screens/report_viewer_screen.dart';
import 'package:fin_wealth/screens/chat_screen.dart';
import 'package:fin_wealth/respositories/auth_repository.dart';
import 'package:fin_wealth/respositories/watchlist_repository.dart';
import 'package:fin_wealth/screens/report_summary_screen.dart';
import 'package:fin_wealth/models/stock_reports.dart';
import 'package:fin_wealth/respositories/search_stock_repository.dart';
import 'package:fin_wealth/screens/ai_report_screen.dart';

class MainScreen extends StatefulWidget {
  final Function(String ticker)? onAskAI;

  const MainScreen({super.key, this.onAskAI});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late Future<InvestmentOpportunities?> _future;
  late Future<DailySummaryData?> _summaryFuture;

  @override
  void initState() {
    super.initState();
    final repo = context.read<InvestmentOpportunitiesRepository>();
    _future = repo.fetch();
    _summaryFuture = repo.fetchDailySummary();
  }

    @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        elevation: 2,
        shadowColor: theme.colorScheme.shadow.withOpacity(0.3),
        centerTitle: false,
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
        child: SafeArea(
          child: FutureBuilder<DailySummaryData?>(
            future: _summaryFuture,
            builder: (context, summarySnap) {
              if (summarySnap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (summarySnap.hasError) {
                return Center(child: Text('Lỗi tải tóm tắt: ${summarySnap.error}'));
              }

              final summaryData = summarySnap.data;
              final date = summaryData?.date ?? '';
              final aiSummary = summaryData?.aiGeneratedSummary ?? '';
              final newsHighlights = summaryData?.newsHighlights ?? [];
              final reportHighlights = summaryData?.reportHighlights ?? [];
              final bubbleOpportunities = summaryData?.bubbleOpportunities ?? [];

              // sau khi có summary → dựng tiếp dữ liệu chính
              return FutureBuilder<InvestmentOpportunities?>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Lỗi: ${snap.error}'));
                  }

                  final data = snap.data;
                  final rows = <_StockRow>[];

                  // Only process gap data if available
                  if (data != null && data.gap.tickers.isNotEmpty) {
                    for (var i = 0; i < data.gap.tickers.length; i++) {
                      final ticker = data.gap.tickers[i];
                      final cur = (data.gap.current[i]).toDouble();
                      final safe = (data.gap.safe[i]).toDouble();
                      rows.add(_StockRow(ticker: ticker, investPrice: safe, currentPrice: cur));
                    }
                  }

                  double _max2(double a, double b) => a > b ? a : b;
                  final maxValue = rows.isEmpty
                      ? 0.0
                      : rows
                          .map((r) => _max2(r.investPrice, r.currentPrice))
                          .fold<double>(0.0, (p, v) => _max2(p, v));

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- AI Summary Card with gradient border ---
                        if (aiSummary.isNotEmpty)
                          _AISummaryCard(
                            date: date,
                            summary: aiSummary,
                            newsHighlights: newsHighlights,
                          ),
                        if (aiSummary.isNotEmpty) const SizedBox(height: 16),

                        // --- Report Highlights Section ---
                        if (reportHighlights.isNotEmpty) ...[
                          _SectionCard(
                            title: 'Báo cáo đáng chú ý',
                            child: Column(
                              children: [
                                Column(
                                  children: reportHighlights.take(3).map((report) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _ReportHighlightCard(
                                        report: report,
                                        onAskAI: widget.onAskAI,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // --- Investment Opportunities Section ---
                        if (bubbleOpportunities.isNotEmpty) ...[
                          _SectionCard(
                            title: 'Cơ hội từ đánh giá CTCK',
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.65,
                              ),
                              itemCount: bubbleOpportunities.length > 8 ? 8 : bubbleOpportunities.length,
                              itemBuilder: (context, index) {
                                    return _InvestmentOpportunityCard(
                                      opportunity: bubbleOpportunities[index],
                                      onGenerateAIReport: _generateAiReport,
                                    );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // --- Phần biểu đồ giữ nguyên ---
                        if (data != null && data.bubble.isNotEmpty)
                        _SectionCard(
                          title: 'Đánh giá của CTCK (Top cơ hội)',
                          child: _InteractiveBubbleChart(points: data.bubble),
                        ),
                        if (data != null && data.bubble.isNotEmpty) const SizedBox(height: 16),
                        if (rows.isNotEmpty)
                        _SectionCard(
                          title: 'Cổ phiếu đầu tư (Giá hiện tại vs Giá an toàn)',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: const [
                                  _LegendSwatch(color: Color(0xFFFFD86B), label: 'Giá an toàn'),
                                  SizedBox(width: 16),
                                  _LegendSwatch(color: Color(0xFF2ECC71), label: 'Giá hiện tại'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: theme.colorScheme.outlineVariant),
                                ),
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                                child: _PriceCompareChart(rows: rows, maxX: maxValue * 1.15),
                              ),
                            ],
                          ),
                        ),
                        if (rows.isNotEmpty) const SizedBox(height: 16),
                        if (data != null)
                        _SectionCard(
                          title: 'Xếp hạng nhanh',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _chips('Tiền mặt/CP cao', data.rankings.cashTickers),
                              _chips('LN tăng trưởng >15% (4Q)', data.rankings.profitTickers),
                              _chips('Cổ tức >6%', data.rankings.divTickers),
                              _chips('P/B thấp (1y)', data.rankings.pbLabels),
                              _chips('P/E thấp (1y)', data.rankings.peLabels),
                              _chips('ROAE AVG5Q >15%', data.rankings.roeTickers),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _chips(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
              .map((e) => InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SearchStockScreen(ticker: e),
                        ),
                      );
                    },
                    child: Chip(label: Text(e)),
                  ))
              .toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAiReport(String ticker) async {
    final repo = context.read<SearchStockRepository>();
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

      if (!mounted) return;

      if (resp['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp['message'] ?? 'Không thể tạo báo cáo')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có task ID để theo dõi')),
        );
        return;
      }

      // Show waiting dialog
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

      // Wait 5 minutes then check
      _delayedCheckReport(ticker, taskId);
    } catch (e) {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tạo báo cáo: $e')),
      );
    }
  }

  Future<void> _delayedCheckReport(String ticker, String taskId) async {
    const waitDuration = Duration(minutes: 5);
    await Future.delayed(waitDuration);

    if (!mounted) return;

    try {
      final repo = context.read<SearchStockRepository>();
      final statusData = await repo.checkWorkflowStatus(taskId);

      final content = statusData['content']?.toString() ?? '';

      final isValidReport = content.isNotEmpty &&
          !content.toLowerCase().contains('lỗi') &&
          !content.toLowerCase().contains('error') &&
          content.length > 100;

      if (isValidReport) {
        if (!mounted) return;
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tạo báo cáo AI thất bại, vui lòng thử lại sau.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi kiểm tra báo cáo: $e')),
        );
      }
    }
  }
}

/// ------------------------------
/// Section wrapper card
/// ------------------------------
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 8),
            blurRadius: 18,
          )
        ],
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// ------------------------------
/// Bubble Chart (Top cơ hội đầu tư)
/// ------------------------------
class _BubbleChart extends StatelessWidget {
  const _BubbleChart({required this.points});
  final List<BubblePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Không có dữ liệu cơ hội'),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CustomPaint(
        painter: _BubbleChartPainter(points, Theme.of(context)),
      ),
    );
  }
}

/// ------------------------------
/// Interactive Bubble Chart (có thể click vào từng ticker)
/// ------------------------------
class _InteractiveBubbleChart extends StatefulWidget {
  const _InteractiveBubbleChart({required this.points});
  final List<BubblePoint> points;

  @override
  State<_InteractiveBubbleChart> createState() => _InteractiveBubbleChartState();
}

class _InteractiveBubbleChartState extends State<_InteractiveBubbleChart> {
  final List<_BubbleHitBox> _hitBoxes = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.points.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Không có dữ liệu cơ hội'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _hitBoxes.clear();
        final size = Size(constraints.maxWidth, constraints.maxWidth * 9 / 16);
        _calculateHitBoxes(size);

        return GestureDetector(
          onTapDown: (details) {
            final hit = _hitBoxes.firstWhere(
              (b) => (details.localPosition - b.center).distance <= b.radius,
              orElse: () => _BubbleHitBox.empty(),
            );
            if (!hit.isEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchStockScreen(ticker: hit.label),
                ),
              );
            }
          },
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: CustomPaint(
              painter: _BubbleChartPainter(widget.points, theme),
            ),
          ),
        );
      },
    );
  }

  void _calculateHitBoxes(Size size) {
    if (widget.points.isEmpty) return;
    final minX = widget.points.map((p) => p.x).reduce(math.min);
    final maxX = widget.points.map((p) => p.x).reduce(math.max);
    final minY = widget.points.map((p) => p.y).reduce(math.min);
    final maxY = widget.points.map((p) => p.y).reduce(math.max);
    final maxR = widget.points.map((p) => p.r).reduce(math.max).toDouble();
    const padding = 24.0;

    for (final p in widget.points) {
      final dx = padding + ((p.x - minX) / (maxX - minX)) * (size.width - padding * 2);
      final dy = size.height - padding - ((p.y - minY) / (maxY - minY)) * (size.height - padding * 2);
      final r = (p.r / maxR) * 40 + 6;
      _hitBoxes.add(_BubbleHitBox(center: Offset(dx, dy), radius: r, label: p.label));
    }
  }
}

class _BubbleHitBox {
  final Offset center;
  final double radius;
  final String label;
  const _BubbleHitBox({required this.center, required this.radius, required this.label});
  bool get isEmpty => label.isEmpty;
  static _BubbleHitBox empty() => const _BubbleHitBox(center: Offset.zero, radius: 0, label: '');
}

class _BubbleChartPainter extends CustomPainter {
  final List<BubblePoint> points;
  final ThemeData theme;

  _BubbleChartPainter(this.points, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final textStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    // min/max để scale
    final minX = points.map((p) => p.x).reduce(math.min);
    final maxX = points.map((p) => p.x).reduce(math.max);
    final minY = points.map((p) => p.y).reduce(math.min);
    final maxY = points.map((p) => p.y).reduce(math.max);
    final maxR = points.map((p) => p.r).reduce(math.max).toDouble();

    const padding = 24.0;

    for (final p in points) {
      final dx = padding + ((p.x - minX) / (maxX - minX)) * (size.width - padding * 2);
      final dy = size.height - padding - ((p.y - minY) / (maxY - minY)) * (size.height - padding * 2);
      final radius = (p.r / maxR) * 40 + 6;

      // Màu xanh nhạt gradient nhẹ theo Y với độ trong suốt
      final hue = (200 - (p.y * 2)).clamp(160, 220);
      paint.color = HSLColor.fromAHSL(0.6, hue.toDouble(), 0.45, 0.65).toColor();

      // Vẽ bong bóng với viền
      canvas.drawCircle(Offset(dx, dy), radius, paint);
      
      // Thêm viền để dễ phân biệt các bubble
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = HSLColor.fromAHSL(0.8, hue.toDouble(), 0.6, 0.4).toColor()
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(dx, dy), radius, borderPaint);

      // Vẽ chữ label
      final tp = TextPainter(
        text: TextSpan(text: p.label, style: textStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout(maxWidth: radius * 2);
      tp.paint(canvas, Offset(dx - tp.width / 2, dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ------------------------------
/// Legend swatch
/// ------------------------------
class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 16, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.labelMedium),
    ]);
  }
}

/// ------------------------------
/// Price Compare Chart
/// ------------------------------
class _StockRow {
  final String ticker;
  final double investPrice;
  final double currentPrice;
  _StockRow({required this.ticker, required this.investPrice, required this.currentPrice});
}

class _PriceCompareChart extends StatelessWidget {
  const _PriceCompareChart({required this.rows, required this.maxX});
  final List<_StockRow> rows;
  final double maxX;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows.map((r) {
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchStockScreen(ticker: r.ticker),
              ),
            );
          },
          child: SizedBox(
            height: 40,
            width: double.infinity,
            child: CustomPaint(
              painter: _PriceCompareRowPainter(
                row: r,
                maxX: maxX,
                theme: Theme.of(context),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PriceComparePainter extends CustomPainter {
  final List<_StockRow> rows;
  final double maxX;
  final ThemeData theme;

  _PriceComparePainter({required this.rows, required this.maxX, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final barColor = const Color(0xFFFFD86B);
    final dotColor = const Color(0xFF2ECC71);
    final gridPaint = Paint()
      ..color = theme.colorScheme.outlineVariant
      ..strokeWidth = 1;

    final leftLabelW = 44.0;
    final rightPad = 8.0;
    final chartRect = Rect.fromLTWH(leftLabelW, 0, size.width - leftLabelW - rightPad, size.height);

    for (int i = 0; i <= 4; i++) {
      final x = chartRect.left + chartRect.width * (i / 4);
      canvas.drawLine(Offset(x, chartRect.top), Offset(x, chartRect.bottom), gridPaint);
    }

    final rowH = 36.0;
    final gap = 4.0;
    final textStyle = theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

    for (int i = 0; i < rows.length; i++) {
      final y = i * (rowH + gap) + 8;
      final r = rows[i];

      final tp = _tp(r.ticker, textStyle);
      tp.layout(maxWidth: leftLabelW - 8);
      tp.paint(canvas, Offset(4, y + rowH / 2 - tp.height / 2));

      if (maxX <= 0) continue;

      final investX = chartRect.left + (r.investPrice / maxX) * chartRect.width;
      final width = math.max(0.0, investX - chartRect.left);
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(chartRect.left, y + 6, width, rowH - 12),
        const Radius.circular(6),
      );
      final barPaint = Paint()..color = barColor;
      canvas.drawRRect(barRect, barPaint);

      final currentX = chartRect.left + (r.currentPrice / maxX) * chartRect.width;
      final dotPaint = Paint()..color = dotColor;
      canvas.drawCircle(Offset(currentX, y + rowH / 2), 5.5, dotPaint);
    }
  }

  TextPainter _tp(String text, TextStyle style) => TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      );

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ------------------------------
/// Row Painter cho từng dòng cổ phiếu (có thể click)
/// ------------------------------
class _PriceCompareRowPainter extends CustomPainter {
  final _StockRow row;
  final double maxX;
  final ThemeData theme;

  _PriceCompareRowPainter({
    required this.row,
    required this.maxX,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barColor = const Color(0xFFFFD86B);
    final dotColor = const Color(0xFF2ECC71);

    final textStyle = theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

    // --- Vẽ nhãn cổ phiếu ---
    final tp = TextPainter(
      text: TextSpan(text: row.ticker, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: 44);
    tp.paint(canvas, const Offset(4, 12));

    if (maxX <= 0) return;
    final chartWidth = size.width - 60;

    final investX = 50 + (row.investPrice / maxX) * chartWidth;
    final currentX = 50 + (row.currentPrice / maxX) * chartWidth;

    // --- Thanh giá an toàn ---
    final barPaint = Paint()..color = barColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(50, 12, investX - 50, 12),
        const Radius.circular(6),
      ),
      barPaint,
    );

    // --- Chấm giá hiện tại ---
    final dotPaint = Paint()..color = dotColor;
    canvas.drawCircle(Offset(currentX, 18), 5.5, dotPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// ------------------------------
/// AI Summary Card with gradient border
/// ------------------------------
class _AISummaryCard extends StatefulWidget {
  const _AISummaryCard({
    required this.date,
    required this.summary,
    required this.newsHighlights,
  });

  final String date;
  final String summary;
  final List<dynamic> newsHighlights;

  @override
  State<_AISummaryCard> createState() => _AISummaryCardState();
}

class _AISummaryCardState extends State<_AISummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1), // Indigo
            Color(0xFFEC4899), // Pink
            Color(0xFF8B5CF6), // Purple
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF6366F1),
                        size: 24,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tóm tắt thông minh từ AI (${widget.date})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.7,
                color: theme.colorScheme.onSurface.withOpacity(0.85),
              ),
            ),
            if (widget.newsHighlights.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Tin tức nổi bật',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ...widget.newsHighlights.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            e.toString(),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

/// ------------------------------
/// Report Highlight Card
/// ------------------------------
class _ReportHighlightCard extends StatelessWidget {
  const _ReportHighlightCard({
    required this.report,
    this.onAskAI,
  });

  final ReportHighlight report;
  final Function(String ticker)? onAskAI;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: report.filePresigned != null
              ? () {
                  // Navigate to report viewer
                  Navigator.pushNamed(
                    context,
                    '/report-viewer',
                    arguments: {
                      'url': report.filePresigned,
                      'title': report.title,
                    },
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  report.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Meta info
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _MetaChip(
                      icon: Icons.business,
                      label: report.source,
                    ),
                    _MetaChip(
                      icon: Icons.calendar_today,
                      label: _formatDate(report.date),
                    ),
                    if (report.valuation != null)
                      _MetaChip(
                        icon: Icons.trending_up,
                        label: NumberFormat('#,###', 'vi_VN').format(report.valuation),
                        color: Colors.green,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Ticker chips
                if (report.tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: report.tags
                        .map((tag) => _TickerChip(ticker: tag))
                        .toList(),
                  ),
                const SizedBox(height: 8),
                
                // Summary
                Text(
                  report.summary ?? 'Đang cập nhật nội dung tóm tắt...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                // --- Action Buttons ---
                Row(
                  children: [
                    // Read button
                    if (report.filePresigned != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Map ReportHighlight to StockReport
                            final stockReport = StockReport(
                              id: report.id ?? 0,
                              ticker: report.tags.isNotEmpty ? report.tags.first : '',
                              title: report.title,
                              date: DateTime.tryParse(report.date) ?? DateTime.now(),
                              source: report.source,
                              fileUrl: report.filePresigned,
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReportSummaryScreen(report: stockReport),
                              ),
                            );
                          },
                          icon: const Icon(Icons.summarize, size: 16),
                          label: const Text('Tóm tắt', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            side: BorderSide(color: theme.colorScheme.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Ask AI button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final tickers = report.tags.join(' ');
                          if (onAskAI != null) {
                            onAskAI!(tickers);
                          } else {
                            // Fallback if callback not provided
                             // Get user data from AuthRepository
                            final authRepo = context.read<AuthRepository>();
                            final userData = {
                              'username': authRepo.username ?? 'user',
                            };
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  userData: userData,
                                  initialMessage: tickers.isNotEmpty ? tickers : null,
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.chat, size: 16),
                        label: const Text('Hỏi AI', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1),
                          side: const BorderSide(color: Color(0xFF6366F1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return date;
    }
  }
}

/// ------------------------------
/// Meta Chip (for source, date, etc.)
/// ------------------------------
class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.onSurface.withOpacity(0.6);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: chipColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: chipColor),
        ),
      ],
    );
  }
}

/// ------------------------------
/// Ticker Chip
/// ------------------------------
class _TickerChip extends StatelessWidget {
  const _TickerChip({required this.ticker});

  final String ticker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchStockScreen(ticker: ticker),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Text(
          ticker,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// ------------------------------
/// Investment Opportunity Card
/// ------------------------------
class _InvestmentOpportunityCard extends StatelessWidget {
  const _InvestmentOpportunityCard({
    required this.opportunity,
    this.onGenerateAIReport,
  });

  final BubbleOpportunity opportunity;
  final Function(String ticker)? onGenerateAIReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchStockScreen(ticker: opportunity.label),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ticker
                Text(
                  opportunity.label,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                // Metrics
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Số CTCK: ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          '${opportunity.nFirms}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Dư địa: ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          '+${opportunity.gapPct.toStringAsFixed(1)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Action buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SearchStockScreen(ticker: opportunity.label),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Chi tiết'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(color: theme.colorScheme.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await context.read<WatchlistRepository>().addToWatchlist(opportunity.label);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã thêm ${opportunity.label} vào danh sách theo dõi'),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Theo dõi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (onGenerateAIReport != null) {
                            onGenerateAIReport!(opportunity.label);
                          }
                        },
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('Xem báo cáo AI'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.secondary,
                          side: BorderSide(color: theme.colorScheme.secondary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
