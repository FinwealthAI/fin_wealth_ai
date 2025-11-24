class WatchlistItem {
  final int id;
  final String ticker;
  final double? currentPrice;
  final double? change;
  final double? changePercent;

  WatchlistItem({
    required this.id,
    required this.ticker,
    this.currentPrice,
    this.change,
    this.changePercent,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'],
      ticker: json['ticker'],
      currentPrice: json['current_price'] != null ? (json['current_price'] as num).toDouble() : null,
      change: json['change'] != null ? (json['change'] as num).toDouble() : null,
      changePercent: json['change_percent'] != null ? (json['change_percent'] as num).toDouble() : null,
    );
  }
}
