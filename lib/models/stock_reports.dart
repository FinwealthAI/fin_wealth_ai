// lib/models/stock_reports.dart

class PagedResult<T> {
  final List<T> items;
  final int page;
  final int numPages;
  final int total;

  const PagedResult({
    required this.items,
    required this.page,
    required this.numPages,
    required this.total,
  });
}

class StockReport {
  final int id;
  final String ticker;
  final String title;
  final DateTime date;
  final num? targetPrice;
  final String source;
  final String? fileUrl; // file_presigned

  StockReport({
    required this.id,
    required this.ticker,
    required this.title,
    required this.date,
    required this.source,
    this.targetPrice,
    this.fileUrl,
  });

  factory StockReport.fromJson(Map<String, dynamic> map) {
    // map['date'] là "YYYY-MM-DD"
    final dateStr = (map['date'] ?? '') as String;
    return StockReport(
      id: (map['id'] ?? 0) as int,
      ticker: (map['ticker'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      date: dateStr.isNotEmpty ? DateTime.parse(dateStr) : DateTime.fromMillisecondsSinceEpoch(0),
      targetPrice: map['target_price'] == null ? null : (map['target_price'] as num),
      source: (map['source'] ?? '') as String,
      fileUrl: map['file_presigned'] as String?,
    );
  }
}

class StockReportSource {
  final String id;
  final String name;

  StockReportSource({required this.id, required this.name});

  factory StockReportSource.fromJson(Map<String, dynamic> map) {
    // id có thể là int hoặc string -> ép về string
    final rawId = map['id'];
    final idStr = rawId == null ? '' : rawId.toString();
    final name = (map['name'] ?? map['source'] ?? '').toString();
    return StockReportSource(id: idStr, name: name);
  }
}
