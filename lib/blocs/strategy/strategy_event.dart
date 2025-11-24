import 'package:equatable/equatable.dart';

abstract class StrategyEvent extends Equatable {
  const StrategyEvent();

  @override
  List<Object> get props => [];
}

class FetchStockStrategies extends StrategyEvent {}
