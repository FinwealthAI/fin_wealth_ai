// lib/models/investment_opportunities.dart

class BubblePoint {
  final double x;       // report_counts (hoặc đã chuẩn hoá)
  final double y;       // difference (%)
  final String label;   // ticker
  final int r;          // radius đã tính sẵn trên server

  BubblePoint({
    required this.x,
    required this.y,
    required this.label,
    required this.r,
  });

  factory BubblePoint.fromJson(Map<String, dynamic> j) => BubblePoint(
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        label: j['label'] as String,
        r: (j['r'] as num).toInt(),
      );
}

class GapData {
  final List<String> tickers;
  final List<double> current;
  final List<double> safe;

  GapData({
    required this.tickers,
    required this.current,
    required this.safe,
  });

  factory GapData.fromJson(Map<String, dynamic> j) => GapData(
        tickers: (j['tickers'] as List).cast<String>(),
        current: (j['current'] as List).map((e) => (e as num).toDouble()).toList(),
        safe:    (j['safe'] as List).map((e) => (e as num).toDouble()).toList(),
      );
}

class Rankings {
  final List<String> cashTickers;
  final List<String> profitTickers;
  final List<String> divTickers;
  final List<String> pbLabels;
  final List<String> peLabels;
  final List<String> roeTickers;

  Rankings({
    required this.cashTickers,
    required this.profitTickers,
    required this.divTickers,
    required this.pbLabels,
    required this.peLabels,
    required this.roeTickers,
  });

  factory Rankings.fromJson(Map<String, dynamic> j) => Rankings(
        cashTickers: (j['cash']['tickers'] as List<dynamic>).cast<String>(),
        profitTickers: (j['profit']['tickers'] as List<dynamic>).cast<String>(),
        divTickers: (j['div']['tickers'] as List<dynamic>).cast<String>(),
        pbLabels: (j['pb']['labels'] as List<dynamic>).cast<String>(),
        peLabels: (j['pe']['labels'] as List<dynamic>).cast<String>(),
        roeTickers: (j['roe']['tickers'] as List<dynamic>).cast<String>(),
      );
}

class InvestmentOpportunities {
  final List<BubblePoint> bubble;
  final GapData gap;
  final Rankings rankings;
  final int rMin;
  final int rMax;

  InvestmentOpportunities({
    required this.bubble,
    required this.gap,
    required this.rankings,
    required this.rMin,
    required this.rMax,
  });

  factory InvestmentOpportunities.fromJson(Map<String, dynamic> j) {
    final bubbleJson = j['bubble'] as Map<String, dynamic>;

    return InvestmentOpportunities(
      bubble: (bubbleJson['points'] as List<dynamic>)
          .map((e) => BubblePoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      gap: GapData.fromJson(j['gap'] as Map<String, dynamic>),
      rankings: Rankings.fromJson(j['rankings'] as Map<String, dynamic>),
      rMin: (bubbleJson['r_min'] as num).toInt(),
      rMax: (bubbleJson['r_max'] as num).toInt(),
    );
  }
}

/// Model for report highlights displayed on dashboard
class ReportHighlight {
  final int? id;
  final String title;
  final String source;
  final String date;
  final List<String> tags;
  final String? summary;
  final String? filePresigned;
  final double? valuation;

  ReportHighlight({
    this.id,
    required this.title,
    required this.source,
    required this.date,
    required this.tags,
    this.summary,
    this.filePresigned,
    this.valuation,
  });

  factory ReportHighlight.fromJson(Map<String, dynamic> j) => ReportHighlight(
        id: j['id'] as int?,
        title: j['title'] as String? ?? '',
        source: j['source'] as String? ?? '',
        date: j['date'] as String? ?? '',
        tags: (j['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        summary: j['summary'] as String?,
        filePresigned: j['file_presigned'] as String?,
        valuation: (j['valuation'] as num?)?.toDouble(),
      );
}

/// Model for investment opportunity cards (from bubble data)
class BubbleOpportunity {
  final String label;
  final int nFirms;
  final double gapPct;

  BubbleOpportunity({
    required this.label,
    required this.nFirms,
    required this.gapPct,
  });

  factory BubbleOpportunity.fromJson(Map<String, dynamic> j) => BubbleOpportunity(
        label: j['label'] as String? ?? '',
        nFirms: (j['n_firms'] as num?)?.toInt() ?? 0,
        gapPct: (j['gap_pct'] as num?)?.toDouble() ?? 0.0,
      );
}
