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
          (_) => const Padding(
                padding: EdgeInsets.only(bottom: 16),
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
        _HistorySection(
          history: _history,
          days: _historyDays,
          onDaysChanged: (d) {
            setState(() => _historyDays = d);
            _load();
          },
        ),
        if (s.marketBreadth != null) ...[
          const SizedBox(height: 16),
          _BreadthGroupsCard(state: s.marketBreadth!, exposurePct: s.finalScore),
        ],
        const SizedBox(height: 16),
        _VnindexCard(snapshot: s),
        const SizedBox(height: 16),
        _MacroBreadthCard(snapshot: s),
      ],
    );
  }
}

// ── Tỷ trọng cổ phiếu gợi ý (mô hình độ rộng) ─────────────────────────────────
// Trước 23/11/2026 thẻ này đọc `final_score` như điểm /100 với vùng 35/50/65 («Tốt/Khá/Thận trọng/Xấu») của điểm tổng
// hợp cũ; từ 09/11 nó là tỷ trọng cổ phiếu gợi ý theo độ rộng (lưới 1/6) — nhãn lấy từ server (`label`).

Color _regimeColor(String regime) {
  switch (regime) {
    case 'bullish':
      return AppColors.successDark;
    case 'bearish':
      return AppColors.dangerDark;
    default:
      return AppColors.warningDark;
  }
}

class _ScoreCard extends StatelessWidget {
  final MarketEvaluation snapshot;
  const _ScoreCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final s = snapshot.finalScore;
    final color = _regimeColor(snapshot.regime);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tỷ trọng cổ phiếu gợi ý',
              style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${s.round()}%',
                style: TextStyle(
                    color: color, fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              if (snapshot.label.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(snapshot.label,
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Phần tài sản nên để ở cổ phiếu, tính từ độ rộng thị trường (số đông cổ phiếu khoẻ hay yếu). '
            'Tín hiệu quản trị rủi ro chung, không dự báo một mã.',
            style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12, height: 1.4),
          ),
          if (snapshot.snapshotUpdatedAt.isNotEmpty)
            Text('Cập nhật ${snapshot.snapshotUpdatedAt}',
                style: const TextStyle(
                    color: AppColors.darkTextMuted, fontSize: 11)),
          const SizedBox(height: 14),
          _ZoneGaugeBar(score: s),
        ],
      ),
    );
  }
}

class _ZoneGaugeBar extends StatelessWidget {
  final double score;
  const _ZoneGaugeBar({required this.score});

