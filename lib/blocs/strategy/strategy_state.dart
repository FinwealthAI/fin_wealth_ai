import 'package:equatable/equatable.dart';
import 'package:fin_wealth/models/stock_strategy.dart';

abstract class StrategyState extends Equatable {
  const StrategyState();

  @override
  List<Object> get props => [];
}

class StrategyInitial extends StrategyState {}

class StrategyLoading extends StrategyState {}

class StrategyLoaded extends StrategyState {
  final List<StockStrategy> stockStrategies;

  const StrategyLoaded({required this.stockStrategies});

  @override
  List<Object> get props => [stockStrategies];
}

class StrategyFailure extends StrategyState {
  final String error;

  const StrategyFailure({required this.error});

  @override
  List<Object> get props => [error];
}
