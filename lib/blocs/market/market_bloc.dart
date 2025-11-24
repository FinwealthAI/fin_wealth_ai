import 'package:fin_wealth/respositories/market_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'market_event.dart';
import 'market_state.dart';

class MarketBloc extends Bloc<MarketEvent, MarketState> {
  final MarketRepository marketRepository;

  MarketBloc({required this.marketRepository}) : super(MarketInitial()) {
    on<FetchMarketReports>(_onFetchMarketReports);
  }

  Future<void> _onFetchMarketReports(
      FetchMarketReports event, Emitter<MarketState> emit) async {
    emit(MarketLoading());

    try {
      final reports = await marketRepository.fetchMarketReports();
      emit(MarketLoaded(reports: reports));
    } catch (error) {
      emit(MarketFailure(error: error.toString()));
    }
  }
}
