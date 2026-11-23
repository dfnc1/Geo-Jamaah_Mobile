import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_exception/app_exception.dart';
import '../../../core/error_mapper.dart';
import '../data/izin_musyrif_repository.dart';
import '../domain/izin_musyrif_error_mapper.dart';
import '../domain/izin_musyrif_model.dart';

class IzinMusyrifState {
  final bool isLoading;
  final bool isVerifying;
  final List<IzinMusyrifItem> daftarIzin;
  final String? errorMessage;
  final IzinFilterMusyrif filter;

  const IzinMusyrifState({
    this.isLoading = false,
    this.isVerifying = false,
    this.daftarIzin = const [],
    this.errorMessage,
    this.filter = IzinFilterMusyrif.pending,
  });

  IzinMusyrifState copyWith({
    bool? isLoading,
    bool? isVerifying,
    List<IzinMusyrifItem>? daftarIzin,
    String? errorMessage,
    bool clearError = false,
    IzinFilterMusyrif? filter,
  }) {
    return IzinMusyrifState(
      isLoading: isLoading ?? this.isLoading,
      isVerifying: isVerifying ?? this.isVerifying,
      daftarIzin: daftarIzin ?? this.daftarIzin,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      filter: filter ?? this.filter,
    );
  }
}

final izinMusyrifControllerProvider =
    StateNotifierProvider.autoDispose<IzinMusyrifController, IzinMusyrifState>((ref) {
  final repository = ref.watch(izinMusyrifRepositoryProvider);
  return IzinMusyrifController(repository: repository);
});

class IzinMusyrifController extends StateNotifier<IzinMusyrifState> {
  final IzinMusyrifRepository repository;
  int _loadRequestId = 0;

  IzinMusyrifController({required this.repository})
      : super(const IzinMusyrifState());

  /// Muat daftar izin binaan sesuai filter.
  Future<void> loadIzinBinaan() async {
    final requestId = ++_loadRequestId;
    final status = state.filter.rawValue;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final daftar = await repository.getIzinBinaan(status: status);
      if (!mounted || requestId != _loadRequestId) return;
      state = state.copyWith(
        isLoading: false,
        daftarIzin: daftar,
        clearError: true,
      );
    } catch (e) {
      if (!mounted || requestId != _loadRequestId) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapErrorMessage(e),
      );
    }
  }

  /// Ganti filter dan muat ulang daftar.
  Future<void> gantiFilter(IzinFilterMusyrif filterBaru) async {
    state = state.copyWith(
      filter: filterBaru,
      daftarIzin: const [],
      clearError: true,
    );
    await loadIzinBinaan();
  }

  /// Verifikasi izin (setujui atau tolak).
  /// Setelah sukses, daftar dimuat ulang.
  Future<bool> verifikasiIzin({
    required String idIzin,
    required String statusBaru,
  }) async {
    if (state.isVerifying) return false;
    state = state.copyWith(isVerifying: true, clearError: true);
    try {
      await repository.verifikasiIzin(idIzin: idIzin, statusBaru: statusBaru);
      if (!mounted) return false;
      state = state.copyWith(isVerifying: false, clearError: true);
      await loadIzinBinaan();
      return true;
    } on AppException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isVerifying: false,
        errorMessage: IzinMusyrifErrorMapper.map(e),
      );
      return false;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isVerifying: false,
        errorMessage: IzinMusyrifErrorMapper.map(e),
      );
      return false;
    }
  }

  /// Menghapus pesan error aktif.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String? _mapErrorMessage(dynamic error) {
    if (error is AppException && error.status == 401) {
      return null; // Ditangani oleh global onLogout
    }
    return mapAppException(error);
  }
}
