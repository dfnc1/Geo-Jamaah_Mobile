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

  authEvent.addListener(() {
    controller.handleSessionExpired();
  });

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
      if (!_isRestoring) return; // Dibatalkan oleh login/logout berikutnya
      if (session != null) {
        state = AuthState.authenticated(
          user: session.user,
          token: session.token,
        );
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (_) {
      if (_isRestoring) {
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
    _isRestoring = false;
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();

    // Validasi lokal
    if (cleanUsername.isEmpty || cleanPassword.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: const AuthErrorInfo(
          message: 'Username/NIM dan Password wajib diisi.',
        ),
      );
      return false;
    }

    // Ambil Device ID
    final deviceId = await _deviceIdService.getDeviceId();
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

    // Set status memuat
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _authRepository.login(
        username: cleanUsername,
        password: cleanPassword,
        deviceId: deviceId,
      );

      state = AuthState.authenticated(
        user: result.user,
        token: result.token,
      );
      return true;
    } catch (e) {
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
    state = AuthState.unauthenticated();
  }

  /// Menghapus banner error aktif
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
