import 'package:fin_wealth/respositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'auth_event.dart';
import 'auth_state.dart';

export 'package:fin_wealth/respositories/auth_repository.dart' show AccountExpiredException;

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  late StreamSubscription<void> _logoutSubscription;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<LoginEvent>(_onLoginEvent);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<CheckAccountExpiry>(_onCheckAccountExpiry);
    on<AuthUserUpdated>((event, emit) {
      if (state is AuthSuccess) {
        emit(AuthSuccess(userData: event.userData));
      }
    });
    on<LogoutRequested>((event, emit) => emit(AuthInitial()));
    
    _logoutSubscription = authRepository.onLogout.listen((_) {
      add(LogoutRequested());
    });
  }

  @override
  Future<void> close() {
    _logoutSubscription.cancel();
    return super.close();
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatus event, Emitter<AuthState> emit) async {
    try {
      final userData = await authRepository.tryAutoLogin();
      if (userData != null) {
        emit(AuthSuccess(userData: userData));
      } else {
        emit(const AuthFailure(error: "Not logged in"));
      }
    } on AccountExpiredException catch (e) {
      emit(AuthAccountExpired(
        username: e.username,
        upgradeUrl: e.upgradeUrl,
        zaloGroup: e.zaloGroup,
        zaloSupport: e.zaloSupport,
      ));
    }
  }

  Future<void> _onCheckAccountExpiry(CheckAccountExpiry event, Emitter<AuthState> emit) async {
    if (state is! AuthSuccess) return; // Chỉ check khi đang logged in
    try {
      await authRepository.checkAccountExpiry();
    } on AccountExpiredException catch (e) {
      emit(AuthAccountExpired(
        username: e.username,
        upgradeUrl: e.upgradeUrl,
        zaloGroup: e.zaloGroup,
        zaloSupport: e.zaloSupport,
      ));
    } catch (_) {
      // Network error → im lặng
    }
  }

  Future<void> _onLoginEvent(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final userData = await authRepository.authenticate(
        event.username,
        event.password,
      );
      emit(AuthSuccess(userData: userData));
    } on AccountExpiredException catch (e) {
      emit(AuthAccountExpired(
        username: e.username,
        upgradeUrl: e.upgradeUrl,
        zaloGroup: e.zaloGroup,
        zaloSupport: e.zaloSupport,
      ));
    } catch (error) {
      emit(AuthFailure(error: error.toString()));
    }
  }
}
