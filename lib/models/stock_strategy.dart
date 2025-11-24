import 'package:equatable/equatable.dart';

class StockStrategy extends Equatable {
  final String strategy;
  final List<Stock> stockList;

  const StockStrategy({required this.strategy, required this.stockList});

  factory StockStrategy.fromJson(Map<String, dynamic> json) {
    var list = json['stock_list'] as List;
    List<Stock> stockList = list.map((i) => Stock.fromJson(i)).toList();

    return StockStrategy(
      strategy: json['strategy'],
      stockList: stockList,
    );
  }

  @override
  List<Object?> get props => [strategy, stockList];
}

class Stock extends Equatable {
  final String ticker;
  final String? date;
  final double? accumulation;
  final double? wavefoot;
  final double? close;
  final double? marketPrice;

  const Stock({
    required this.ticker,
    this.date,
    this.accumulation,
    this.wavefoot,
    this.close,
    this.marketPrice,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      ticker: json['ticker'] ?? json['symbol'],
      date: json['date'],
      accumulation: json['predicted_price']?.toDouble(),
      wavefoot: json['wavefoot']?.toDouble(),
      close: json['close']?.toDouble(),
      marketPrice: json['market_price']?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        ticker,
        date,
        accumulation,
        wavefoot,
        close,
        marketPrice,
      ];
}
