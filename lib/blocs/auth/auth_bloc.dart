import 'package:fin_wealth/respositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fin_wealth/config/api_config.dart';
import 'dart:async';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  late StreamSubscription<void> _logoutSubscription;
  late final GoogleSignIn _googleSignIn;
  StreamSubscription<GoogleSignInAccount?>? _googleSignInSubscription;

  /// Luồng web: nút Google của plugin tự phát tài khoản qua stream nên không mang
  /// theo ngữ cảnh. Màn hình đang hiển thị nút set 2 field này ('login' | 'signup'
  /// + mã giới thiệu) và trả về mặc định khi rời màn.
  String webAuthEntry = 'login';
  String? webReferralCode;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? ApiConfig.googleServerClientId : null,
      serverClientId: kIsWeb ? null : ApiConfig.googleServerClientId,
    );

    if (kIsWeb) {
      _googleSignInSubscription =
          _googleSignIn.onCurrentUserChanged.listen((account) {
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

  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event, Emitter<AuthState> emit) async {
    final userData = await authRepository.tryAutoLogin();
    if (userData != null) {
      emit(AuthSuccess(userData: userData));
    } else {
      emit(const AuthFailure(error: "Not logged in"));
    }
  }

  /// ⚠️ TRƯỚC 18/08/2026 sự kiện này ĐÁ USER RA khi hết điểm (mỗi lần app resume).
  /// Nay chỉ làm mới số điểm để màn hình hiện đúng "N ngày sử dụng".
  Future<void> _onCheckAccountExpiry(
      CheckAccountExpiry event, Emitter<AuthState> emit) async {
    if (state is! AuthSuccess) return; // Chỉ chạy khi đang logged in
    await authRepository.refreshAccountStatus();
  }

  /// Đổi lỗi thô của plugin/mạng thành thông điệp tiếng Việt; lỗi nghiệp vụ từ
  /// backend (Exception có sẵn nội dung) giữ nguyên.
  static String _googleErrorMessage(Object error) {
    final raw = error.toString();
    if (raw.contains('network_error') ||
        raw.contains('SocketException') ||
        raw.contains('DioException')) {
      return 'Không thể kết nối máy chủ. Kiểm tra kết nối mạng.';
    }
    if (raw.contains('ApiException: 10') || raw.contains('sign_in_failed')) {
      return 'Đăng nhập Google chưa được cấu hình đúng cho ứng dụng này. Vui lòng thử lại sau hoặc dùng email.';
    }
    return raw.replaceFirst('Exception: ', '');
  }

  Future<void> _onGoogleLoginEvent(
      GoogleLoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _googleSignIn
          .signOut(); // Clear cached account to force account picker
      final account = await _googleSignIn.signIn();
      if (account == null) {
        emit(AuthInitial()); // User cancelled → silent, no error
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        emit(const AuthFailure(
            error: 'Không lấy được token từ Google. Kiểm tra cấu hình OAuth.'));
        return;
      }
      final userData = await authRepository.googleSignIn(
        idToken,
        authEntry: event.authEntry,
        referralCode: event.referralCode,
      );
      emit(AuthSuccess(userData: userData));
    } catch (error) {
      emit(AuthFailure(error: _googleErrorMessage(error)));
    }
  }

  Future<void> _onGoogleWebLoginSuccess(
      GoogleWebLoginSuccessEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final auth = await event.account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        emit(const AuthFailure(
            error: 'Không lấy được token từ Google (Web). Hãy thử lại.'));
        return;
      }
      final userData = await authRepository.googleSignIn(
        idToken,
        authEntry: webAuthEntry,
        referralCode: webReferralCode,
      );
      emit(AuthSuccess(userData: userData));
    } catch (error) {
      emit(AuthFailure(error: _googleErrorMessage(error)));
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
    } catch (error) {
      emit(AuthFailure(error: error.toString()));
    }
  }
}
