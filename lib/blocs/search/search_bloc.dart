import 'package:fin_wealth/respositories/stock_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final StockRepository stockRepository;

  SearchBloc({required this.stockRepository}) : super(SearchInitial()) {
    on<SearchStocks>(_onSearchStocks);
  }

  Future<void> _onSearchStocks(
      SearchStocks event, Emitter<SearchState> emit) async {
    emit(SearchLoading());

    try {
      final stock = await stockRepository.searchStocks(event.query);
      emit(SearchLoaded(stock: stock));
    } catch (error) {
      emit(SearchFailure(error: error.toString()));
    }
  }
}
