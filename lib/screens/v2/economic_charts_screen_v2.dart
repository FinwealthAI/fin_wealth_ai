import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/api_config.dart';
import '../../respositories/investment_opportunities_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class _ChartItem {
  final int id;
  final String title;
  final String unit;
  final String latestDate;
  const _ChartItem(
      {required this.id,
      required this.title,
      required this.unit,
      required this.latestDate});
}

class _ChartGroup {
  final String category;
  final List<_ChartItem> charts;
  const _ChartGroup({required this.category, required this.charts});
}

class _Point {
  final String date;
  final double value;
  const _Point(this.date, this.value);
}

class _TickerLink {
  final String ticker;
  final String correlation; // 'positive' | 'negative'
  final String reason;
  const _TickerLink(
      {required this.ticker,
      required this.correlation,
      required this.reason});
}

// ─── Main screen ─────────────────────────────────────────────────────────────

class EconomicChartsScreenV2 extends StatefulWidget {
  final int? openIndicatorId;
  final String? openIndicatorTitle;
  const EconomicChartsScreenV2(
      {super.key, this.openIndicatorId, this.openIndicatorTitle});

  @override
  State<EconomicChartsScreenV2> createState() =>
      _EconomicChartsScreenV2State();
}

class _EconomicChartsScreenV2State extends State<EconomicChartsScreenV2> {
  List<_ChartGroup> _groups = const [];
  bool _loading = true;
  Object? _err;

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
      final dio = context.read<InvestmentOpportunitiesRepository>().dio;
      final resp = await dio.get(ApiConfig.chartsList);
      final groups = (resp.data['groups'] as List<dynamic>)
          .map((g) => _ChartGroup(
                category: g['category'] as String,
                charts: (g['charts'] as List<dynamic>)
                    .map((c) => _ChartItem(
                          id: c['id'] as int,
                          title: c['title'] as String,
                          unit: c['unit'] as String? ?? '',
                          latestDate: c['latest_date'] as String? ?? '',
                        ))
                    .toList(),
              ))
          .toList();
      if (mounted) {
        setState(() {
          _groups = groups;
          _loading = false;
        });
        final targetId = widget.openIndicatorId;
        if (targetId != null) {
          _ChartItem? match;
          outer:
          for (final g in groups) {
            for (final c in g.charts) {
              if (c.id == targetId) {
                match = c;
                break outer;
              }
            }
          }
          final item = match ??
              _ChartItem(
                id: targetId,
                title: widget.openIndicatorTitle ?? '',
                unit: '',
                latestDate: '',
              );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _openChart(item);
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() {
        _err = e;
        _loading = false;
      });
    }
  }

  void _openChart(_ChartItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ChartDetailScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FwAppBar(
        title: 'Biểu đồ kinh tế',
        subtitle: 'Hàng hóa & Tỷ giá',
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: 8,
                itemBuilder: (_, __) =>
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: FwSkeleton(height: 56, radius: AppRadius.md),
                    ),
              )
            : _err != null
                ? Center(
                    child: FwEmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Không tải được dữ liệu',
                      message:
                          _err.toString().replaceFirst('Exception: ', ''),
                      action: FwButton(
                          label: 'Thử lại', onPressed: _load),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    itemCount: _groups.length,
                    itemBuilder: (_, gi) {
                      final group = _groups[gi];
                      return _GroupSection(
                        group: group,
                        onTap: _openChart,
                      );
                    },
                  ),
      ),
    );
  }
}

// ─── Group section ────────────────────────────────────────────────────────────

