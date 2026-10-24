import 'auth_error_mapper.dart';
import 'user_model.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

/// State terpusat untuk proses autentikasi aplikasi.
class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final AuthErrorInfo? error;

  const AuthState({
    required this.status,
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  factory AuthState.unauthenticated({AuthErrorInfo? error}) => AuthState(
        status: AuthStatus.unauthenticated,
        error: error,
      );

  factory AuthState.authenticated({
    required UserModel user,
    required String token,
  }) =>
      AuthState(
        status: AuthStatus.authenticated,
        user: user,
        token: token,
      );

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? token,
    bool? isLoading,
    AuthErrorInfo? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
