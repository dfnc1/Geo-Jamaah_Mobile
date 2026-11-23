import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_exception/app_exception.dart';
import '../../../core/error_mapper.dart';
import '../data/mahasantri_repository.dart';
import '../domain/presensi_hari_ini_model.dart';

class BerandaState {
  final bool isLoading;
  final bool isRefreshing;
  final PresensiHariIniResponse? data;
  final String? errorMessage;

  const BerandaState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.data,
    this.errorMessage,
  });

  BerandaState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    PresensiHariIniResponse? data,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BerandaState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      data: data ?? this.data,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Provider durasi polling interval otomatis (default: 30 detik, null untuk mematikan polling saat test).
final berandaPollingIntervalProvider = Provider<Duration?>((ref) {
  return const Duration(seconds: 30);
});

final berandaControllerProvider =
    StateNotifierProvider.autoDispose<BerandaController, BerandaState>((ref) {
  final repository = ref.watch(mahasantriRepositoryProvider);
  return BerandaController(repository: repository);
});

class BerandaController extends StateNotifier<BerandaState> {
  final MahasantriRepository repository;

  BerandaController({required this.repository}) : super(const BerandaState());

  /// Muat data pertama kali (menampilkan indikator loading utama jika data kosong)
  Future<void> loadInitial() async {
    if (state.data != null) {
      await refreshSilently();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await repository.getPresensiHariIni();
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        data: response,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapErrorMessage(e),
      );
    }
  }

  /// Tarik untuk muat ulang (Pull-to-refresh)
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      final response = await repository.getPresensiHariIni();
      if (!mounted) return;
      state = state.copyWith(
        isRefreshing: false,
        data: response,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: _mapErrorMessage(e),
      );
    }
  }

  /// Muat ulang diam-diam (auto-refresh interval 30 detik) tanpa mengosongkan UI
  Future<void> refreshSilently() async {
    if (state.isLoading) return;
    try {
      final response = await repository.getPresensiHariIni();
      if (!mounted) return;
      state = state.copyWith(
        data: response,
        clearError: true,
      );
    } catch (_) {
      // Pada silent refresh, jangan ganggu tampilan pengguna jika ada kegagalan sesaat
    }
  }

  /// Menghapus pesan error aktif.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String? _mapErrorMessage(dynamic error) {
    if (error is AppException) {
      if (error.status == 401) {
        return null; // Ditangani oleh global onLogout
      }
      if (error.status == 403 || error.code.toUpperCase() == 'ERR_FORBIDDEN_ROLE') {
        return 'Akses ditolak: Anda tidak memiliki izin untuk melihat presensi Mahasantri.';
      }
      return mapAppException(error);
    }
    return 'Terjadi kesalahan saat memuat data presensi. Silakan coba lagi.';
  }
}
