import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/app_exception/app_exception.dart';
import '../data/presensi_repository.dart';
import '../domain/location_service.dart';
import '../domain/mock_location_detector.dart';
import '../domain/presensi_error_mapper.dart';
import '../domain/presensi_models.dart';

/// Batas akurasi GPS yang diterima aplikasi sebelum mengirim ke server (dalam meter).
/// 50.0 diterima, > 50.0 (misal 50.1) ditolak lokal tanpa request ke server.
const double kMaxAkurasiMeter = 50.0;

/// Batas waktu pengambilan posisi GPS (20 detik).
const Duration kGpsTimeout = Duration(seconds: 20);

/// Tahap-tahap alur presensi.
enum TahapPresensi {
  /// Memeriksa dan meminta izin lokasi.
  periksaIzin,

  /// Sedang mengambil posisi GPS.
  ambilPosisi,

  /// Akurasi GPS kurang (> 50 m) — meminta pengguna pindah ke area terbuka.
  akurasiKurang,

  /// Sedang mengirim data ke server.
  mengirim,

  /// Presensi berhasil dicatat server.
  berhasil,

  /// Mahasantri sudah presensi untuk shalat ini (ERR_ALREADY_PRESENT).
  /// Ditampilkan netral, bukan layar sukses.
  sudahPresensi,

  /// Terjadi error (izin ditolak, GPS mati, timeout, server error, dsb.).
  error,
}

/// Jenis error pada alur presensi (untuk menentukan tombol pemulihan di UI).
enum JenisErrorPresensi {
  /// Izin ditolak sementara (bisa diminta lagi dengan tombol "Coba Lagi").
  izinDitolak,

  /// Izin ditolak permanen (harus buka pengaturan aplikasi).
  izinPermanen,

  /// GPS / layanan lokasi dimatikan (harus buka pengaturan lokasi).
  gpsNonaktif,

  /// Timeout atau gagal mengambil koordinat GPS.
  gpsGagal,

  /// Error lainnya dari server atau jaringan.
  lainnya,
}

class PresensiState {
  final TahapPresensi tahap;
  final JenisErrorPresensi? jenisError;

  /// Akurasi GPS saat ini dalam meter (null = belum diketahui).
  final double? akurasiSaatIni;

  /// Pesan error ramah pengguna yang siap ditampilkan di UI.
  final String? pesanError;

  /// Hasil presensi jika [tahap] == [TahapPresensi.berhasil].
  final PresensiResult? hasil;

  const PresensiState({
    this.tahap = TahapPresensi.periksaIzin,
    this.jenisError,
    this.akurasiSaatIni,
    this.pesanError,
    this.hasil,
  });

  PresensiState copyWith({
    TahapPresensi? tahap,
    JenisErrorPresensi? jenisError,
    bool clearError = false,
    double? akurasiSaatIni,
    bool clearAkurasi = false,
    String? pesanError,
    PresensiResult? hasil,
  }) {
    return PresensiState(
      tahap: tahap ?? this.tahap,
      jenisError: clearError ? null : (jenisError ?? this.jenisError),
      akurasiSaatIni:
          clearAkurasi ? null : (akurasiSaatIni ?? this.akurasiSaatIni),
      pesanError: clearError ? null : (pesanError ?? this.pesanError),
      hasil: hasil ?? this.hasil,
    );
  }
}

/// Parameter wajib dari beranda untuk layar presensi.
class PresensiArgs {
  final String idJadwal;
  final String namaSholat;
  final String idMasjid;
  final String namaMasjid;
  final double latitude;
  final double longitude;
  final int radiusToleransi;

  const PresensiArgs({
    required this.idJadwal,
    required this.namaSholat,
    required this.idMasjid,
    required this.namaMasjid,
    required this.latitude,
    required this.longitude,
    required this.radiusToleransi,
  });
}

final presensiControllerProvider =
    StateNotifierProvider.autoDispose<PresensiController, PresensiState>((ref) {
  final repository = ref.watch(presensiRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider);
  final mockLocationDetector = ref.watch(mockLocationDetectorProvider);
  return PresensiController(
    repository: repository,
    locationService: locationService,
    mockLocationDetector: mockLocationDetector,
  );
});

class PresensiController extends StateNotifier<PresensiState> {
  final PresensiRepository repository;
  final LocationService locationService;
  final MockLocationDetector mockLocationDetector;

  /// Perlindungan tekan ganda internal controller (double-tap protection).
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  PresensiController({
    required this.repository,
    required this.locationService,
    required this.mockLocationDetector,
  }) : super(const PresensiState());

  // ── Alur Utama ──────────────────────────────────────────────────────────

