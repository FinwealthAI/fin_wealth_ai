class Stock {
  final String id;
  final String reports;
  final bool isSummary;
  final double marketPrice;
  final double averageTargetPrice;
  final bool isBreakout;

  Stock({
    required this.id,
    required this.reports,
    required this.isSummary,
    required this.marketPrice,
    required this.averageTargetPrice,
    required this.isBreakout,
  });

  // Factory constructor to create a Report from a JSON map
  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['id'],
      reports: json['reports'],
      isSummary: json['is_summary'],
      marketPrice: json['market_price'].toDouble(),
      averageTargetPrice: json['average_target_price'].toDouble(),
      isBreakout: json['is_brreakout'],
    );
  }

  // Method to convert Report to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reports': reports,
      'is_summary': isSummary,
      'market_price': marketPrice,
      'average_target_price': averageTargetPrice,
      'is_brreakout': isBreakout,
    };
  }
}

class StockValuation {
  final String ticker;
  final String lastReportDate;
  final int recommendCount;
  final double averageTargetPrice;
  final double valuationDifference;
  final double investPrice;
  final double investPriceDifference;

  StockValuation({
    required this.ticker,
    required this.lastReportDate,
    required this.recommendCount,
    required this.averageTargetPrice,
    required this.valuationDifference,
    required this.investPrice,
    required this.investPriceDifference,
  });

  factory StockValuation.fromJson(Map<String, dynamic> json) {
    return StockValuation(
      ticker: json['ticker'],
      lastReportDate: json['last_report_date'],
      recommendCount: json['recommend_count'],
      averageTargetPrice: json['average_target_price'].toDouble(),
      valuationDifference: json['valuation_difference'].toDouble(),
      investPrice: json['invest_price'].toDouble(),
      investPriceDifference: json['invest_price_difference'].toDouble(),
    );
  }
}

class StockGrowthData {
  final List<String> labels; // e.g. ["2023-Q1", "2023-Q2"]
  final List<double> revenueGrowth;
  final List<double> profitGrowth;

  StockGrowthData({
    required this.labels,
    required this.revenueGrowth,
    required this.profitGrowth,
  });

  factory StockGrowthData.fromJson(Map<String, dynamic> json) {
    return StockGrowthData(
      labels: (json['labels'] as List?)?.map((e) => e.toString()).toList() ?? [],
      revenueGrowth: (json['revenue_growth'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      profitGrowth: (json['profit_growth'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
    );
  }
}

class StockSafetyData {
  final List<String> labels;
  final List<double> debtToEquity;
  final List<double> cfoToRevenue;

  StockSafetyData({
    required this.labels,
    required this.debtToEquity,
    required this.cfoToRevenue,
  });

  factory StockSafetyData.fromJson(Map<String, dynamic> json) {
    return StockSafetyData(
      labels: (json['labels'] as List?)?.map((e) => e.toString()).toList() ?? [],
      debtToEquity: (json['debt_to_equity'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      cfoToRevenue: (json['cfo_to_revenue'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
    );
  }
}

class ExpertViewLevel {
  final double? nearestSupport;
  final double? nearestResistance;

  ExpertViewLevel({this.nearestSupport, this.nearestResistance});

  factory ExpertViewLevel.fromJson(Map<String, dynamic> json) {
    return ExpertViewLevel(
      nearestSupport: (json['nearest_support'] as num?)?.toDouble(),
      nearestResistance: (json['nearest_resistance'] as num?)?.toDouble(),
    );
  }
}

class ExpertView {
  final String? trendDirection; // UPTREND, DOWNTREND, SIDEWAY
  final ExpertViewLevel? levels;
  final String? momentumDivergence; // BEARISH, BULLISH

  ExpertView({this.trendDirection, this.levels, this.momentumDivergence});

  factory ExpertView.fromJson(Map<String, dynamic> json) {
    return ExpertView(
      trendDirection: json['trend']?['direction'] as String?,
      levels: json['levels'] != null ? ExpertViewLevel.fromJson(json['levels']) : null,
      momentumDivergence: json['momentum']?['divergence'] as String?,
    );
  }
}

class StockTechnicalData {
  final ExpertView? expertView;

  StockTechnicalData({this.expertView});

  factory StockTechnicalData.fromJson(Map<String, dynamic> json) {
    return StockTechnicalData(
      expertView: json['data']?['expert_view'] != null
          ? ExpertView.fromJson(json['data']['expert_view'])
          : null,
    );
  }
}

class StockOverviewData {
  final double? upSize; // e.g. 15.5 (%)
  final double? price; // Current price
  final double? avgTargetPrice;
  final double? expectedPrice;

  StockOverviewData({
    this.upSize,
    this.price,
    this.avgTargetPrice,
    this.expectedPrice,
  });

  factory StockOverviewData.fromJson(Map<String, dynamic> json) {
    // Helper to parse potential string numbers with commas
    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val.replaceAll(',', ''));
      return null;
    }

    return StockOverviewData(
      upSize: parseDouble(json['up_size']),
      price: parseDouble(json['price']),
      avgTargetPrice: parseDouble(json['avg_target_price']),
      expectedPrice: parseDouble(json['expected_price']),
    );
  }
}

class CTCKDetail {
  final String source; // firm_new or source
  final String targetPrice; // Display string e.g. "30,000"
  final String reportDate;
  final String recommendation; // BUY, SELL, HOLD

  CTCKDetail({
    required this.source,
    required this.targetPrice,
    required this.reportDate,
    required this.recommendation,
  });

  factory CTCKDetail.fromJson(Map<String, dynamic> json) {
    return CTCKDetail(
      source: (json['firm_new'] ?? json['source'] ?? '').toString(),
      targetPrice: (json['target_price'] ?? '').toString(),
      reportDate: (json['report_date'] ?? '').toString(),
      recommendation: (json['recommendation'] ?? '').toString(),
    );
  }
}

class CTCKValuation {
  final List<CTCKDetail> details;

  CTCKValuation({required this.details});

  factory CTCKValuation.fromJson(Map<String, dynamic> json) {
    return CTCKValuation(
      details: (json['details'] as List?)
              ?.map((e) => CTCKDetail.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class StockPriceHistory {
  final List<String> labels;
  final List<double> close;
  final List<double> volume;

  StockPriceHistory({
    required this.labels,
    required this.close,
    required this.volume,
  });

  factory StockPriceHistory.fromJson(Map<String, dynamic> json) {
    return StockPriceHistory(
      labels: (json['labels'] as List?)?.map((e) => e.toString()).toList() ?? [],
      close: (json['close'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      volume: (json['volume'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
    );
  }
}

class StockRatioData {
  final List<String> labels;
  final List<double> peData;
  final List<double> pbData;
  final double? avgPe1y;
  final double? avgPb1y;
  final StockPriceHistory? priceHistory;

  StockRatioData({
    required this.labels,
    required this.peData,
    required this.pbData,
    this.avgPe1y,
    this.avgPb1y,
    this.priceHistory,
  });

  factory StockRatioData.fromJson(Map<String, dynamic> json) {
    return StockRatioData(
      labels: (json['labels'] as List?)?.map((e) => e.toString()).toList() ?? [],
      peData: (json['pe_data'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      pbData: (json['pb_data'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      avgPe1y: (json['avg_pe_1y'] as num?)?.toDouble(),
      avgPb1y: (json['avg_pb_1y'] as num?)?.toDouble(),
      priceHistory: json['price_history'] != null
          ? StockPriceHistory.fromJson(json['price_history'])
          : null,
    );
  }
}
