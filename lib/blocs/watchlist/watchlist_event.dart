import 'package:equatable/equatable.dart';

abstract class WatchlistEvent extends Equatable {
  const WatchlistEvent();

  @override
  List<Object> get props => [];
}

class LoadWatchlist extends WatchlistEvent {}

class AddToWatchlist extends WatchlistEvent {
  final String ticker;

  const AddToWatchlist(this.ticker);

  @override
  List<Object> get props => [ticker];
}

class RemoveFromWatchlist extends WatchlistEvent {
  final int id;

  const RemoveFromWatchlist(this.id);

  @override
  List<Object> get props => [id];
}
