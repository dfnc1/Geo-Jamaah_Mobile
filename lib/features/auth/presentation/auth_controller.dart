import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client/api_client.dart';
import '../../../core/services/device_id_service.dart';
import '../data/auth_repository.dart';
import '../domain/auth_error_mapper.dart';
import '../domain/auth_state.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final deviceIdService = ref.watch(deviceIdServiceProvider);
  final authEvent = ref.watch(authEventProvider);

  final controller = AuthController(
    authRepository: repository,
    deviceIdService: deviceIdService,
  );

  void onSessionExpired() {
    controller.handleSessionExpired();
  }

  authEvent.addListener(onSessionExpired);
  ref.onDispose(() => authEvent.removeListener(onSessionExpired));

  return controller;
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final DeviceIdService _deviceIdService;
  bool _isRestoring = false;

  AuthController({
    required AuthRepository authRepository,
    required DeviceIdService deviceIdService,
    bool autoRestore = true,
  })  : _authRepository = authRepository,
        _deviceIdService = deviceIdService,
        super(AuthState.initial()) {
    if (autoRestore) {
      restoreSession();
    }
  }

  /// Memulihkan sesi pengguna dari local secure storage
  Future<void> restoreSession() async {
    _isRestoring = true;
    try {
      final session = await _authRepository.restoreSession();
      if (!mounted || !_isRestoring) return;
      if (session != null) {
        state = AuthState.authenticated(
          user: session.user,
          token: session.token,
        );
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (_) {
      if (mounted && _isRestoring) {
        state = AuthState.unauthenticated();
      }
    } finally {
      _isRestoring = false;
    }
  }

  /// Memproses login dengan validasi lokal dan Device ID
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    if (state.isLoading) return false;
    _isRestoring = false;
    final cleanUsername = username.trim();

    if (cleanUsername.isEmpty || password.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: const AuthErrorInfo(
          message: 'Username/NIM dan Password wajib diisi.',
        ),
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final deviceId = await _deviceIdService.getDeviceId();
    if (!mounted) return false;
    if (deviceId == null || deviceId.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: const AuthErrorInfo(
          message: 'Device ID tidak terbaca. Hubungi Admin.',
        ),
      );
      return false;
    }

    try {
      final result = await _authRepository.login(
        username: cleanUsername,
        password: password,
        deviceId: deviceId,
      );
      if (!mounted) return false;

      state = AuthState.authenticated(
        user: result.user,
        token: result.token,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      final errorInfo = AuthErrorMapper.map(e);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: errorInfo,
      );
      return false;
    }
  }

  /// Dipanggil saat token kedaluwarsa (401)
  void handleSessionExpired() {
    if (!mounted) return;
    _isRestoring = false;
    _authRepository.logout();
    state = AuthState.unauthenticated(
      error: const AuthErrorInfo(
        message: 'Sesi Anda telah berakhir. Silakan masuk kembali.',
      ),
    );
  }

  /// Logout manual dari menu pengguna
  Future<void> logout() async {
    _isRestoring = false;
    await _authRepository.logout();
    if (!mounted) return;
    state = AuthState.unauthenticated();
  }

  /// Menghapus banner error aktif
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
