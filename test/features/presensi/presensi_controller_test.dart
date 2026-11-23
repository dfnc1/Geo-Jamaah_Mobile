import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geo_jamaah/core/api_client/api_client.dart';
import 'package:geo_jamaah/core/app_exception/app_exception.dart';
import 'package:geo_jamaah/features/presensi/data/presensi_repository.dart';
import 'package:geo_jamaah/features/presensi/domain/location_service.dart';
import 'package:geo_jamaah/features/presensi/domain/presensi_models.dart';
import 'package:geo_jamaah/features/presensi/presentation/presensi_controller.dart';
import '../../helpers/test_fakes.dart' show FakeTokenStore;
import 'mock_location_detector_test.dart';

class FakeLocationService implements LocationService {
  bool serviceEnabled = true;
  LocationPermission permissionStatus = LocationPermission.whileInUse;
  LocationPermission requestResult = LocationPermission.whileInUse;
  Position? customPosition;
  Completer<Position>? positionCompleter;
  Exception? positionError;
  bool appSettingsOpened = false;
  bool locationSettingsOpened = false;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permissionStatus;

  @override
  Future<LocationPermission> requestPermission() async => requestResult;

  @override
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 20),
  }) async {
    if (positionCompleter != null) return positionCompleter!.future;
    if (positionError != null) throw positionError!;
    return customPosition ?? createTestPosition();
  }

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpened = true;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsOpened = true;
    return true;
  }
}

class FakePresensiRepository implements PresensiRepository {
  @override
  final ApiClient apiClient;

  int callCount = 0;
  PresensiRequest? lastRequest;
  PresensiResult? mockResult;
  Exception? mockError;
  Duration delay = Duration.zero;

  FakePresensiRepository({required this.apiClient});

  @override
  Future<PresensiResult> postPresensi(PresensiRequest request) async {
    callCount++;
    lastRequest = request;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (mockError != null) throw mockError!;
    return mockResult ??
        const PresensiResult(
          statusPresensi: 'Hadir',
          namaSholat: 'Subuh',
          jarakMeter: 24.5,
        );
  }
}

