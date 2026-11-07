import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_exception/app_exception.dart';
import '../data/izin_repository.dart';
import '../domain/izin_error_mapper.dart';
import '../domain/izin_model.dart';

class IzinState {
  final bool isLoading;
  final bool isSubmitting;
  final List<IzinItem> daftarIzin;
  final String? errorMessage;
  final IzinResult? hasilAjukan; // hasil pengajuan terbaru

  const IzinState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.daftarIzin = const [],
    this.errorMessage,
    this.hasilAjukan,
  });

  IzinState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<IzinItem>? daftarIzin,
    String? errorMessage,
    bool clearError = false,
    IzinResult? hasilAjukan,
    bool clearHasil = false,
  }) {
    return IzinState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      daftarIzin: daftarIzin ?? this.daftarIzin,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasilAjukan: clearHasil ? null : (hasilAjukan ?? this.hasilAjukan),
    );
  }
}

final izinControllerProvider =
    StateNotifierProvider<IzinController, IzinState>((ref) {
  final repository = ref.watch(izinRepositoryProvider);
  return IzinController(repository: repository);
});

class IzinController extends StateNotifier<IzinState> {
  final IzinRepository repository;

  IzinController({required this.repository}) : super(const IzinState());

  /// Muat daftar izin milik sendiri (GET /v1/izin/saya).
  Future<void> loadIzinSaya() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final daftar = await repository.getIzinSaya();
      state = state.copyWith(
        isLoading: false,
        daftarIzin: daftar,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapErrorMessage(e),
      );
    }
  }

  /// Ajukan izin baru (POST /v1/izin).
  /// Setelah sukses, daftar izin dimuat ulang dan hasil ajukan disimpan.
  Future<bool> ajukanIzin(IzinRequest request) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final hasil = await repository.ajukanIzin(request);
      state = state.copyWith(
        isSubmitting: false,
        hasilAjukan: hasil,
        clearError: true,
      );
      // Muat ulang daftar agar pengajuan baru muncul di daftar
      await loadIzinSaya();
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: IzinErrorMapper.map(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: IzinErrorMapper.map(e),
      );
      return false;
    }
  }

  /// Menghapus pesan error aktif.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Menghapus hasil ajukan (misal setelah ditutup layar konfirmasi).
  void clearHasilAjukan() {
    state = state.copyWith(clearHasil: true);
  }

  String _mapErrorMessage(dynamic error) {
    if (error is AppException) {
      if (error.status == 401) {
        return ''; // Ditangani oleh global onLogout
      }
      if (error.status == 403) {
        return 'Akses ditolak: Anda tidak memiliki izin untuk mengajukan izin.';
      }
      if (error.code == 'ERR_CONNECTION' ||
          error.code == 'ERR_NETWORK' ||
          error.code == 'ERR_TIMEOUT') {
        return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
      }
      if (error.message.isNotEmpty) {
        return error.message;
      }
    }
    return 'Terjadi kesalahan saat memuat data izin. Silakan coba lagi.';
  }
}
