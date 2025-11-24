import 'package:fin_wealth/models/stock_reports.dart';

enum StockReportsStatus { initial, loading, success, failure, loadingMore, refreshing }

class StockReportsState {
  final StockReportsStatus status;
  final List<StockReport> items;
  final int page;
  final int numPages;
  final int total;
  final String? stock;
  final String? sourceId;
  final String? error;
  final List<StockReportSource> sources;

  const StockReportsState({
    this.status = StockReportsStatus.initial,
    this.items = const [],
    this.page = 0,
    this.numPages = 0,
    this.total = 0,
    this.stock,
    this.sourceId,
    this.error,
    this.sources = const <StockReportSource>[],
  });

  bool get hasMore => page < numPages;

  StockReportsState copyWith({
    StockReportsStatus? status,
    List<StockReport>? items,
    int? page,
    int? numPages,
    int? total,
    String? stock,
    String? sourceId,
    String? error,
    List<StockReportSource>? sources,
  }) {
    return StockReportsState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      numPages: numPages ?? this.numPages,
      total: total ?? this.total,
      stock: stock ?? this.stock,
      sourceId: sourceId ?? this.sourceId,
      error: error,
      sources: sources ?? this.sources,
    );
  }
}