void main() {
  const testArgs = PresensiArgs(
    idJadwal: 'jadwal-subuh-01',
    namaSholat: 'Subuh',
    idMasjid: 'masjid-al-ikhlas-01',
    namaMasjid: 'Masjid Al-Ikhlas',
    latitude: -7.9666,
    longitude: 112.6326,
    radiusToleransi: 100,
  );

  late FakeLocationService fakeLocationService;
  late FakeMockLocationDetector fakeMockDetector;
  late FakePresensiRepository fakeRepository;
  late PresensiController controller;

  setUp(() {
    final fakeTokenStore = FakeTokenStore();
    fakeLocationService = FakeLocationService();
    fakeMockDetector = FakeMockLocationDetector(returnValue: false);
    fakeRepository = FakePresensiRepository(
      apiClient: ApiClient(tokenStore: fakeTokenStore),
    );
    controller = PresensiController(
      repository: fakeRepository,
      locationService: fakeLocationService,
      mockLocationDetector: fakeMockDetector,
    );
  });

  group('PresensiController - Batas Akurasi (Client-side validation)', () {
    test('akurasi tepat 50.0 meter DITERIMA dan lanjut mengirim request ke server', () async {
      fakeLocationService.customPosition = createTestPosition(accuracy: 50.0);

      await controller.mulai(testArgs);

      expect(controller.state.tahap, TahapPresensi.berhasil);
      expect(controller.state.akurasiSaatIni, 50.0);
      expect(fakeRepository.callCount, 1);
      expect(fakeRepository.lastRequest?.akurasiMeter, 50.0);
    });

    test('akurasi 50.1 meter DITOLAK lokal tanpa request ke server', () async {
      fakeLocationService.customPosition = createTestPosition(accuracy: 50.1);

      await controller.mulai(testArgs);

      expect(controller.state.tahap, TahapPresensi.akurasiKurang);
      expect(controller.state.akurasiSaatIni, 50.1);
      expect(
        controller.state.pesanError,
        contains('Akurasi GPS kurang baik (50 m)'),
      );
      // Dipastikan tidak ada request ke server
      expect(fakeRepository.callCount, 0);
    });
  });

  group('PresensiController - Deteksi Mock Location', () {
    test('isMocked dari geolocator dikirim true ke server', () async {
      fakeLocationService.customPosition = createTestPosition(isMocked: true);
      fakeMockDetector.returnValue = false;

      await controller.mulai(testArgs);

      expect(fakeRepository.callCount, 1);
      expect(fakeRepository.lastRequest?.isMockLocation, true);
    });

    test('isMockLocation dari safe_device dikirim true ke server', () async {
      fakeLocationService.customPosition = createTestPosition(isMocked: false);
      fakeMockDetector.returnValue = true; // safe_device deteksi mock

      await controller.mulai(testArgs);

      expect(fakeRepository.callCount, 1);
      expect(fakeRepository.lastRequest?.isMockLocation, true);
    });

    test('bukan mock location dikirim false ke server', () async {
      fakeLocationService.customPosition = createTestPosition(isMocked: false);
      fakeMockDetector.returnValue = false;

      await controller.mulai(testArgs);

      expect(fakeRepository.callCount, 1);
      expect(fakeRepository.lastRequest?.isMockLocation, false);
    });
  });

  group('PresensiController - Alur Izin & Layanan GPS', () {
    test('layanan GPS mati menghasilkan state gpsNonaktif', () async {
      fakeLocationService.serviceEnabled = false;

      await controller.mulai(testArgs);

      expect(controller.state.tahap, TahapPresensi.error);
      expect(controller.state.jenisError, JenisErrorPresensi.gpsNonaktif);
      expect(controller.state.pesanError, contains('Layanan lokasi (GPS) tidak aktif'));
      expect(fakeRepository.callCount, 0);
    });

    test('izin lokasi ditolak sementara menghasilkan state izinDitolak', () async {
      fakeLocationService.permissionStatus = LocationPermission.denied;
      fakeLocationService.requestResult = LocationPermission.denied;

      await controller.mulai(testArgs);

      expect(controller.state.tahap, TahapPresensi.error);
      expect(controller.state.jenisError, JenisErrorPresensi.izinDitolak);
      expect(
        controller.state.pesanError,
        'Aplikasi memerlukan lokasi untuk memastikan Anda berada di area masjid.',
      );
      expect(fakeRepository.callCount, 0);
    });

    test('izin lokasi ditolak permanen menghasilkan state izinPermanen', () async {
      fakeLocationService.permissionStatus = LocationPermission.deniedForever;

      await controller.mulai(testArgs);

      expect(controller.state.tahap, TahapPresensi.error);
      expect(controller.state.jenisError, JenisErrorPresensi.izinPermanen);
      expect(
        controller.state.pesanError,
        contains('Buka pengaturan aplikasi'),
      );
      expect(fakeRepository.callCount, 0);
    });
  });

  group('PresensiController - Sukses & Penanganan ERR_ALREADY_PRESENT', () {
    test('sukses membawa nama_sholat dan jarak_meter', () async {
      fakeRepository.mockResult = const PresensiResult(
        statusPresensi: 'Hadir',
        namaSholat: 'Subuh',
        jarakMeter: 18.7,
      );

      await controller.mulai(testArgs);

      expect(controller.state.tahap, TahapPresensi.berhasil);
      expect(controller.state.hasil?.namaSholat, 'Subuh');
      expect(controller.state.hasil?.jarakMeter, 18.7);
      expect(controller.state.hasil?.statusPresensi, 'Hadir');
    });

    test('ERR_ALREADY_PRESENT tidak menampilkan layar sukses melainkan tahap sudahPresensi netral', () async {
      fakeRepository.mockError = const AppException(
        code: 'ERR_ALREADY_PRESENT',
        message: 'Sudah presensi',
        status: 409,
      );

      await controller.mulai(testArgs);

      // BUKAN TahapPresensi.berhasil
      expect(controller.state.tahap, isNot(TahapPresensi.berhasil));
      expect(controller.state.tahap, TahapPresensi.sudahPresensi);
      expect(controller.state.pesanError, 'Anda sudah presensi untuk shalat ini.');
    });
  });

  group('PresensiController - Perlindungan Tekan Ganda (Double-tap protection)', () {
    test('tekan ganda hanya menjalankan 1 request ke server', () async {
      fakeRepository.delay = const Duration(milliseconds: 100);

      // Panggil mulai dua kali secara simultan
      final call1 = controller.mulai(testArgs);
      final call2 = controller.mulai(testArgs);

      await Future.wait([call1, call2]);

      expect(fakeRepository.callCount, 1);
    });
  });

  group('PresensiController - Aksi Tombol Pengaturan', () {
    test('bukaSettingAplikasi memanggil openAppSettings pada LocationService', () async {
      await controller.bukaSettingAplikasi();
      expect(fakeLocationService.appSettingsOpened, true);
    });

    test('bukaSettingLokasi memanggil openLocationSettings pada LocationService', () async {
      await controller.bukaSettingLokasi();
      expect(fakeLocationService.locationSettingsOpened, true);
    });
  });

  group('PresensiController - Keamanan Dispose', () {
    test('dispose saat GPS masih menunggu tidak crash dan tidak mengirim presensi', () async {
      final completer = Completer<Position>();
      fakeLocationService.positionCompleter = completer;

      final future = controller.mulai(testArgs);
      await Future<void>.delayed(Duration.zero);

      controller.dispose();
      completer.complete(createTestPosition(accuracy: 10.0));
      await future;

      expect(fakeRepository.callCount, 0);
    });
  });
}
