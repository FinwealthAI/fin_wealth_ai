import 'package:equatable/equatable.dart';

class MarketReport extends Equatable {
  final String content;
  final String source;
  final String date;

  const MarketReport({required this.content, required this.source, required this.date});

  factory MarketReport.fromJson(Map<String, dynamic> json) {
    return MarketReport(
      content: json['content'],
      source: json['source'],
      date: json['date'],
    );
  }

  @override
  List<Object> get props => [content, source, date];
}
