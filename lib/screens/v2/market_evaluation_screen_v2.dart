import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/market_evaluation.dart';
import '../../respositories/market_evaluation_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';

class MarketEvaluationScreenV2 extends StatefulWidget {
  const MarketEvaluationScreenV2({super.key});

  @override
  State<MarketEvaluationScreenV2> createState() =>
      _MarketEvaluationScreenV2State();
}

class _MarketEvaluationScreenV2State extends State<MarketEvaluationScreenV2> {
  late final MarketEvaluationRepository _repo =
      context.read<MarketEvaluationRepository>();
  MarketEvaluation? _snapshot;
  List<MarketEvaluationHistoryItem> _history = const [];
  bool _loading = true;
  Object? _err;
  int _historyDays = 90;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final results = await Future.wait([
        _repo.fetchSnapshot(),
        _repo.fetchHistory(days: _historyDays),
      ]);
      if (!mounted) return;
      setState(() {
        _snapshot = results[0] as MarketEvaluation;
        _history = results[1] as List<MarketEvaluationHistoryItem>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: const FwAppBar(
        title: 'Đánh giá Thị trường',
        subtitle: 'Phân tích tổng hợp VNINDEX',
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.brandPrimary,
        child: _loading
            ? _buildSkeleton()
            : _err != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
          4,
          (_) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FwSkeleton(height: 100),
              )),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.dangerDark, size: 48),
          const SizedBox(height: 12),
          Text('$_err', style: const TextStyle(color: AppColors.darkTextMuted)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final s = _snapshot!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _ScoreCard(snapshot: s),
        const SizedBox(height: 16),
        _ScoresBreakdownCard(snapshot: s),
        const SizedBox(height: 16),
        _VnindexCard(snapshot: s),
        const SizedBox(height: 16),
        _MacroBreadthCard(snapshot: s),
        const SizedBox(height: 16),
        _AiSentimentCard(sentiment: s.aiSentiment),
        const SizedBox(height: 16),
        _HistorySection(
          history: _history,
          days: _historyDays,
          onDaysChanged: (d) {
            setState(() => _historyDays = d);
            _load();
          },
        ),
      ],
    );
  }
}

