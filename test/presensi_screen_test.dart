import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_jamaah/core/api_client/api_client.dart';
import 'package:geo_jamaah/features/presensi/data/presensi_repository.dart';
import 'package:geo_jamaah/features/presensi/domain/location_service.dart';
import 'package:geo_jamaah/features/presensi/domain/mock_location_detector.dart';
import 'package:geo_jamaah/features/presensi/domain/presensi_models.dart';
import 'package:geo_jamaah/features/presensi/presentation/presensi_controller.dart';
import 'package:geo_jamaah/features/presensi/presentation/presensi_screen.dart';
import 'api_client_test.dart';
import 'mock_location_detector_test.dart';
import 'presensi_controller_test.dart';

class TestPresensiController extends PresensiController {
  TestPresensiController({
    required super.repository,
    required super.locationService,
    required super.mockLocationDetector,
  });

  void setCustomState(PresensiState newState) {
    state = newState;
  }

  @override
  Future<void> mulai(PresensiArgs args) async {
    // Hindari pemanggilan platform native di widget test
  }

  @override
  Future<void> cobaLagi(PresensiArgs args) async {
    // No-op untuk widget test
  }
}

void main() {
  const testArgs = PresensiArgs(
    idJadwal: 'jadwal-subuh-uuid',
    namaSholat: 'Subuh',
    idMasjid: 'masjid-al-ikhlas-uuid',
    namaMasjid: 'Masjid Al-Ikhlas',
    latitude: -7.9666,
    longitude: 112.6326,
    radiusToleransi: 100,
  );

  late FakePresensiRepository fakeRepository;
  late FakeLocationService fakeLocationService;
  late FakeMockLocationDetector fakeMockDetector;
  late TestPresensiController testController;

  setUp(() {
    final fakeTokenStore = FakeTokenStore();
    fakeRepository = FakePresensiRepository(
      apiClient: ApiClient(tokenStore: fakeTokenStore),
    );
    fakeLocationService = FakeLocationService();
    fakeMockDetector = FakeMockLocationDetector();
    testController = TestPresensiController(
      repository: fakeRepository,
      locationService: fakeLocationService,
      mockLocationDetector: fakeMockDetector,
    );
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        presensiRepositoryProvider.overrideWithValue(fakeRepository),
        locationServiceProvider.overrideWithValue(fakeLocationService),
        mockLocationDetectorProvider.overrideWithValue(fakeMockDetector),
        presensiControllerProvider.overrideWith((ref) => testController),
      ],
      child: const MaterialApp(
        home: PresensiScreen(args: testArgs),
      ),
    );
  }

  group('PresensiScreen - UI Berdasarkan Tahap Alur M4', () {
    testWidgets('menampilkan judul appBar dengan nama shalat', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Presensi Subuh'), findsOneWidget);
    });

    testWidgets('tahap ambilPosisi menampilkan indikator dan akurasi saat ini',
        (tester) async {
      testController.setCustomState(
        const PresensiState(
          tahap: TahapPresensi.ambilPosisi,
          akurasiSaatIni: 18.0,
        ),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Mengambil lokasi...'), findsOneWidget);
      expect(find.text('Akurasi saat ini: 18 m'), findsOneWidget);
      expect(
        find.text(
          'Aplikasi memerlukan lokasi untuk memastikan\nAnda berada di area masjid.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'tahap akurasiKurang (>50m) menampilkan peringatan dan tombol ambil ulang',
        (tester) async {
      testController.setCustomState(
        const PresensiState(
          tahap: TahapPresensi.akurasiKurang,
          akurasiSaatIni: 65.0,
          pesanError:
              'Akurasi GPS kurang baik (65 m).\nPindah ke area terbuka lalu coba lagi.',
        ),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Akurasi GPS Kurang Baik'), findsOneWidget);
      expect(
        find.text(
          'Akurasi GPS kurang baik (65 m).\nPindah ke area terbuka lalu coba lagi.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ambil Ulang Lokasi'), findsOneWidget);
    });

    testWidgets(
        'tahap berhasil menampilkan status, jarak meter, dan tombol kembali',
        (tester) async {
      testController.setCustomState(
        const PresensiState(
          tahap: TahapPresensi.berhasil,
          hasil: PresensiResult(
            statusPresensi: 'Hadir',
            namaSholat: 'Subuh',
            jarakMeter: 32.7,
          ),
        ),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Presensi Berhasil!'), findsOneWidget);
      expect(find.text('32.7 m'), findsOneWidget);
      expect(find.text('Hadir'), findsOneWidget);
      expect(find.text('Kembali ke Beranda'), findsOneWidget);
    });

    testWidgets(
        'tahap sudahPresensi menampilkan kartu netral dan BUKAN Presensi Berhasil',
        (tester) async {
      testController.setCustomState(
        const PresensiState(
          tahap: TahapPresensi.sudahPresensi,
          pesanError: 'Anda sudah presensi untuk shalat ini.',
        ),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      // Memastikan BUKAN 'Presensi Berhasil!'
      expect(find.text('Presensi Berhasil!'), findsNothing);
      expect(find.text('Sudah Presensi'), findsOneWidget);
      expect(find.text('Anda sudah presensi untuk shalat ini.'), findsOneWidget);
      expect(find.text('Kembali ke Beranda'), findsOneWidget);
    });

    testWidgets('error izinDitolak menampilkan tombol Coba Lagi',
        (tester) async {
      testController.setCustomState(
        const PresensiState(
          tahap: TahapPresensi.error,
          jenisError: JenisErrorPresensi.izinDitolak,
          pesanError: 'Aplikasi memerlukan lokasi untuk memastikan Anda berada di area masjid.',
        ),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Izin Lokasi Diperlukan'), findsOneWidget);
      expect(
        find.text('Aplikasi memerlukan lokasi untuk memastikan Anda berada di area masjid.'),
        findsOneWidget,
      );
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('error izinPermanen menampilkan tombol Buka Pengaturan',
        (tester) async {
      testController.setCustomState(
        const PresensiState(
          tahap: TahapPresensi.error,
          jenisError: JenisErrorPresensi.izinPermanen,
          pesanError: 'Izin lokasi diblokir secara permanen.',
        ),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Izin Lokasi Diblokir'), findsOneWidget);
      expect(find.text('Buka Pengaturan'), findsOneWidget);
    });

    testWidgets('error gpsNonaktif menampilkan tombol Buka Pengaturan Lokasi',
        (tester) async {
      testController.setCustomState(
        const PresensiState(
          tahap: TahapPresensi.error,
          jenisError: JenisErrorPresensi.gpsNonaktif,
          pesanError: 'Layanan lokasi (GPS) tidak aktif.',
        ),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('GPS Tidak Aktif'), findsOneWidget);
      expect(find.text('Buka Pengaturan Lokasi'), findsOneWidget);
    });
  });
}
