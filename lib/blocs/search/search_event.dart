import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

class SearchStocks extends SearchEvent {
  final String query;

  const SearchStocks({required this.query});

  @override
  List<Object> get props => [query];
}