  // Ranh của mô hình độ rộng: ≤ 1/3 độ rộng yếu (chặn mua), giữa = vào từng phần, ≥ 2/3 mạnh.
  static const _zones = [
    (end: 33.3, color: AppColors.dangerDark,  label: 'Độ rộng yếu'),
    (end: 66.7, color: AppColors.warningDark, label: 'Trung tính'),
    (end: 100.0, color: AppColors.successDark, label: 'Độ rộng mạnh'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final w = constraints.maxWidth;
      final indicatorX = (score / 100 * w).clamp(0, w).toDouble();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thanh màu + chỉ thị ───────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Thanh nền phân vùng
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    for (int i = 0; i < _zones.length; i++) ...[
                      Flexible(
                        flex: (i == 1 ? 34 : 33),
                        child: Container(
                          height: 12,
                          color: _zones[i].color.withValues(alpha: 0.35),
                        ),
                      ),
                      if (i < _zones.length - 1)
                        Container(width: 1, height: 12, color: AppColors.darkBg),
                    ],
                  ],
                ),
              ),
              // Chỉ thị vị trí điểm
              Positioned(
                left: (indicatorX - 1.5).clamp(0, w - 3),
                child: Column(
                  children: [
                    Container(
                      width: 3,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                      ),
                    ),
                    // Mũi tên nhỏ bên dưới
                    CustomPaint(size: const Size(8, 5), painter: _TrianglePainter()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Nhãn mốc ────────────────────────────────
          Stack(
            children: [
              SizedBox(height: 14, width: w),
              for (final milestone in [0, 33, 50, 67, 100])
                Positioned(
                  left: (milestone / 100 * w).clamp(0, w - 1),
                  child: Transform.translate(
                    offset: Offset(milestone == 0 ? 0 : milestone == 100 ? -26 : -12, 0),
                    child: Text(
                      '$milestone%',
                      style: TextStyle(
                        fontSize: 9,
                        color: _labelColor(milestone.toDouble()),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // ── Legend vùng ────────────────────────────────
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: _zones.map((z) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: z.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(z.label,
                    style: const TextStyle(
                        color: AppColors.darkTextMuted, fontSize: 10)),
              ],
            )).toList(),
          ),
        ],
      );
    });
  }

  Color _labelColor(double v) {
    if (v >= 66.7) return AppColors.successDark;
    if (v > 33.3) return AppColors.warningDark;
    return AppColors.dangerDark;
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Breakdown 5 điểm thành phần ───────────────────────────────────────────────

/// Ba nhóm chỉ báo độ rộng — CHÍNH thứ quyết định tỷ trọng gợi ý (cùng thẻ trên web). Thay thẻ «Điểm thành phần»
/// (Kỹ thuật/Độ rộng/Định giá/Ngắn hạn/Dài hạn) đã gỡ 23/11/2026.
class _BreadthGroupsCard extends StatelessWidget {
  final MarketBreadthState state;
  final double exposurePct;
  const _BreadthGroupsCard({required this.state, required this.exposurePct});

  Color _c(double score) => score >= 1
      ? AppColors.successDark
      : score <= 0
          ? AppColors.dangerDark
          : AppColors.warningDark;

  @override
  Widget build(BuildContext context) {
    final raw = state.exposureRawPct?.round();
    final cur = exposurePct.round();
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
          const Text('Ba nhóm chỉ báo độ rộng',
              style: TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Mỗi nhóm khoẻ cộng 1/3 tỷ trọng gợi ý.',
              style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12)),
          const SizedBox(height: 12),
          for (final g in state.groups) ...[
            Row(children: [
              Expanded(
                child: Text(g.label,
                    style: const TextStyle(
                        color: AppColors.darkTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _c(g.score).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(g.status,
                    style: TextStyle(
                        color: _c(g.score),
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 4),
            for (final ind in g.indicators)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Row(children: [
                  Expanded(
                    child: Text(ind.label,
                        style: const TextStyle(
                            color: AppColors.darkTextSecondary, fontSize: 12)),
                  ),
                  Text(
                    ind.healthy == null ? '—' : (ind.healthy! ? 'khoẻ' : 'yếu'),
                    style: TextStyle(
                      color: ind.healthy == null
                          ? AppColors.darkTextMuted
                          : (ind.healthy! ? AppColors.successDark : AppColors.dangerDark),
                      fontSize: 12,
                    ),
                  ),
                ]),
              ),
            const SizedBox(height: 10),
          ],
          Text(
            '${state.provisional ? 'Tạm tính trong phiên · ' : ''}'
            '${raw != null ? 'Tín hiệu thô $raw% · ' : ''}tỷ trọng gợi ý $cur%'
            '${raw != null && raw != cur ? ' (giữ mức cũ vì tín hiệu chưa lệch đủ 1/3 — tránh mua bán qua lại)' : ''}.',
            style: const TextStyle(
                color: AppColors.darkTextMuted, fontSize: 11, height: 1.4),
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
            const SizedBox(width: 12),
            if (snapshot.pctChange20d != null)
              Text(
                '${snapshot.pctChange20d! >= 0 ? '+' : ''}${_fmt(snapshot.pctChange20d)}% (20d)',
                style: TextStyle(
                  color: snapshot.pctChange20d! >= 0 ? AppColors.successDark : AppColors.dangerDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const Spacer(),
            _Chip('RSI ${_fmt(snapshot.rsi14)}', AppColors.brandPrimaryDark),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _StatItem('MA20', _fmt(snapshot.ma20, dec: 0)),
            _StatItem('MA60', _fmt(snapshot.ma60, dec: 0)),
            _StatItem('Biến động', '${_fmt(snapshot.volatility20dPct)}%'),
          ]),
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
              _InfoPill('VIX', _f(snapshot.vix, dec: 1)),
              _InfoPill('ERP', '${_f(snapshot.erp)}%'),
              _InfoPill('PE TT', _f(snapshot.medianPe, dec: 1)),
              _InfoPill('Trên MA20', snapshot.pctAboveMa20 != null ? '${_f(snapshot.pctAboveMa20, dec: 0)}%' : '--'),
              _InfoPill('Brent', _f(snapshot.brentOil, dec: 0)),
              _InfoPill('USD/VND', snapshot.usdvnd != null ? snapshot.usdvnd!.toStringAsFixed(0) : '--'),
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
            const Text('Lịch sử tỷ trọng gợi ý',
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
            SizedBox(height: 240, child: _CombinedChart(history: history)),
          const SizedBox(height: 8),
          const Row(children: [
            _LegendDot(AppColors.brandPrimaryDark, 'Tỷ trọng gợi ý'),
            SizedBox(width: 16),
            _LegendDot(AppColors.successDark, 'VNINDEX'),
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

// Chart kết hợp: điểm tổng hợp (trục trái 0-100) + VNINDEX (trục phải, normalize về 0-100)
class _CombinedChart extends StatelessWidget {
  final List<MarketEvaluationHistoryItem> history;
  const _CombinedChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final scoreSpots = <FlSpot>[];
    final vniRawSpots = <({int i, double v})>[];

    for (var i = 0; i < history.length; i++) {
      final h = history[i];
      if (h.finalScore != null) scoreSpots.add(FlSpot(i.toDouble(), h.finalScore!));
      if (h.vnindex != null) vniRawSpots.add((i: i, v: h.vnindex!));
    }

    // Normalize VNINDEX vào dải 0-100 để vẽ trên cùng canvas
    double minVni = 0, maxVni = 100;
    if (vniRawSpots.isNotEmpty) {
      minVni = vniRawSpots.map((e) => e.v).reduce((a, b) => a < b ? a : b);
      maxVni = vniRawSpots.map((e) => e.v).reduce((a, b) => a > b ? a : b);
      if (maxVni == minVni) maxVni = minVni + 1;
    }
    final vniRange = maxVni - minVni;
    final vniSpots = vniRawSpots
        .map((e) => FlSpot(e.i.toDouble(), (e.v - minVni) / vniRange * 100))
        .toList();

    final labelStep = history.length > 60 ? 20 : history.length > 30 ? 10 : 5;

    // Giá trị VNINDEX thực ứng với trục phải tại 0/25/50/75/100 (normalized)
    double vniAt(double norm) => minVni + norm / 100 * vniRange;

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
                style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 9),
              ),
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: vniSpots.isNotEmpty,
              interval: 25,
              reservedSize: 44,
              getTitlesWidget: (v, _) => Text(
                vniAt(v).toStringAsFixed(0),
                style: const TextStyle(color: AppColors.successDark, fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: labelStep.toDouble(),
              reservedSize: 20,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= history.length) return const SizedBox.shrink();
                final parts = history[idx].date.split('-');
                final label = parts.length >= 3 ? '${parts[2]}/${parts[1]}' : '';
                return Text(label,
                    style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 9));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.darkSurfaceElevated,
            getTooltipItems: (spots) => spots.map((s) {
              if (s.barIndex == 0) {
                return LineTooltipItem(
                  'Tỷ trọng gợi ý: ${s.y.round()}%',
                  const TextStyle(color: AppColors.brandPrimaryDark, fontSize: 11, fontWeight: FontWeight.w600),
                );
              } else {
                final actual = vniAt(s.y);
                return LineTooltipItem(
                  'VNI: ${actual.toStringAsFixed(0)}',
                  const TextStyle(color: AppColors.successDark, fontSize: 11, fontWeight: FontWeight.w600),
                );
              }
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: scoreSpots,
            isCurved: true,
            color: AppColors.brandPrimaryDark,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.brandPrimaryDark.withValues(alpha: 0.08),
            ),
          ),
          if (vniSpots.isNotEmpty)
            LineChartBarData(
              spots: vniSpots,
              isCurved: true,
              color: AppColors.successDark,
              barWidth: 1.5,
              dotData: const FlDotData(show: false),
            ),
        ],
      ),
    );
  }
}