// ── Score tổng hợp ────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final MarketEvaluation snapshot;
  const _ScoreCard({required this.snapshot});

  Color _scoreColor(double s) {
    if (s >= 65) return AppColors.successDark;
    if (s >= 50) return AppColors.brandPrimaryDark;
    if (s >= 35) return AppColors.warningDark;
    return AppColors.dangerDark;
  }

  String _zoneLabel(double s) {
    if (s >= 65) return 'Tốt';
    if (s >= 50) return 'Khá';
    if (s >= 35) return 'Thận trọng';
    return 'Xấu';
  }

  @override
  Widget build(BuildContext context) {
    final s = snapshot.finalScore;
    final color = _scoreColor(s);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Gauge vòng tròn
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: s / 100,
                  strokeWidth: 8,
                  backgroundColor: AppColors.darkBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.toStringAsFixed(1),
                      style: TextStyle(
                          color: color,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '/100',
                      style: TextStyle(
                          color: AppColors.darkTextMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _zoneLabel(s),
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.label,
                  style: const TextStyle(
                      color: AppColors.darkTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  snapshot.snapshotUpdatedAt.isNotEmpty
                      ? 'Cập nhật: ${snapshot.snapshotUpdatedAt}'
                      : '',
                  style: const TextStyle(
                      color: AppColors.darkTextMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Breakdown 5 điểm thành phần ───────────────────────────────────────────────

class _ScoresBreakdownCard extends StatelessWidget {
  final MarketEvaluation snapshot;
  const _ScoresBreakdownCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Kỹ thuật', snapshot.techScore, AppColors.brandPrimaryDark),
      ('Độ rộng', snapshot.breadthScore, AppColors.successDark),
      ('Định giá', snapshot.valScore, AppColors.warningDark),
      ('Ngắn hạn', snapshot.shortTermScore, AppColors.brandSecondaryDark),
      ('Dài hạn', snapshot.longTermScore, AppColors.goldenAccent),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Điểm thành phần',
              style: TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...items.map((e) => _ScoreBar(label: e.$1, value: e.$2, color: e.$3)),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _ScoreBar(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.darkTextSecondary, fontSize: 13)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 8,
                backgroundColor: AppColors.darkBorder,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              value.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── VNINDEX kỹ thuật ──────────────────────────────────────────────────────────

class _VnindexCard extends StatelessWidget {
  final MarketEvaluation snapshot;
  const _VnindexCard({required this.snapshot});

  String _fmt(double? v, {int dec = 1}) =>
      v != null ? v.toStringAsFixed(dec) : '--';

  @override
  Widget build(BuildContext context) {
    final pct = snapshot.pctVsMa20;
    final pctColor = pct == null
        ? AppColors.darkTextMuted
        : pct >= 0
            ? AppColors.successDark
            : AppColors.dangerDark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('VNINDEX',
                style: TextStyle(
                    color: AppColors.darkTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            if (pct != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: pctColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(
                  '${pct >= 0 ? '+' : ''}${_fmt(pct)}% vs MA20',
                  style: TextStyle(color: pctColor, fontSize: 12),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Text(
              _fmt(snapshot.vnindex, dec: 2),
              style: const TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            _Chip('RSI ${_fmt(snapshot.rsi14)}', AppColors.brandPrimaryDark),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _StatItem('MA20', _fmt(snapshot.ma20, dec: 2)),
            _StatItem('MA60', _fmt(snapshot.ma60, dec: 2)),
            _StatItem('Biến động', '${_fmt(snapshot.volatility20dPct)}%'),
            _StatItem('20d', '${snapshot.pctChange20d != null ? (snapshot.pctChange20d! >= 0 ? '+' : '') : ''}${_fmt(snapshot.pctChange20d)}%'),
          ]),
          if (snapshot.nearestSupport != null || snapshot.nearestResistance != null) ...[
            const Divider(height: 20, color: AppColors.darkBorder),
            Row(children: [
              _StatItem('Hỗ trợ', _fmt(snapshot.nearestSupport, dec: 2)),
              _StatItem('Kháng cự', _fmt(snapshot.nearestResistance, dec: 2)),
              if (snapshot.pctToSupport != null)
                _StatItem('Đến HT', '${_fmt(snapshot.pctToSupport)}%'),
              if (snapshot.pctToResistance != null)
                _StatItem('Đến KC', '${_fmt(snapshot.pctToResistance)}%'),
            ]),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.darkTextMuted, fontSize: 11)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6)),
      child:
          Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

// ── Macro + Breadth ───────────────────────────────────────────────────────────

class _MacroBreadthCard extends StatelessWidget {
  final MarketEvaluation snapshot;
  const _MacroBreadthCard({required this.snapshot});

  String _f(double? v, {int dec = 2}) =>
      v != null ? v.toStringAsFixed(dec) : '--';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vĩ mô & Độ rộng',
              style: TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill('VIX', _f(snapshot.vix)),
              _InfoPill('DXY', _f(snapshot.dxy)),
              _InfoPill('US10Y', '${_f(snapshot.us10y)}%'),
              _InfoPill('VN10Y', '${_f(snapshot.vn10y)}%'),
              _InfoPill('USD/VND', snapshot.usdvnd != null ? snapshot.usdvnd!.toStringAsFixed(0) : '--'),
              _InfoPill('Brent', _f(snapshot.brentOil, dec: 1)),
              _InfoPill('ERP', '${_f(snapshot.erp)}%'),
              _InfoPill('PE trung vị', _f(snapshot.medianPe, dec: 1)),
              _InfoPill('Trên MA20', snapshot.pctAboveMa20 != null ? '${_f(snapshot.pctAboveMa20, dec: 1)}%' : '--'),
              _InfoPill('Trên MA50', snapshot.pctAboveMa50 != null ? '${_f(snapshot.pctAboveMa50, dec: 1)}%' : '--'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  const _InfoPill(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkBorder.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.darkTextMuted, fontSize: 10)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── AI Sentiment ──────────────────────────────────────────────────────────────

class _AiSentimentCard extends StatelessWidget {
  final AiSentiment sentiment;
  const _AiSentimentCard({required this.sentiment});

  Color _sentColor(String color) {
    switch (color) {
      case 'positive':
        return AppColors.successDark;
      case 'negative':
        return AppColors.dangerDark;
      case 'caution':
        return AppColors.warningDark;
      default:
        return AppColors.darkTextMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.brandPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome,
                color: AppColors.brandPrimaryDark, size: 18),
            const SizedBox(width: 8),
            const Text('AI Sentiment',
                style: TextStyle(
                    color: AppColors.darkTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              '${sentiment.score.toStringAsFixed(0)}/100',
              style: const TextStyle(
                  color: AppColors.brandPrimaryDark,
                  fontWeight: FontWeight.bold),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _SentimentLabel(
                  'Ngắn hạn',
                  sentiment.shortTerm.label,
                  _sentColor(sentiment.shortTerm.color)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SentimentLabel(
                  'Dài hạn',
                  sentiment.longTerm.label,
                  _sentColor(sentiment.longTerm.color)),
            ),
          ]),
          if (sentiment.summary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              sentiment.summary,
              style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 13,
                  height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _SentimentLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SentimentLabel(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.darkTextMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── History Chart ─────────────────────────────────────────────────────────────

class _HistorySection extends StatelessWidget {
  final List<MarketEvaluationHistoryItem> history;
  final int days;
  final ValueChanged<int> onDaysChanged;

  const _HistorySection({
    required this.history,
    required this.days,
    required this.onDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Lịch sử điểm',
                style: TextStyle(
                    color: AppColors.darkTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            ...([30, 90, 180].map((d) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: GestureDetector(
                    onTap: () => onDaysChanged(d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: days == d
                            ? AppColors.brandPrimary.withValues(alpha: 0.25)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: days == d
                              ? AppColors.brandPrimary
                              : AppColors.darkBorder,
                        ),
                      ),
                      child: Text(
                        '${d}D',
                        style: TextStyle(
                          color: days == d
                              ? AppColors.brandPrimaryDark
                              : AppColors.darkTextMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ))),
          ]),
          const SizedBox(height: 16),
          if (history.isEmpty)
            const Center(
              child: Text('Chưa có dữ liệu lịch sử',
                  style: TextStyle(color: AppColors.darkTextMuted)),
            )
          else
            SizedBox(height: 180, child: _ScoreLineChart(history: history)),
          const SizedBox(height: 8),
          Row(children: [
            _LegendDot(AppColors.brandPrimaryDark, 'Điểm tổng hợp'),
            const SizedBox(width: 16),
            _LegendDot(AppColors.warningDark, 'Điểm quant'),
          ]),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 11)),
    ]);
  }
}

class _ScoreLineChart extends StatelessWidget {
  final List<MarketEvaluationHistoryItem> history;
  const _ScoreLineChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final finalSpots = <FlSpot>[];
    final quantSpots = <FlSpot>[];
    for (var i = 0; i < history.length; i++) {
      final h = history[i];
      if (h.finalScore != null) finalSpots.add(FlSpot(i.toDouble(), h.finalScore!));
      if (h.quantScore != null) quantSpots.add(FlSpot(i.toDouble(), h.quantScore!));
    }
    final labelStep = history.length > 60 ? 20 : history.length > 30 ? 10 : 5;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.darkBorder, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(
                    color: AppColors.darkTextMuted, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: labelStep.toDouble(),
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= history.length) return const SizedBox.shrink();
                final date = history[idx].date;
                final parts = date.split('-');
                final label = parts.length >= 3 ? '${parts[2]}/${parts[1]}' : date;
                return Text(label,
                    style: const TextStyle(
                        color: AppColors.darkTextMuted, fontSize: 9));
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.darkSurfaceElevated,
            getTooltipItems: (spots) => spots.map((s) {
              final color = s.barIndex == 0
                  ? AppColors.brandPrimaryDark
                  : AppColors.warningDark;
              return LineTooltipItem(
                s.y.toStringAsFixed(1),
                TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: finalSpots,
            isCurved: true,
            color: AppColors.brandPrimaryDark,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.brandPrimaryDark.withValues(alpha: 0.08),
            ),
          ),
          LineChartBarData(
            spots: quantSpots,
            isCurved: true,
            color: AppColors.warningDark,
            barWidth: 1.5,
            dashArray: [4, 4],
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