class _GroupSection extends StatelessWidget {
  final _ChartGroup group;
  final void Function(_ChartItem) onTap;
  const _GroupSection({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  size: 16, color: AppColors.brandPrimaryDark),
              const SizedBox(width: AppSpacing.sm),
              Text(group.category,
                  style: text.titleSmall?.copyWith(
                      color: AppColors.brandPrimaryDark,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimaryDark.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${group.charts.length}',
                    style: text.labelSmall
                        ?.copyWith(color: AppColors.brandPrimaryDark)),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            children: [
              for (int i = 0; i < group.charts.length; i++) ...[
                if (i > 0)
                  Divider(
                      height: 1,
                      color: AppColors.darkBorder.withValues(alpha: 0.5)),
                InkWell(
                  onTap: () => onTap(group.charts[i]),
                  borderRadius: BorderRadius.vertical(
                    top: i == 0
                        ? const Radius.circular(AppRadius.lg)
                        : Radius.zero,
                    bottom: i == group.charts.length - 1
                        ? const Radius.circular(AppRadius.lg)
                        : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(Icons.show_chart,
                              size: 16,
                              color: AppColors.brandPrimaryDark),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(group.charts[i].title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600)),
                              if (group.charts[i].unit.isNotEmpty)
                                Text(
                                  'Đơn vị: ${group.charts[i].unit}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: AppColors.darkTextMuted),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          group.charts[i].latestDate,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.darkTextMuted),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.chevron_right,
                            size: 18, color: AppColors.darkTextMuted),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

// ─── Chart detail screen ──────────────────────────────────────────────────────

class _ChartDetailScreen extends StatefulWidget {
  final _ChartItem item;
  const _ChartDetailScreen({required this.item});

  @override
  State<_ChartDetailScreen> createState() => _ChartDetailScreenState();
}

class _ChartDetailScreenState extends State<_ChartDetailScreen> {
  List<_Point> _points = const [];
  List<_TickerLink> _tickers = const [];
  String _unit = '';
  bool _loading = true;
  Object? _err;

  // Range selector: 90d, 180d, 1y, 3y, all
  int _rangeIndex = 2; // default 1y
  static const _ranges = [
    ('3T', 90),
    ('6T', 180),
    ('1N', 365),
    ('3N', 1095),
    ('Tất cả', 99999),
  ];

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
      final dio = context.read<InvestmentOpportunitiesRepository>().dio;
      final resp = await dio.get(ApiConfig.chartData(widget.item.id));
      final data = resp.data as Map<String, dynamic>;
      final pts = (data['points'] as List<dynamic>)
          .map((p) => _Point(
                p['date'] as String,
                (p['value'] as num).toDouble(),
              ))
          .toList();
      final tickers = ((data['tickers'] as List<dynamic>?) ?? [])
          .map((t) => _TickerLink(
                ticker: t['ticker'] as String? ?? '',
                correlation: t['correlation'] as String? ?? 'positive',
                reason: t['reason'] as String? ?? '',
              ))
          .where((t) => t.ticker.isNotEmpty)
          .toList();
      if (mounted) setState(() {
        _points = pts;
        _tickers = tickers;
        _unit = data['unit'] as String? ?? '';
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _err = e;
        _loading = false;
      });
    }
  }

  List<_Point> get _filtered {
    final days = _ranges[_rangeIndex].$2;
    if (days >= 99999 || _points.isEmpty) return _points;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _points.where((p) {
      try {
        return DateTime.parse(p.date).isAfter(cutoff);
      } catch (_) {
        return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _err != null
              ? Center(
                  child: FwEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Không tải được biểu đồ',
                    message: _err.toString().replaceFirst('Exception: ', ''),
                    action: FwButton(label: 'Thử lại', onPressed: _load),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Range selector
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                            child: Row(
                              children: List.generate(_ranges.length, (i) {
                                final selected = i == _rangeIndex;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _rangeIndex = i),
                                    child: Container(
                                      margin: EdgeInsets.only(
                                          right: i < _ranges.length - 1 ? 6 : 0),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppColors.brandPrimaryDark
                                                .withValues(alpha: 0.2)
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.sm),
                                        border: Border.all(
                                          color: selected
                                              ? AppColors.brandPrimaryDark
                                              : Colors.white12,
                                        ),
                                      ),
                                      child: Text(
                                        _ranges[i].$1,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: selected
                                              ? AppColors.brandPrimaryDark
                                              : AppColors.darkTextMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),

                          // Stats row
                          if (_filtered.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                              child: _StatsRow(
                                  points: _filtered,
                                  unit: _unit,
                                  text: text),
                            ),

                          // Chart
                          if (_filtered.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 48),
                              child: FwEmptyState(
                                icon: Icons.bar_chart_outlined,
                                title: 'Không có dữ liệu',
                              ),
                            )
                          else
                            SizedBox(
                              height: 260,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    AppSpacing.lg,
                                    AppSpacing.lg,
                                    AppSpacing.lg),
                                child: _LineChartWidget(
                                    points: _filtered, unit: _unit),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Tickers section
                    if (_tickers.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _TickersSection(tickers: _tickers),
                      ),

                    const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.xxxl)),
                  ],
                ),
    );
  }
}

// ─── Tickers section ─────────────────────────────────────────────────────────

class _TickersSection extends StatelessWidget {
  final List<_TickerLink> tickers;
  const _TickersSection({required this.tickers});

  @override
  Widget build(BuildContext context) {
    final positive = tickers.where((t) => t.correlation == 'positive').toList();
    final negative = tickers.where((t) => t.correlation != 'positive').toList();
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'CỔ PHIẾU LIÊN QUAN',
              style: text.labelSmall?.copyWith(
                  letterSpacing: 1.2, color: AppColors.darkTextMuted),
            ),
          ),
          if (positive.isNotEmpty) ...[
            _CorrelationGroup(
              label: 'Hưởng lợi',
              icon: Icons.trending_up,
              color: AppColors.successDark,
              tickers: positive,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (negative.isNotEmpty)
            _CorrelationGroup(
              label: 'Bất lợi',
              icon: Icons.trending_down,
              color: AppColors.dangerDark,
              tickers: negative,
            ),
        ],
      ),
    );
  }
}

