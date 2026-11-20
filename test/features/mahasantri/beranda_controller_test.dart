import 'package:flutter_test/flutter_test.dart';
import 'package:geo_jamaah/core/api_client/api_client.dart';
import 'package:geo_jamaah/core/app_exception/app_exception.dart';
import 'package:geo_jamaah/features/mahasantri/data/mahasantri_repository.dart';
import 'package:geo_jamaah/features/mahasantri/domain/presensi_hari_ini_model.dart';
import 'package:geo_jamaah/features/mahasantri/presentation/beranda_controller.dart';
import '../../helpers/test_fakes.dart';

class MockMahasantriRepository implements MahasantriRepository {
  @override
  final ApiClient apiClient;

  PresensiHariIniResponse? mockResponse;
  Exception? mockError;
  int callCount = 0;

  MockMahasantriRepository({required this.apiClient});

  @override
  Future<PresensiHariIniResponse> getPresensiHariIni() async {
    callCount++;
    if (mockError != null) {
      throw mockError!;
    }
    return mockResponse ??
        const PresensiHariIniResponse(
          tanggal: '2026-10-19',
          jadwal: [],
        );
  }
}

void main() {
  late MockMahasantriRepository repository;
  late BerandaController controller;

  setUp(() {
    final fakeTokenStore = FakeTokenStore();
    final fakeApiClient = ApiClient(tokenStore: fakeTokenStore);
    repository = MockMahasantriRepository(apiClient: fakeApiClient);
    controller = BerandaController(repository: repository);
  });

  group('BerandaController - Alur Pengambilan Data & State', () {
    test('loadInitial berhasil memuat data dan mematikan loading', () async {
      repository.mockResponse = const PresensiHariIniResponse(
        tanggal: '2026-10-19',
        masjid: MasjidModel(
          idMasjid: 'masjid-01',
          namaMasjid: 'Masjid Jami',
          latitude: -6.2,
          longitude: 106.8,
          radiusToleransi: 100,
        ),
        jadwal: [
          JadwalHariIniModel(
            idJadwal: 'j1',
            namaSholat: 'Subuh',
            waktuAzan: '04:30',
            waktuIqamah: '04:35',
            waktuMulaiPresensi: '04:20',
            waktuAkhirPresensi: '05:00',
            status: StatusPresensiJadwal.hadir,
            sedangDalamWindow: false,
          ),
        ],
      );

      expect(controller.state.isLoading, false);
      expect(controller.state.data, isNull);

      final future = controller.loadInitial();
      expect(controller.state.isLoading, true);

      await future;

      expect(controller.state.isLoading, false);
      expect(controller.state.errorMessage, isNull);
      expect(controller.state.data, isNotNull);
      expect(controller.state.data!.tanggal, '2026-10-19');
      expect(controller.state.data!.jadwal.length, 1);
      expect(repository.callCount, 1);
    });

    test('loadInitial gagal menangani error jaringan', () async {
      repository.mockError = const AppException(
        code: 'ERR_CONNECTION',
        message: 'Gagal terhubung',
      );

      await controller.loadInitial();

      expect(controller.state.isLoading, false);
      expect(controller.state.data, isNull);
      expect(
        controller.state.errorMessage,
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    });

    test('loadInitial gagal menangani error 403 role ditolak', () async {
      repository.mockError = const AppException(
        code: 'ERR_FORBIDDEN_ROLE',
        message: 'Bukan Mahasantri',
        status: 403,
      );

      await controller.loadInitial();

      expect(controller.state.isLoading, false);
      expect(
        controller.state.errorMessage,
        'Akses ditolak: Anda tidak memiliki izin untuk melihat presensi Mahasantri.',
      );
    });

    test('pull-to-refresh memperbarui data dengan flag isRefreshing', () async {
      repository.mockResponse = const PresensiHariIniResponse(
        tanggal: '2026-10-19',
        jadwal: [],
      );

      final refreshFuture = controller.refresh();
      expect(controller.state.isRefreshing, true);

      await refreshFuture;

      expect(controller.state.isRefreshing, false);
      expect(controller.state.data, isNotNull);
      expect(controller.state.errorMessage, isNull);
    });

    test('refreshSilently memperbarui data tanpa mengosongkan data lama', () async {
      // Data awal sudah ada
      repository.mockResponse = const PresensiHariIniResponse(
        tanggal: '2026-10-19',
        jadwal: [],
      );
      await controller.loadInitial();
      expect(controller.state.data, isNotNull);

      // Data baru datang via background polling
      repository.mockResponse = const PresensiHariIniResponse(
        tanggal: '2026-10-19',
        masjid: MasjidModel(
          idMasjid: 'masjid-update',
          namaMasjid: 'Masjid Terupdate',
          latitude: 0,
          longitude: 0,
          radiusToleransi: 50,
        ),
        jadwal: [],
      );

      await controller.refreshSilently();

      expect(controller.state.isLoading, false);
      expect(controller.state.data!.masjid?.namaMasjid, 'Masjid Terupdate');

      // Jika silent refresh mengalami gangguan, data lama tetap dipertahankan
      repository.mockError = const AppException(
        code: 'ERR_TIMEOUT',
        message: 'Timeout',
      );
      await controller.refreshSilently();

      // Data lama tidak hilang dan tidak menampilkan error dialog
      expect(controller.state.data!.masjid?.namaMasjid, 'Masjid Terupdate');
    });
  });
}
