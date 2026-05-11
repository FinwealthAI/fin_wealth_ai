import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoginEvent extends AuthEvent {
  final String username;
  final String password;

  LoginEvent(this.username, this.password);

  @override
  List<Object> get props => [username, password];
}

class CheckAuthStatus extends AuthEvent {}

/// Kiểm tra nhẹ khi app resume từ background — chỉ gọi account-status, không refresh token
class CheckAccountExpiry extends AuthEvent {}

class LogoutRequested extends AuthEvent {}

class GoogleLoginEvent extends AuthEvent {
  final String authEntry; // 'login' or 'signup'
  GoogleLoginEvent({this.authEntry = 'login'});
}

class AuthUserUpdated extends AuthEvent {
  final Map<String, dynamic> userData;
  AuthUserUpdated(this.userData);

  @override
  List<Object> get props => [userData];
}
