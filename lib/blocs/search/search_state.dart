import 'package:equatable/equatable.dart';
import 'package:fin_wealth/models/stock_models.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final Stock stock;

  const SearchLoaded({required this.stock});

  @override
  List<Object> get props => [stock];
}

class SearchFailure extends SearchState {
  final String error;

  const SearchFailure({required this.error});

  @override
  List<Object> get props => [error];
}
