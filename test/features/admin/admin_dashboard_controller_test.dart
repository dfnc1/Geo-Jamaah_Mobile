import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_jamaah/core/api_client/api_client.dart';
import 'package:geo_jamaah/core/app_exception/app_exception.dart';
import 'package:geo_jamaah/features/admin/domain/admin_models.dart';
import 'package:geo_jamaah/features/admin/presentation/admin_dashboard_controller.dart';
import '../../helpers/test_fakes.dart';

void main() {
  late FakeAdminRepository fakeRepo;
  late AdminDashboardController controller;

  setUp(() {
    final client = ApiClient(
      customDio: Dio(),
      tokenStore: FakeTokenStore(),
      baseUrl: 'http://localhost:3000',
    );
    fakeRepo = FakeAdminRepository(apiClient: client);
    controller = AdminDashboardController(repository: fakeRepo);
  });

  group('AdminDashboardController - loadRekap', () {
    test('berhasil memuat rekap dan memperbarui state', () async {
      expect(controller.state.isLoadingRekap, isFalse);
      expect(controller.state.rekap, isNull);

      await controller.loadRekap();

      expect(controller.state.isLoadingRekap, isFalse);
      expect(controller.state.errorRekap, isNull);
      expect(controller.state.rekap, isNotNull);
      expect(controller.state.rekap!.jumlahSantriAktif, 15);
      expect(controller.state.rekap!.jumlahSantriKritis, 2);
      expect(controller.state.rekap!.presensi.hadir, 200);
      expect(fakeRepo.getRekapCalls, 1);
    });

    test('menangani error jaringan/server saat memuat rekap', () async {
      fakeRepo.errorToThrow = AppException(
        code: 'ERR_FORBIDDEN_ROLE',
        message: 'Akses ditolak',
        status: 403,
      );

      await controller.loadRekap();

      expect(controller.state.isLoadingRekap, isFalse);
      expect(controller.state.rekap, isNull);
      expect(controller.state.errorRekap, isNotNull);
      expect(controller.state.errorRekap, contains('tidak memiliki hak akses Admin'));
    });
  });

  group('AdminDashboardController - loadTren', () {
    test('berhasil memuat data tren sesuai jumlah hari', () async {
      await controller.loadTren(hari: 14);

      expect(controller.state.isLoadingTren, isFalse);
      expect(controller.state.errorTren, isNull);
      expect(controller.state.trenHari, 14);
      expect(controller.state.tren, isNotNull);
      expect(fakeRepo.getTrenCalls, 1);
    });

    test('menangani error saat memuat tren', () async {
      fakeRepo.errorToThrow = AppException(
        code: 'ERR_NETWORK',
        message: 'Gagal koneksi',
      );

      await controller.loadTren();

      expect(controller.state.isLoadingTren, isFalse);
      expect(controller.state.tren, isNull);
      expect(controller.state.errorTren, isNotNull);
    });
  });

  group('AdminDashboardController - loadLogs & Filter Modul', () {
    test('berhasil memuat log aktivitas dengan refresh', () async {
      await controller.loadLogs(refresh: true);

      expect(controller.state.isLoadingLogs, isFalse);
      expect(controller.state.errorLogs, isNull);
      expect(controller.state.logs.length, 2);
      expect(controller.state.logPage, 1);
      expect(controller.state.logTotalPages, 1);
    });

    test('mengganti filter modul mereset daftar dan memuat ulang log', () async {
      controller.setFilterModul('Presensi');

      expect(controller.state.selectedModul, 'Presensi');
      // Otomatis memicu loadLogs(refresh: true)
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeRepo.lastLogModul, 'Presensi');
    });

    test('tidak memuat jika filter modul sama', () async {
      controller.setFilterModul('Semua'); // Default adalah 'Semua'
      expect(fakeRepo.getLogsCalls, 0);
    });

    test('muatLebihBanyakLogs menambah halaman jika masih ada totalPages', () async {
      fakeRepo.mockLogs = const ActivityLogResponse(
        logs: [
          ActivityLogItem(
            idLog: 'log-1',
            username: 'admin',
            role: 'Admin',
            modul: 'Auth',
            aktivitas: 'Login berhasil',
            createdAt: '2026-10-18T10:00:00.000Z',
          ),
        ],
        page: 1,
        limit: 1,
        total: 2,
        totalPages: 2,
      );

      await controller.loadLogs(refresh: true);
      expect(controller.state.logs.length, 1);
      expect(controller.state.logPage, 1);
      expect(controller.state.logTotalPages, 2);

      await controller.muatLebihBanyakLogs();
      expect(controller.state.logPage, 2);
    });

    test('muatLebihBanyakLogs gagal tidak menaikkan logPage agar retry tidak melompati halaman', () async {
      fakeRepo.mockLogs = const ActivityLogResponse(
        logs: [
          ActivityLogItem(
            idLog: 'log-1',
            username: 'admin',
            role: 'Admin',
            modul: 'Auth',
            aktivitas: 'Login berhasil',
            createdAt: '2026-10-18T10:00:00.000Z',
          ),
        ],
        page: 1,
        limit: 1,
        total: 3,
        totalPages: 3,
      );

      await controller.loadLogs(refresh: true);
      expect(controller.state.logPage, 1);

      fakeRepo.errorToThrow = const AppException(
        code: 'ERR_NETWORK',
        message: 'Network down',
      );
      await controller.muatLebihBanyakLogs();

      expect(controller.state.logPage, 1);
      expect(controller.state.errorLogs, isNotNull);

      fakeRepo.errorToThrow = null;
      await controller.muatLebihBanyakLogs();
      expect(controller.state.logPage, 2);
    });
  });

  group('AdminDashboardController - resetDevice', () {
    test('validasi lokal: NIM kosong mengembalikan false dan set pesan error', () async {
      final sukses = await controller.resetDevice('   ');

      expect(sukses, isFalse);
      expect(controller.state.actionError, contains('NIM Mahasantri tidak boleh kosong'));
      expect(fakeRepo.resetDeviceCalls, 0);
    });

    test('berhasil mereset device mahasantri', () async {
      final sukses = await controller.resetDevice('24050505050');

      expect(sukses, isTrue);
      expect(fakeRepo.resetDeviceCalls, 1);
      expect(fakeRepo.lastResetNim, '24050505050');
      expect(controller.state.actionError, isNull);
      expect(controller.state.actionMessage, contains('berhasil direset'));
      expect(controller.state.lastResetResult, isNotNull);
    });

    test('gagal mereset device jika santri tidak ditemukan (404)', () async {
      fakeRepo.errorToThrow = AppException(
        code: 'ERR_MAHASANTRI_NOT_FOUND',
        message: 'Mahasantri tidak ditemukan',
        status: 404,
      );

      final sukses = await controller.resetDevice('999999999');

      expect(sukses, isFalse);
      expect(controller.state.actionError, contains('Mahasantri dengan NIM tersebut tidak ditemukan'));
    });
  });

  group('AdminDashboardController - triggerJob', () {
    test('berhasil memicu job kehadiran hari ini dan memuat ulang rekap', () async {
      final sukses = await controller.triggerJob();

      expect(sukses, isTrue);
      expect(fakeRepo.triggerJobCalls, 1);
      expect(fakeRepo.lastJobTanggal, isNull);
      expect(controller.state.actionMessage, contains('Job selesai'));
      expect(fakeRepo.getRekapCalls, 1); // Memuat ulang rekap otomatis
    });

    test('berhasil memicu job backfill tanggal spesifik', () async {
      final sukses = await controller.triggerJob(tanggal: '2026-10-15');

      expect(sukses, isTrue);
      expect(fakeRepo.triggerJobCalls, 1);
      expect(fakeRepo.lastJobTanggal, '2026-10-15');
    });

    test('gagal memicu job jika di luar window waktu', () async {
      fakeRepo.errorToThrow = AppException(
        code: 'ERR_TIME_WINDOW_INVALID',
        message: 'Belum melewati waktu akhir presensi',
        status: 400,
      );

      final sukses = await controller.triggerJob();

      expect(sukses, isFalse);
      expect(controller.state.actionError, contains('belum lewat'));
    });
  });

  group('AdminDashboardController - clearActionFeedback', () {
    test('membersihkan actionMessage dan actionError', () async {
      await controller.resetDevice('');
      expect(controller.state.actionError, isNotNull);

      controller.clearActionFeedback();
      expect(controller.state.actionError, isNull);
      expect(controller.state.actionMessage, isNull);
    });
  });
}
