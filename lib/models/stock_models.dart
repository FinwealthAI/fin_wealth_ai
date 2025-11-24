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
