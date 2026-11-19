import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_exception/app_exception.dart';
import '../../../core/error_mapper.dart';
import '../data/musyrif_dashboard_repository.dart';
import '../domain/musyrif_models.dart';

class MusyrifDashboardState {
  final bool isLoadingKritis;
  final bool isLoadingMonitoring;
  final bool isLoadingTren;
  final List<SantriKritis> daftarKritis;
  final MonitoringResponse? monitoring;
  final TrenKehadiranResponse? tren;
  final String? errorKritis;
  final String? errorMonitoring;
  final String? errorTren;
  final DateTime? tanggalMonitoring;

  /// Getter kompatibilitas pesan error aktif.
  String? get errorMessage => errorKritis ?? errorMonitoring ?? errorTren;

  const MusyrifDashboardState({
    this.isLoadingKritis = false,
    this.isLoadingMonitoring = false,
    this.isLoadingTren = false,
    this.daftarKritis = const [],
    this.monitoring,
    this.tren,
    this.errorKritis,
    this.errorMonitoring,
    this.errorTren,
    this.tanggalMonitoring,
  });

  MusyrifDashboardState copyWith({
    bool? isLoadingKritis,
    bool? isLoadingMonitoring,
    bool? isLoadingTren,
    List<SantriKritis>? daftarKritis,
    MonitoringResponse? monitoring,
    bool clearMonitoring = false,
    TrenKehadiranResponse? tren,
    bool clearTren = false,
    String? errorKritis,
    bool clearErrorKritis = false,
    String? errorMonitoring,
    bool clearErrorMonitoring = false,
    String? errorTren,
    bool clearErrorTren = false,
    String? errorMessage,
    bool clearError = false,
    DateTime? tanggalMonitoring,
  }) {
    return MusyrifDashboardState(
      isLoadingKritis: isLoadingKritis ?? this.isLoadingKritis,
      isLoadingMonitoring: isLoadingMonitoring ?? this.isLoadingMonitoring,
      isLoadingTren: isLoadingTren ?? this.isLoadingTren,
      daftarKritis: daftarKritis ?? this.daftarKritis,
      monitoring: clearMonitoring ? null : (monitoring ?? this.monitoring),
      tren: clearTren ? null : (tren ?? this.tren),
      errorKritis: clearError || clearErrorKritis
          ? null
          : (errorKritis ?? errorMessage ?? this.errorKritis),
      errorMonitoring: clearError || clearErrorMonitoring
          ? null
          : (errorMonitoring ?? errorMessage ?? this.errorMonitoring),
      errorTren: clearError || clearErrorTren
          ? null
          : (errorTren ?? errorMessage ?? this.errorTren),
      tanggalMonitoring:
          tanggalMonitoring ?? this.tanggalMonitoring,
    );
  }
}

final musyrifDashboardControllerProvider =
    StateNotifierProvider<MusyrifDashboardController, MusyrifDashboardState>(
  (ref) {
    final repository = ref.watch(musyrifDashboardRepositoryProvider);
    return MusyrifDashboardController(repository: repository);
  },
);

class MusyrifDashboardController
    extends StateNotifier<MusyrifDashboardState> {
  final MusyrifDashboardRepository repository;

  MusyrifDashboardController({required this.repository})
      : super(MusyrifDashboardState(
            tanggalMonitoring: DateTime.now()));

  /// Muat daftar santri kritis (DSS).
  Future<void> loadKritis() async {
    state = state.copyWith(isLoadingKritis: true, clearErrorKritis: true);
    try {
      final daftar = await repository.getSantriKritis();
      state = state.copyWith(
        isLoadingKritis: false,
        daftarKritis: daftar,
        clearErrorKritis: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingKritis: false,
        errorKritis: _mapErrorMessage(e),
      );
    }
  }

  /// Muat monitoring presensi per tanggal.
  Future<void> loadMonitoring(String tanggal) async {
    state = state.copyWith(
      isLoadingMonitoring: true,
      clearErrorMonitoring: true,
      tanggalMonitoring: DateTime.tryParse(tanggal) ?? state.tanggalMonitoring,
    );
    try {
      final monitoring = await repository.getMonitoring(tanggal: tanggal);
      state = state.copyWith(
        isLoadingMonitoring: false,
        monitoring: monitoring,
        clearErrorMonitoring: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMonitoring: false,
        errorMonitoring: _mapErrorMessage(e),
      );
    }
  }

  /// Muat tren kehadiran.
  Future<void> loadTren({int hari = 7}) async {
    state = state.copyWith(isLoadingTren: true, clearErrorTren: true);
    try {
      final tren = await repository.getTrenKehadiran(hari: hari);
      state = state.copyWith(
        isLoadingTren: false,
        tren: tren,
        clearErrorTren: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingTren: false,
        errorTren: _mapErrorMessage(e),
      );
    }
  }

  /// Ganti tanggal monitoring dan muat ulang.
  Future<void> gantiTanggalMonitoring(DateTime tanggal) async {
    state = state.copyWith(tanggalMonitoring: tanggal);
    final formatted = '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}';
    await loadMonitoring(formatted);
  }

  /// Menghapus pesan error aktif.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _mapErrorMessage(dynamic error) {
    if (error is AppException) {
      if (error.status == 401) {
        return ''; // Ditangani oleh global onLogout
      }
    }
    return mapAppException(error);
  }
}
