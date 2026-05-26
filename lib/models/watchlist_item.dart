class WatchlistItem {
  final int id;
  final String ticker;
  final String? companyName;
  final double? currentPrice;
  final double? change;
  final double? changePercent;
  final String? faTier;
  final String? taTier;
  final String? faLabel;
  final String? taLabel;
  final String? strengthLabel;

  WatchlistItem({
    required this.id,
    required this.ticker,
    this.companyName,
    this.currentPrice,
    this.change,
    this.changePercent,
    this.faTier,
    this.taTier,
    this.faLabel,
    this.taLabel,
    this.strengthLabel,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'],
      ticker: json['ticker'],
      companyName: json['company_name'],
      currentPrice: json['current_price'] != null ? (json['current_price'] as num).toDouble() : null,
      change: json['change'] != null ? (json['change'] as num).toDouble() : null,
      changePercent: json['change_percent'] != null ? (json['change_percent'] as num).toDouble() : null,
      faTier: json['fa_tier'] as String?,
      taTier: json['ta_tier'] as String?,
      faLabel: json['fa_label'] as String?,
      taLabel: json['ta_label'] as String?,
      strengthLabel: json['strength_label'] as String?,
    );
  }
}
