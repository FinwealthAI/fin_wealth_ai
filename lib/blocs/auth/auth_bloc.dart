import 'package:fin_wealth/respositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fin_wealth/config/api_config.dart';
import 'dart:async';
import 'auth_event.dart';
import 'auth_state.dart';

export 'package:fin_wealth/respositories/auth_repository.dart' show AccountExpiredException;

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  late StreamSubscription<void> _logoutSubscription;
  late final GoogleSignIn _googleSignIn;
  StreamSubscription<GoogleSignInAccount?>? _googleSignInSubscription;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? ApiConfig.googleServerClientId : null,
      serverClientId: kIsWeb ? null : ApiConfig.googleServerClientId,
    );

    if (kIsWeb) {
      _googleSignInSubscription = _googleSignIn.onCurrentUserChanged.listen((account) {
        if (account != null) {
          add(GoogleWebLoginSuccessEvent(account));
        }
      });
    }

    on<LoginEvent>(_onLoginEvent);
    on<GoogleLoginEvent>(_onGoogleLoginEvent);
    on<GoogleWebLoginSuccessEvent>(_onGoogleWebLoginSuccess);
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
    _googleSignInSubscription?.cancel();
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

  Future<void> _onGoogleLoginEvent(GoogleLoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _googleSignIn.signOut(); // Clear cached account to force account picker
      final account = await _googleSignIn.signIn();
      if (account == null) {
        emit(AuthInitial()); // User cancelled → silent, no error
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        emit(const AuthFailure(error: 'Không lấy được token từ Google. Kiểm tra cấu hình OAuth.'));
        return;
      }
      final userData = await authRepository.googleSignIn(idToken, authEntry: event.authEntry);
      emit(AuthSuccess(userData: userData));
    } on AccountExpiredException catch (e) {
      emit(AuthAccountExpired(
        username: e.username,
        upgradeUrl: e.upgradeUrl,
        zaloGroup: e.zaloGroup,
        zaloSupport: e.zaloSupport,
      ));
    } catch (error) {
      String msg = error.toString().replaceFirst('Exception: ', '');
      if (msg.contains('network_error') || msg.contains('SocketException')) {
        msg = 'Không thể kết nối máy chủ. Kiểm tra kết nối mạng.';
      }
      emit(AuthFailure(error: msg));
    }
  }

  Future<void> _onGoogleWebLoginSuccess(GoogleWebLoginSuccessEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final auth = await event.account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        emit(const AuthFailure(error: 'Không lấy được token từ Google (Web). Hãy thử lại.'));
        return;
      }
      final userData = await authRepository.googleSignIn(idToken, authEntry: 'login');
      emit(AuthSuccess(userData: userData));
    } on AccountExpiredException catch (e) {
      emit(AuthAccountExpired(
        username: e.username,
        upgradeUrl: e.upgradeUrl,
        zaloGroup: e.zaloGroup,
        zaloSupport: e.zaloSupport,
      ));
    } catch (error) {
      String msg = error.toString().replaceFirst('Exception: ', '');
      if (msg.contains('network_error') || msg.contains('SocketException')) {
        msg = 'Không thể kết nối máy chủ. Kiểm tra kết nối mạng.';
      }
      emit(AuthFailure(error: msg));
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
