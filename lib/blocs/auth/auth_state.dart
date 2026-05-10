import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final Map<String, dynamic> userData;

  const AuthSuccess({required this.userData});

  @override
  List<Object?> get props => [userData];
}

class AuthFailure extends AuthState {
  final String error;

  const AuthFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

class AuthAccountExpired extends AuthState {
  final String username;
  final String upgradeUrl;
  final String zaloGroup;
  final String zaloSupport;

  const AuthAccountExpired({
    required this.username,
    required this.upgradeUrl,
    required this.zaloGroup,
    required this.zaloSupport,
  });

  @override
  List<Object?> get props => [username, upgradeUrl, zaloGroup, zaloSupport];
}
