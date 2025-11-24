import 'package:fin_wealth/blocs/strategy/strategy_event.dart';
import 'package:fin_wealth/blocs/strategy/strategy_state.dart';
import 'package:fin_wealth/respositories/strategy_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StrategyBloc extends Bloc<StrategyEvent, StrategyState> {
  final StrategyRepository strategyRepository;

  StrategyBloc({required this.strategyRepository}) : super(StrategyInitial()) {
    on<FetchStockStrategies>(_onFetchStockStrategies);
  }

  Future<void> _onFetchStockStrategies(
      FetchStockStrategies event, Emitter<StrategyState> emit) async {
    emit(StrategyLoading());

    try {
      final stockStrategies = await strategyRepository.fetchStockStrategies();
      emit(StrategyLoaded(stockStrategies: stockStrategies));
    } catch (error) {
      emit(StrategyFailure(error: error.toString()));
    }
  }
}
