import 'package:equatable/equatable.dart';

class MarketReport extends Equatable {
  final String content;
  final String source;
  final String date;

  final String? marketTrend;

  const MarketReport({
    required this.content,
    required this.source,
    required this.date,
    this.marketTrend,
  });

  factory MarketReport.fromJson(Map<String, dynamic> json) {
    return MarketReport(
      content: json['content'] ?? json['summaryContent'] ?? '',
      source: json['source'] ?? 'AI',
      date: json['date'] ?? '',
      marketTrend: json['trend'] ?? json['marketTrend'],
    );
  }

  @override
  List<Object> get props => [content, source, date];
}
