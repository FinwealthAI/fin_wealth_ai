import 'package:fin_wealth/respositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  late StreamSubscription<void> _logoutSubscription;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<LoginEvent>(_onLoginEvent);
    on<CheckAuthStatus>(_onCheckAuthStatus);
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
    // Không emit Loading để tránh flicker màn hình Login nếu thất bại
    final userData = await authRepository.tryAutoLogin();
    if (userData != null) {
      emit(AuthSuccess(userData: userData));
    }
    // Nếu null thì giữ nguyên state (AuthInitial) -> LoginScreen sẽ hiển thị
  }

  Future<void> _onLoginEvent(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final userData = await authRepository.authenticate(
        event.username,
        event.password,
      );
      print('AuthBloc - User data received: $userData'); // Debug
      emit(AuthSuccess(userData: userData));
    } catch (error) {
      print('AuthBloc - Error: $error'); // Debug
      emit(AuthFailure(error: error.toString()));
    }
  }
}
