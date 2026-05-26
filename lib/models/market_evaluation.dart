double? _toD(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '').trim());
  return null;
}

class AiSentimentShort {
  final String label;
  final String color;
  final String reason;

  AiSentimentShort({required this.label, required this.color, required this.reason});

  factory AiSentimentShort.fromJson(Map<String, dynamic> j) => AiSentimentShort(
        label: j['label'] ?? 'Trung tính',
        color: j['color'] ?? 'neutral',
        reason: j['reason'] ?? '',
      );
}

class AiSentiment {
  final double score;
  final AiSentimentShort shortTerm;
  final AiSentimentShort longTerm;
  final String summary;
  final String analysis;

  AiSentiment({
    required this.score,
    required this.shortTerm,
    required this.longTerm,
    required this.summary,
    required this.analysis,
  });

  factory AiSentiment.fromJson(Map<String, dynamic>? j) {
    if (j == null) {
      return AiSentiment(
        score: 50,
        shortTerm: AiSentimentShort(label: 'Trung tính', color: 'neutral', reason: ''),
        longTerm: AiSentimentShort(label: 'Trung tính', color: 'neutral', reason: ''),
        summary: '',
        analysis: '',
      );
    }
    return AiSentiment(
      score: _toD(j['score']) ?? 50,
      shortTerm: AiSentimentShort.fromJson((j['short_term'] as Map<String, dynamic>?) ?? {}),
      longTerm: AiSentimentShort.fromJson((j['long_term'] as Map<String, dynamic>?) ?? {}),
      summary: j['summary'] ?? '',
      analysis: j['analysis'] ?? '',
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

  // Scores
  final double techScore;
  final double breadthScore;
  final double valScore;
  final double quantScore;
  final double aiScore;
  final double shortTermScore;
  final double longTermScore;
  final double alWeight;

  // VNINDEX kỹ thuật
  final double? vnindex;
  final double? ma20;
  final double? ma60;
  final double? pctVsMa20;
  final double? pctChange20d;
  final double? volatility20dPct;
  final double? rsi14;
  final String techRegime;
  final String? divergenceSignal;
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

  // AI Sentiment
  final AiSentiment aiSentiment;

  MarketEvaluation({
    required this.regime,
    required this.label,
    required this.cautionLevel,
    required this.finalScore,
    required this.snapshotUpdatedAt,
    required this.techScore,
    required this.breadthScore,
    required this.valScore,
    required this.quantScore,
    required this.aiScore,
    required this.shortTermScore,
    required this.longTermScore,
    required this.alWeight,
    this.vnindex,
    this.ma20,
    this.ma60,
    this.pctVsMa20,
    this.pctChange20d,
    this.volatility20dPct,
    this.rsi14,
    required this.techRegime,
    this.divergenceSignal,
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
    required this.aiSentiment,
  });

  factory MarketEvaluation.fromJson(Map<String, dynamic> j) => MarketEvaluation(
        regime: j['regime'] ?? 'sideways',
        label: j['label'] ?? '',
        cautionLevel: j['caution_level'] ?? 'medium',
        finalScore: _toD(j['final_score']) ?? 50,
        snapshotUpdatedAt: j['snapshot_updated_at'] ?? '',
        techScore: _toD(j['tech_score']) ?? 50,
        breadthScore: _toD(j['breadth_score']) ?? 50,
        valScore: _toD(j['val_score']) ?? 50,
        quantScore: _toD(j['quant_score']) ?? 50,
        aiScore: _toD(j['ai_score']) ?? 50,
        shortTermScore: _toD(j['short_term_score']) ?? 50,
        longTermScore: _toD(j['long_term_score']) ?? 50,
        alWeight: _toD(j['al_weight']) ?? 0.3,
        vnindex: _toD(j['vnindex']),
        ma20: _toD(j['ma20']),
        ma60: _toD(j['ma60']),
        pctVsMa20: _toD(j['pct_vs_ma20']),
        pctChange20d: _toD(j['pct_change_20d']),
        volatility20dPct: _toD(j['volatility_20d_pct']),
        rsi14: _toD(j['rsi_14']),
        techRegime: j['tech_regime'] ?? '',
        divergenceSignal: j['divergence_signal'],
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
        aiSentiment: AiSentiment.fromJson(j['ai_sentiment'] as Map<String, dynamic>?),
      );
}

class MarketEvaluationHistoryItem {
  final String date;
  final double? finalScore;
  final double? quantScore;
  final double? aiScore;
  final double? techScore;
  final double? breadthScore;
  final double? valScore;
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
    this.quantScore,
    this.aiScore,
    this.techScore,
    this.breadthScore,
    this.valScore,
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
        quantScore: _toD(j['quant_score']),
        aiScore: _toD(j['ai_score']),
        techScore: _toD(j['tech_score']),
        breadthScore: _toD(j['breadth_score']),
        valScore: _toD(j['val_score']),
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