class _CorrelationGroup extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final List<_TickerLink> tickers;
  const _CorrelationGroup({
    required this.label,
    required this.icon,
    required this.color,
    required this.tickers,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: text.labelSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: tickers
                .map((t) => Tooltip(
                      message: t.reason.isNotEmpty ? t.reason : t.ticker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: color.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          t.ticker,
                          style: text.labelSmall?.copyWith(
                              color: color, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final List<_Point> points;
  final String unit;
  final TextTheme text;
  const _StatsRow(
      {required this.points, required this.unit, required this.text});

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return v.toStringAsFixed(0);
    if (v >= 1) return v.toStringAsFixed(2);
    return v.toStringAsFixed(4);
  }

  @override
  Widget build(BuildContext context) {
    final last = points.last.value;
    final first = points.first.value;
    final pct = first != 0 ? ((last - first) / first * 100) : 0.0;
    final isUp = pct >= 0;
    final minV = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxV = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          _stat('Hiện tại',
              '${_fmt(last)} ${unit.isNotEmpty ? unit : ""}', Colors.white,
              text: text),
          _divider(),
          _stat(
              'Thay đổi',
              '${isUp ? "+" : ""}${pct.toStringAsFixed(2)}%',
              isUp ? AppColors.successDark : AppColors.dangerDark,
              text: text),
          _divider(),
          _stat('Thấp nhất', _fmt(minV), AppColors.darkTextMuted, text: text),
          _divider(),
          _stat('Cao nhất', _fmt(maxV), AppColors.darkTextMuted, text: text),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1, height: 32, color: Colors.white10,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      );

  Widget _stat(String label, String value, Color color,
          {required TextTheme text}) =>
      Expanded(
        child: Column(
          children: [
            Text(label,
                style: text.bodySmall?.copyWith(color: AppColors.darkTextMuted),
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(value,
                style: text.labelMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );
}

// ─── Line chart ───────────────────────────────────────────────────────────────

class _LineChartWidget extends StatelessWidget {
  final List<_Point> points;
  final String unit;
  const _LineChartWidget({required this.points, required this.unit});

  String _fmtY(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    if (v >= 1) return v.toStringAsFixed(1);
    return v.toStringAsFixed(3);
  }

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    // Subsample to max 300 points for performance
    final step = (points.length / 300).ceil().clamp(1, 9999);
    final sampled = [
      for (int i = 0; i < points.length; i += step) points[i],
      if ((points.length - 1) % step != 0) points.last,
    ];

    final spots = sampled.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    final minY = sampled.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxY = sampled.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final pad = range * 0.05;

    final first = points.first;
    final last = points.last;
    final isUp = last.value >= first.value;
    final lineColor =
        isUp ? AppColors.successDark : AppColors.dangerDark;

    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: range > 0 ? range / 4 : 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: range > 0 ? range / 4 : 1,
              getTitlesWidget: (v, _) => Text(
                _fmtY(v),
                style: const TextStyle(
                    color: AppColors.darkTextMuted, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (sampled.length / 4).ceilToDouble(),
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= sampled.length) {
                  return const SizedBox.shrink();
                }
                final d = sampled[idx].date;
                final parts = d.split('-');
                final label = parts.length >= 2
                    ? '${parts[1]}/${parts[0].substring(2)}'
                    : d;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(label,
                      style: const TextStyle(
                          color: AppColors.darkTextMuted, fontSize: 10)),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final idx = s.spotIndex;
              final date = idx < sampled.length ? sampled[idx].date : '';
              return LineTooltipItem(
                '$date\n${_fmtY(s.y)} $unit',
                const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: lineColor,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  lineColor.withValues(alpha: 0.25),
                  lineColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
