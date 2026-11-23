import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../musyrif/domain/musyrif_models.dart';
import '../data/admin_repository.dart';
import '../domain/admin_error_mapper.dart';
import '../domain/admin_models.dart';

class AdminDashboardState {
  final bool isLoadingRekap;
  final String? errorRekap;
  final AdminRekap? rekap;

  final bool isLoadingTren;
  final String? errorTren;
  final TrenKehadiranResponse? tren;
  final int trenHari;

  final bool isLoadingLogs;
  final String? errorLogs;
  final List<ActivityLogItem> logs;
  final int logPage;
  final int logTotalPages;
  final String selectedModul;

  final bool isActionLoading;
  final String? actionMessage;
  final String? actionError;
  final ResetDeviceResult? lastResetResult;
  final JobTandaiResult? lastJobResult;

  const AdminDashboardState({
    this.isLoadingRekap = false,
    this.errorRekap,
    this.rekap,
    this.isLoadingTren = false,
    this.errorTren,
    this.tren,
    this.trenHari = 7,
    this.isLoadingLogs = false,
    this.errorLogs,
    this.logs = const [],
    this.logPage = 1,
    this.logTotalPages = 1,
    this.selectedModul = 'Semua',
    this.isActionLoading = false,
    this.actionMessage,
    this.actionError,
    this.lastResetResult,
    this.lastJobResult,
  });

  AdminDashboardState copyWith({
    bool? isLoadingRekap,
    String? errorRekap,
    bool clearErrorRekap = false,
    AdminRekap? rekap,
    bool? isLoadingTren,
    String? errorTren,
    bool clearErrorTren = false,
    TrenKehadiranResponse? tren,
    int? trenHari,
    bool? isLoadingLogs,
    String? errorLogs,
    bool clearErrorLogs = false,
    List<ActivityLogItem>? logs,
    int? logPage,
    int? logTotalPages,
    String? selectedModul,
    bool? isActionLoading,
    String? actionMessage,
    bool clearActionMessage = false,
    String? actionError,
    bool clearActionError = false,
    ResetDeviceResult? lastResetResult,
    JobTandaiResult? lastJobResult,
  }) {
    return AdminDashboardState(
      isLoadingRekap: isLoadingRekap ?? this.isLoadingRekap,
      errorRekap: clearErrorRekap ? null : (errorRekap ?? this.errorRekap),
      rekap: rekap ?? this.rekap,
      isLoadingTren: isLoadingTren ?? this.isLoadingTren,
      errorTren: clearErrorTren ? null : (errorTren ?? this.errorTren),
      tren: tren ?? this.tren,
      trenHari: trenHari ?? this.trenHari,
      isLoadingLogs: isLoadingLogs ?? this.isLoadingLogs,
      errorLogs: clearErrorLogs ? null : (errorLogs ?? this.errorLogs),
      logs: logs ?? this.logs,
      logPage: logPage ?? this.logPage,
      logTotalPages: logTotalPages ?? this.logTotalPages,
      selectedModul: selectedModul ?? this.selectedModul,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      actionMessage:
          clearActionMessage ? null : (actionMessage ?? this.actionMessage),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      lastResetResult: lastResetResult ?? this.lastResetResult,
      lastJobResult: lastJobResult ?? this.lastJobResult,
    );
  }
}

final adminDashboardControllerProvider = StateNotifierProvider.autoDispose<
    AdminDashboardController, AdminDashboardState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminDashboardController(repository: repository);
});

class AdminDashboardController extends StateNotifier<AdminDashboardState> {
  final AdminRepository repository;
  int _logsRequestId = 0;

  AdminDashboardController({required this.repository})
      : super(const AdminDashboardState());

  Future<void> loadRekap() async {
    state = state.copyWith(isLoadingRekap: true, clearErrorRekap: true);
    try {
      final rekap = await repository.getRekap();
      if (!mounted) return;
      state = state.copyWith(isLoadingRekap: false, rekap: rekap);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingRekap: false,
        errorRekap: AdminErrorMapper.map(e),
      );
    }
  }

  Future<void> loadTren({int? hari}) async {
    final targetHari = hari ?? state.trenHari;
    state = state.copyWith(
      isLoadingTren: true,
      clearErrorTren: true,
      trenHari: targetHari,
    );
    try {
      final tren = await repository.getTrenKehadiran(hari: targetHari);
      if (!mounted) return;
      state = state.copyWith(isLoadingTren: false, tren: tren);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingTren: false,
        errorTren: AdminErrorMapper.map(e),
      );
    }
  }

  Future<void> loadLogs({bool refresh = false, int? page}) async {
    if (!refresh && state.isLoadingLogs) return;

    final requestId = ++_logsRequestId;
    final targetPage = refresh ? 1 : (page ?? state.logPage);
    final targetModul = state.selectedModul;
    state = state.copyWith(
      isLoadingLogs: true,
      clearErrorLogs: true,
    );

    try {
      final res = await repository.getActivityLogs(
        page: targetPage,
        limit: 20,
        modul: targetModul,
      );
      if (!mounted || requestId != _logsRequestId) return;

      final newLogs = refresh ? res.logs : [...state.logs, ...res.logs];

      state = state.copyWith(
        isLoadingLogs: false,
        logs: newLogs,
        logPage: targetPage,
        logTotalPages: res.totalPages,
      );
    } catch (e) {
      if (!mounted || requestId != _logsRequestId) return;
      state = state.copyWith(
        isLoadingLogs: false,
        errorLogs: AdminErrorMapper.map(e),
      );
    }
  }

  Future<void> muatLebihBanyakLogs() async {
    if (state.isLoadingLogs || state.logPage >= state.logTotalPages) return;
    await loadLogs(refresh: false, page: state.logPage + 1);
  }

  void setFilterModul(String modul) {
    if (state.selectedModul == modul) return;
    state = state.copyWith(selectedModul: modul, logs: const [], logPage: 1);
    loadLogs(refresh: true);
  }

  Future<bool> resetDevice(String nim) async {
    final cleanNim = nim.trim();
    if (cleanNim.isEmpty) {
      state = state.copyWith(
        actionError: 'NIM Mahasantri tidak boleh kosong.',
      );
      return false;
    }

    state = state.copyWith(
      isActionLoading: true,
      clearActionError: true,
      clearActionMessage: true,
    );

    try {
      final result = await repository.resetDevice(cleanNim);
      if (!mounted) return false;
      state = state.copyWith(
        isActionLoading: false,
        lastResetResult: result,
        actionMessage:
            'Device ID untuk ${result.nama} (NIM: ${result.nim}) berhasil direset.',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isActionLoading: false,
        actionError: AdminErrorMapper.map(e),
      );
      return false;
    }
  }

  Future<bool> triggerJob({String? tanggal, String? idJadwal}) async {
    state = state.copyWith(
      isActionLoading: true,
      clearActionError: true,
      clearActionMessage: true,
    );

    try {
      final result = await repository.triggerJobTandai(
        tanggal: tanggal,
        idJadwal: idJadwal,
      );
      if (!mounted) return false;
      state = state.copyWith(
        isActionLoading: false,
        lastJobResult: result,
        actionMessage:
            'Job selesai: ${result.tidakHadir} Tidak Hadir, ${result.izin} Izin dibuat.',
      );
      await loadRekap();
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isActionLoading: false,
        actionError: AdminErrorMapper.map(e),
      );
      return false;
    }
  }

  void clearActionFeedback() {
    state = state.copyWith(
      clearActionMessage: true,
      clearActionError: true,
    );
  }
}