  /// Memulai alur presensi: periksa izin -> ambil GPS -> kirim.
  /// Dilindungi dari penekanan ganda (double-tap).
  Future<void> mulai(PresensiArgs args) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      state = const PresensiState(tahap: TahapPresensi.periksaIzin);
      await _periksaIzin(args);
    } finally {
      _isProcessing = false;
    }
  }

  /// Dipanggil saat pengguna menekan "Coba Lagi" / "Ambil Ulang Lokasi".
  Future<void> cobaLagi(PresensiArgs args) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      state = state.copyWith(
        tahap: TahapPresensi.periksaIzin,
        clearError: true,
        clearAkurasi: true,
      );
      await _periksaIzin(args);
    } finally {
      _isProcessing = false;
    }
  }

  // ── Tahap 1: Periksa & Minta Izin ───────────────────────────────────────

  Future<void> _periksaIzin(PresensiArgs args) async {
    final serviceEnabled = await locationService.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      state = state.copyWith(
        tahap: TahapPresensi.error,
        jenisError: JenisErrorPresensi.gpsNonaktif,
        pesanError:
            'Layanan lokasi (GPS) tidak aktif. Aktifkan GPS lalu coba lagi.',
      );
      return;
    }

    LocationPermission permission = await locationService.checkPermission();
    if (!mounted) return;

    if (permission == LocationPermission.denied) {
      permission = await locationService.requestPermission();
      if (!mounted) return;
    }

    if (permission == LocationPermission.denied) {
      state = state.copyWith(
        tahap: TahapPresensi.error,
        jenisError: JenisErrorPresensi.izinDitolak,
        pesanError:
            'Aplikasi memerlukan lokasi untuk memastikan Anda berada di area masjid.',
      );
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        tahap: TahapPresensi.error,
        jenisError: JenisErrorPresensi.izinPermanen,
        pesanError:
            'Izin lokasi diblokir secara permanen. Buka pengaturan aplikasi untuk mengizinkan akses lokasi.',
      );
      return;
    }

    await _ambilPosisi(args);
  }

  Future<void> _ambilPosisi(PresensiArgs args) async {
    if (!mounted) return;
    state = state.copyWith(
      tahap: TahapPresensi.ambilPosisi,
      clearError: true,
    );

    try {
      final position = await locationService.getCurrentPosition(
        accuracy: LocationAccuracy.high,
        timeLimit: kGpsTimeout,
      );
      if (!mounted) return;

      final akurasi = position.accuracy;
      state = state.copyWith(akurasiSaatIni: akurasi);

      if (akurasi > kMaxAkurasiMeter) {
        state = state.copyWith(
          tahap: TahapPresensi.akurasiKurang,
          pesanError:
              'Akurasi GPS kurang baik (${akurasi.toStringAsFixed(0)} m). Pindah ke area terbuka lalu coba lagi.',
        );
        return;
      }

      final isMock = await mockLocationDetector.isMockLocation(position);
      if (!mounted) return;

      await _kirimPresensi(position, isMock, args);
    } on LocationServiceDisabledException {
      if (!mounted) return;
      state = state.copyWith(
        tahap: TahapPresensi.error,
        jenisError: JenisErrorPresensi.gpsNonaktif,
        pesanError:
            'Layanan lokasi dimatikan saat mengambil posisi. Aktifkan GPS lalu coba lagi.',
      );
    } on PermissionDeniedException {
      if (!mounted) return;
      state = state.copyWith(
        tahap: TahapPresensi.error,
        jenisError: JenisErrorPresensi.izinDitolak,
        pesanError:
            'Izin lokasi dicabut saat mengambil posisi. Coba lagi untuk memberikan izin.',
      );
    } on TimeoutException {
      if (!mounted) return;
      state = state.copyWith(
        tahap: TahapPresensi.error,
        jenisError: JenisErrorPresensi.gpsGagal,
        pesanError:
            'Pengambilan lokasi melebihi batas waktu (${kGpsTimeout.inSeconds} detik). Pindah ke area dengan sinyal GPS lebih baik lalu coba lagi.',
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        tahap: TahapPresensi.error,
        jenisError: JenisErrorPresensi.gpsGagal,
        pesanError: 'Gagal mengambil posisi GPS. Silakan coba lagi.',
      );
    }
  }

  Future<void> _kirimPresensi(
    Position position,
    bool isMock,
    PresensiArgs args,
  ) async {
    if (!mounted) return;
    state = state.copyWith(tahap: TahapPresensi.mengirim);

    try {
      final request = PresensiRequest(
        idJadwal: args.idJadwal,
        idMasjid: args.idMasjid,
        latitudeUser: position.latitude,
        longitudeUser: position.longitude,
        akurasiMeter: position.accuracy,
        isMockLocation: isMock,
      );

      final hasil = await repository.postPresensi(request);
      if (!mounted) return;
      state = state.copyWith(tahap: TahapPresensi.berhasil, hasil: hasil);
    } on AppException catch (e) {
      if (!mounted) return;
      if (e.code == 'ERR_ALREADY_PRESENT') {
        state = state.copyWith(
          tahap: TahapPresensi.sudahPresensi,
          pesanError: 'Anda sudah presensi untuk shalat ini.',
        );
      } else {
        state = state.copyWith(
          tahap: TahapPresensi.error,
          jenisError: JenisErrorPresensi.lainnya,
          pesanError: PresensiErrorMapper.map(e),
        );
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        tahap: TahapPresensi.error,
        jenisError: JenisErrorPresensi.lainnya,
        pesanError: PresensiErrorMapper.map(e),
      );
    }
  }

  // ── Aksi Tombol Pengaturan ───────────────────────────────────────────────

  Future<void> bukaSettingAplikasi() async {
    await locationService.openAppSettings();
  }

  Future<void> bukaSettingLokasi() async {
    await locationService.openLocationSettings();
  }
}
