import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fin_wealth/respositories/watchlist_repository.dart';
import 'watchlist_event.dart';
import 'watchlist_state.dart';

class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  final WatchlistRepository repository;

  WatchlistBloc({required this.repository}) : super(WatchlistInitial()) {
    on<LoadWatchlist>(_onLoadWatchlist);
    on<AddToWatchlist>(_onAddToWatchlist);
    on<RemoveFromWatchlist>(_onRemoveFromWatchlist);
  }

  Future<void> _onLoadWatchlist(LoadWatchlist event, Emitter<WatchlistState> emit) async {
    emit(WatchlistLoading());
    try {
      final items = await repository.getWatchlist();
      emit(WatchlistLoaded(items));
    } catch (e) {
      emit(WatchlistError(e.toString()));
    }
  }

  Future<void> _onAddToWatchlist(AddToWatchlist event, Emitter<WatchlistState> emit) async {
    try {
      await repository.addToWatchlist(event.ticker);
      add(LoadWatchlist());
    } catch (e) {
      emit(WatchlistError(e.toString()));
      // Retry load to restore list if possible, or let UI handle retry
      add(LoadWatchlist());
    }
  }

  Future<void> _onRemoveFromWatchlist(RemoveFromWatchlist event, Emitter<WatchlistState> emit) async {
    try {
      await repository.removeFromWatchlist(event.id);
      add(LoadWatchlist());
    } catch (e) {
      emit(WatchlistError(e.toString()));
      add(LoadWatchlist());
    }
  }
}
