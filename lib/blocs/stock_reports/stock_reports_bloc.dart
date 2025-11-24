import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fin_wealth/blocs/stock_reports/stock_reports_event.dart';
import 'package:fin_wealth/blocs/stock_reports/stock_reports_state.dart';
import 'package:fin_wealth/respositories/stock_reports_repository.dart';

class StockReportsBloc extends Bloc<StockReportsEvent, StockReportsState> {
  final StockReportsRepository repo;

  StockReportsBloc(this.repo) : super(const StockReportsState()) {
    on<StockReportsLoadSources>(_onLoadSources);
    on<StockReportsInitialLoad>(_onInitial);
    on<StockReportsLoadMore>(_onMore);
    on<StockReportsRefresh>(_onRefresh);
  }

  Future<void> _onLoadSources(StockReportsLoadSources e, Emitter<StockReportsState> emit) async {
    try {
      final list = await repo.fetchSources();
      emit(state.copyWith(sources: list));
    } catch (_) {
      // bỏ qua lỗi nguồn
    }
  }

  Future<void> _onInitial(StockReportsInitialLoad e, Emitter<StockReportsState> emit) async {
    emit(state.copyWith(status: StockReportsStatus.loading, stock: e.stock, sourceId: e.sourceId, error: null));
    try {
      final res = await repo.fetchReports(page: 1, stock: e.stock, sourceId: e.sourceId);
      emit(state.copyWith(
        status: StockReportsStatus.success,
        items: res.items,
        page: res.page,
        numPages: res.numPages,
        total: res.total,
      ));
    } catch (err) {
      emit(state.copyWith(status: StockReportsStatus.failure, error: err.toString()));
    }
  }

  Future<void> _onMore(StockReportsLoadMore e, Emitter<StockReportsState> emit) async {
    if (!state.hasMore || state.status == StockReportsStatus.loadingMore) return;
    emit(state.copyWith(status: StockReportsStatus.loadingMore));
    try {
      final res = await repo.fetchReports(page: state.page + 1, stock: state.stock, sourceId: state.sourceId);
      emit(state.copyWith(
        status: StockReportsStatus.success,
        items: [...state.items, ...res.items],
        page: res.page,
        numPages: res.numPages,
        total: res.total,
      ));
    } catch (err) {
      emit(state.copyWith(status: StockReportsStatus.failure, error: err.toString()));
    }
  }

  Future<void> _onRefresh(StockReportsRefresh e, Emitter<StockReportsState> emit) async {
    emit(state.copyWith(status: StockReportsStatus.refreshing));
    try {
      final res = await repo.fetchReports(page: 1, stock: state.stock, sourceId: state.sourceId);
      emit(state.copyWith(
        status: StockReportsStatus.success,
        items: res.items,
        page: res.page,
        numPages: res.numPages,
        total: res.total,
      ));
    } catch (err) {
      emit(state.copyWith(status: StockReportsStatus.failure, error: err.toString()));
    }
  }
}
