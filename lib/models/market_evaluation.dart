double? _toD(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '').trim());
  return null;
}

/// Một chỉ báo trong mô hình độ rộng (vd "% mã trên MA20"): khoẻ/yếu so với ngưỡng.
class BreadthIndicator {
  final String label;
  final bool? healthy;

  BreadthIndicator({required this.label, this.healthy});

  factory BreadthIndicator.fromJson(Map<String, dynamic> j) =>
      BreadthIndicator(label: j['label'] ?? '', healthy: j['healthy'] as bool?);
}

/// Một nhóm chỉ báo độ rộng (Sớm · Xác nhận · Dài hạn). `score` 1 = khoẻ, 0 = yếu, giữa = lẫn lộn.
/// Mỗi nhóm khoẻ cộng 1/3 vào tỷ trọng cổ phiếu gợi ý (`quant/services/market_breadth.py`).
class BreadthGroup {
  final String label;
  final double score;
  final List<BreadthIndicator> indicators;

  BreadthGroup({required this.label, required this.score, required this.indicators});

  String get status => score >= 1 ? 'khoẻ' : score <= 0 ? 'yếu' : 'lẫn lộn';

  factory BreadthGroup.fromJson(Map<String, dynamic> j) => BreadthGroup(
        label: j['label'] ?? '',
        score: _toD(j['score']) ?? 0,
        indicators: ((j['indicators'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(BreadthIndicator.fromJson)
            .toList(),
      );
}

/// Trạng thái mô hình độ rộng quyết định tỷ trọng gợi ý (`market_breadth` của API).
class MarketBreadthState {
  final List<BreadthGroup> groups;
  final double? exposureRawPct;
  final String asOf;
  final bool provisional;

  MarketBreadthState({
    required this.groups,
    this.exposureRawPct,
    required this.asOf,
    required this.provisional,
  });

  static MarketBreadthState? fromJson(dynamic j) {
    if (j is! Map<String, dynamic>) return null;
    final groups = (j['groups'] as Map<String, dynamic>?) ?? const {};
    if (groups.isEmpty) return null;
    final raw = _toD(j['exposure_raw']);
    return MarketBreadthState(
      groups: groups.values
          .whereType<Map<String, dynamic>>()
          .map(BreadthGroup.fromJson)
          .toList(),
      exposureRawPct: raw != null ? raw * 100 : null,
      asOf: j['as_of']?.toString() ?? '',
      provisional: j['provisional'] == true,
    );
  }
}

class MarketEvaluation {
  // Tổng hợp
  final String regime;
  final String label;
  final String cautionLevel;
  final double finalScore;
  final String snapshotUpdatedAt;

  /// Ba nhóm chỉ báo độ rộng tạo ra `finalScore` (null khi server chưa có).
  final MarketBreadthState? marketBreadth;

  // Điểm Kỹ thuật/Định giá/Tổng hợp/AI/Ngắn hạn/Dài hạn đã gỡ 23/11/2026 (backend đo lại trên production: không
  // hơn nắm giữ thụ động, điểm AI chấm ngược) — đừng thêm lại với mặc định 50: app sẽ hiện "50" như số đo có thật.

  // VNINDEX kỹ thuật
  final double? vnindex;
  final double? ma20;
  final double? ma60;
  final double? pctVsMa20;
  final double? pctChange20d;
  final double? volatility20dPct;
  final double? rsi14;
  final double? nearestSupport;
  final double? nearestResistance;
  final double? pctToSupport;
  final double? pctToResistance;

  // Breadth
  final double? pctAboveMa20;
  final double? pctAboveMa50;

  // Valuation
  final double? medianPe;
  final double? erp;
  final double? rf;

  // Macro
  final double? vix;
  final double? dxy;
  final double? us10y;
  final double? vn10y;
  final double? usdvnd;
  final double? brentOil;
  final double? interbankRate;

  MarketEvaluation({
    required this.regime,
    required this.label,
    required this.cautionLevel,
    required this.finalScore,
    required this.snapshotUpdatedAt,
    this.marketBreadth,
    this.vnindex,
    this.ma20,
    this.ma60,
    this.pctVsMa20,
    this.pctChange20d,
    this.volatility20dPct,
    this.rsi14,
    this.nearestSupport,
    this.nearestResistance,
    this.pctToSupport,
    this.pctToResistance,
    this.pctAboveMa20,
    this.pctAboveMa50,
    this.medianPe,
    this.erp,
    this.rf,
    this.vix,
    this.dxy,
    this.us10y,
    this.vn10y,
    this.usdvnd,
    this.brentOil,
    this.interbankRate,
  });

  factory MarketEvaluation.fromJson(Map<String, dynamic> j) => MarketEvaluation(
        regime: j['regime'] ?? 'sideways',
        label: j['label'] ?? '',
        cautionLevel: j['caution_level'] ?? 'medium',
        finalScore: _toD(j['final_score']) ?? 50,
        snapshotUpdatedAt: j['snapshot_updated_at'] ?? '',
        marketBreadth: MarketBreadthState.fromJson(j['market_breadth']),
        vnindex: _toD(j['vnindex']),
        ma20: _toD(j['ma20']),
        ma60: _toD(j['ma60']),
        pctVsMa20: _toD(j['pct_vs_ma20']),
        pctChange20d: _toD(j['pct_change_20d']),
        volatility20dPct: _toD(j['volatility_20d_pct']),
        rsi14: _toD(j['rsi_14']),
        nearestSupport: _toD(j['nearest_support']),
        nearestResistance: _toD(j['nearest_resistance']),
        pctToSupport: _toD(j['pct_to_support']),
        pctToResistance: _toD(j['pct_to_resistance']),
        pctAboveMa20: _toD(j['pct_above_ma20']),
        pctAboveMa50: _toD(j['pct_above_ma50']),
        medianPe: _toD(j['median_pe']),
        erp: _toD(j['erp']),
        rf: _toD(j['rf']),
        vix: _toD(j['vix']),
        dxy: _toD(j['dxy']),
        us10y: _toD(j['us10y']),
        vn10y: _toD(j['vn10y']),
        usdvnd: _toD(j['usdvnd']),
        brentOil: _toD(j['brent_oil']),
        interbankRate: _toD(j['interbank_rate']),
      );
}

class MarketEvaluationHistoryItem {
  final String date;
  final double? finalScore;
  final double? breadthScore;
  final String regime;
  final double? vnindex;
  final double? ma20;
  final double? ma60;
  final double? rsi14;
  final double? pctAboveMa20;
  final double? pctAboveMa50;
  final double? erp;
  final double? medianPe;
  final double? vix;

  MarketEvaluationHistoryItem({
    required this.date,
    this.finalScore,
    this.breadthScore,
    required this.regime,
    this.vnindex,
    this.ma20,
    this.ma60,
    this.rsi14,
    this.pctAboveMa20,
    this.pctAboveMa50,
    this.erp,
    this.medianPe,
    this.vix,
  });

  factory MarketEvaluationHistoryItem.fromJson(Map<String, dynamic> j) =>
      MarketEvaluationHistoryItem(
        date: j['date']?.toString() ?? '',
        finalScore: _toD(j['final_score']),
        breadthScore: _toD(j['breadth_score']),
        regime: j['regime'] ?? 'sideways',
        vnindex: _toD(j['vnindex']),
        ma20: _toD(j['ma20']),
        ma60: _toD(j['ma60']),
        rsi14: _toD(j['rsi_14']),
        pctAboveMa20: _toD(j['pct_above_ma20']),
        pctAboveMa50: _toD(j['pct_above_ma50']),
        erp: _toD(j['erp']),
        medianPe: _toD(j['median_pe']),
        vix: _toD(j['vix']),
      );
}
