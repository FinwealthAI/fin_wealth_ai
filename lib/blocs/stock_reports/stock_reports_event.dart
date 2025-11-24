abstract class StockReportsEvent {}

class StockReportsLoadSources extends StockReportsEvent {}

class StockReportsInitialLoad extends StockReportsEvent {
  final String? stock;     // mã CP
  final String? sourceId;  // id nguồn (hoặc 'all')
  StockReportsInitialLoad({this.stock, this.sourceId});
}

class StockReportsLoadMore extends StockReportsEvent {}

class StockReportsRefresh extends StockReportsEvent {}
