import 'package:equatable/equatable.dart';
import 'package:fin_wealth/models/market_report.dart';

abstract class MarketState extends Equatable {
  const MarketState();

  @override
  List<Object> get props => [];
}

class MarketInitial extends MarketState {}

class MarketLoading extends MarketState {}

class MarketLoaded extends MarketState {
  final List<MarketReport> reports;

  const MarketLoaded({required this.reports});

  @override
  List<Object> get props => [reports];
}

class MarketFailure extends MarketState {
  final String error;

  const MarketFailure({required this.error});

  @override
  List<Object> get props => [error];
}
