import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geo_jamaah/core/api_client/api_client.dart';
import 'package:geo_jamaah/core/app_exception/app_exception.dart';
import 'package:geo_jamaah/core/services/device_id_service.dart';
import 'package:geo_jamaah/core/token_store/token_store.dart';
import 'package:geo_jamaah/features/admin/data/admin_repository.dart';
import 'package:geo_jamaah/features/admin/domain/admin_models.dart';
import 'package:geo_jamaah/features/auth/data/auth_repository.dart';
import 'package:geo_jamaah/features/auth/domain/user_model.dart';
import 'package:geo_jamaah/features/mahasantri/data/mahasantri_repository.dart';
import 'package:geo_jamaah/features/mahasantri/domain/presensi_hari_ini_model.dart';
import 'package:geo_jamaah/features/musyrif/data/izin_musyrif_repository.dart';
import 'package:geo_jamaah/features/musyrif/domain/izin_musyrif_model.dart';
import 'package:geo_jamaah/features/musyrif/domain/musyrif_models.dart';
import 'package:geo_jamaah/features/presensi/data/presensi_repository.dart';
import 'package:geo_jamaah/features/presensi/domain/location_service.dart';
import 'package:geo_jamaah/features/presensi/domain/mock_location_detector.dart';
import 'package:geo_jamaah/features/presensi/domain/presensi_models.dart';

// =============================================================================
// Helper Geolocation
// =============================================================================

Position createTestPosition({
  double latitude = -7.9666,
  double longitude = 112.6326,
  double accuracy = 15.0,
  bool isMocked = false,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.now(),
    accuracy: accuracy,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
    isMocked: isMocked,
  );
}

// =============================================================================
// Mock Http Adapter & Token Store
// =============================================================================

class MockHttpAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  MockHttpAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

class FakeTokenStore extends TokenStore {
  String? _token;
  Map<String, dynamic>? _user;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> deleteToken() async => _token = null;

  @override
  Future<void> saveUser(Map<String, dynamic> user) async => _user = user;

  @override
  Future<Map<String, dynamic>?> getUser() async => _user;

  @override
  Future<void> deleteUser() async => _user = null;

  @override
  Future<void> clear() async {
    _token = null;
    _user = null;
  }
}

// =============================================================================
// Fake Auth & Device ID Service
// =============================================================================

class MockDeviceIdService implements DeviceIdService {
  String? deviceIdToReturn = 'test-android-device-123';

  @override
  Future<String?> getDeviceId() async => deviceIdToReturn;
}

class FakeAuthRepository extends AuthRepository {
  ({UserModel user, String token})? sessionData;
  AppException? exceptionToThrow;

  FakeAuthRepository({
    required super.apiClient,
    required super.tokenStore,
  });

  @override
  Future<({UserModel user, String token})> login({
    required String username,
    required String password,
    required String deviceId,
  }) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return sessionData ??
        (
          user: const UserModel(
            idPengguna: 'u1',
            username: 'santri1',
            role: 'Mahasantri',
          ),
          token: 'dummy-jwt-token'
        );
  }

  @override
  Future<({UserModel user, String token})?> restoreSession() async {
    return sessionData;
  }

  @override
  Future<void> logout() async {
    sessionData = null;
    await tokenStore.clear();
  }
}

// =============================================================================
// Fake Location & Mock Location Detector
// =============================================================================

class FakeMockLocationDetector implements MockLocationDetector {
  bool returnValue;
  FakeMockLocationDetector({this.returnValue = false});

  @override
  Future<bool> isMockLocation(Position position) async => returnValue;
}

class FakeLocationService implements LocationService {
  bool serviceEnabled = true;
  LocationPermission permissionStatus = LocationPermission.whileInUse;
  LocationPermission requestResult = LocationPermission.whileInUse;
  Position? customPosition;
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

// =============================================================================
// Fake Repositories
// =============================================================================

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
    if (mockError != null) {
      throw mockError!;
    }
    return mockResult ??
        const PresensiResult(
          statusPresensi: 'Hadir',
          namaSholat: 'Shubuh',
          jarakMeter: 25.5,
        );
  }
}

class FakeMahasantriRepository implements MahasantriRepository {
  @override
  final ApiClient apiClient;

  PresensiHariIniResponse? mockResponse;
  AppException? mockError;

  FakeMahasantriRepository({required this.apiClient});

  @override
  Future<PresensiHariIniResponse> getPresensiHariIni() async {
    if (mockError != null) throw mockError!;
    return mockResponse ??
        const PresensiHariIniResponse(
          tanggal: '2026-10-18',
          masjid: MasjidModel(
            idMasjid: 'm1',
            namaMasjid: 'Masjid Al-Awwabin',
            radiusToleransi: 100,
            latitude: -7.9666,
            longitude: 112.6326,
          ),
          jadwal: [],
        );
  }
}

class FakeIzinMusyrifRepository extends IzinMusyrifRepository {
  List<IzinMusyrifItem> daftar = [];
  AppException? error;
  String? lastStatusBaru;
  String? lastIdIzin;

  FakeIzinMusyrifRepository({required super.apiClient});

  @override
  Future<List<IzinMusyrifItem>> getIzinBinaan({String? status}) async {
    if (error != null) throw error!;
    return daftar.where((i) {
      if (status == null) return true;
      return i.statusPersetujuan == status;
    }).toList();
  }

  @override
  Future<IzinMusyrifItem> verifikasiIzin({
    required String idIzin,
    required String statusBaru,
  }) async {
    lastIdIzin = idIzin;
    lastStatusBaru = statusBaru;
    if (error != null) throw error!;
    final idx = daftar.indexWhere((i) => i.idIzin == idIzin);
    if (idx == -1) {
      throw AppException(
        code: 'ERR_IZIN_NOT_FOUND',
        message: 'Izin tidak ditemukan',
        status: 404,
      );
    }
    final baru = IzinMusyrifItem(
      idIzin: daftar[idx].idIzin,
      nim: daftar[idx].nim,
      namaMahasantri: daftar[idx].namaMahasantri,
      jenisIzin: daftar[idx].jenisIzin,
      tanggalIzin: daftar[idx].tanggalIzin,
      alasan: daftar[idx].alasan,
      buktiLampiran: daftar[idx].buktiLampiran,
      statusPersetujuan: statusBaru,
    );
    daftar[idx] = baru;
    return baru;
  }
}

class FakeAdminRepository extends AdminRepository {
  AdminRekap? mockRekap;
  TrenKehadiranResponse? mockTren;
  ActivityLogResponse? mockLogs;
  ResetDeviceResult? mockResetResult;
  JobTandaiResult? mockJobResult;

  AppException? errorToThrow;
  int getRekapCalls = 0;
  int getTrenCalls = 0;
  int getLogsCalls = 0;
  int resetDeviceCalls = 0;
  int triggerJobCalls = 0;

  String? lastResetNim;
  String? lastJobTanggal;
  String? lastJobIdJadwal;
  String? lastLogModul;

  FakeAdminRepository({required super.apiClient});

  @override
  Future<AdminRekap> getRekap() async {
    getRekapCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return mockRekap ??
        const AdminRekap(
          jumlahSantriAktif: 15,
          jumlahSantriKritis: 2,
          presensi: PresensiRekap(
            hadir: 200,
            tidakHadir: 20,
            izin: 10,
            manual: 5,
            total: 235,
          ),
          izin: IzinRekap(
            pending: 3,
            disetujui: 15,
            ditolak: 2,
            total: 20,
          ),
        );
  }

  @override
  Future<TrenKehadiranResponse> getTrenKehadiran({int hari = 7}) async {
    getTrenCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return mockTren ??
        TrenKehadiranResponse(
          hari: hari,
          tanggalMulai: '2026-10-12',
          tanggalAkhir: '2026-10-18',
          data: const [
            TrenHarian(
              tanggal: '2026-10-17',
              hadir: 15,
              tidakHadir: 3,
              izin: 2,
              manual: 0,
              total: 20,
              persenHadir: 75.0,
            ),
            TrenHarian(
              tanggal: '2026-10-18',
              hadir: 18,
              tidakHadir: 1,
              izin: 1,
              manual: 0,
              total: 20,
              persenHadir: 90.0,
            ),
          ],
        );
  }

  @override
  Future<ActivityLogResponse> getActivityLogs({
    int page = 1,
    int limit = 20,
    String? modul,
    String? role,
    String? from,
    String? to,
  }) async {
    getLogsCalls++;
    lastLogModul = modul;
    if (errorToThrow != null) throw errorToThrow!;
    return mockLogs ??
        const ActivityLogResponse(
          logs: [
            ActivityLogItem(
              idLog: 'log-1',
              username: 'admin',
              role: 'Admin',
              modul: 'Masjid',
              aktivitas: 'Mengubah radius toleransi masjid',
              createdAt: '2026-10-18T10:00:00.000Z',
            ),
            ActivityLogItem(
              idLog: 'log-2',
              username: 'santri1',
              role: 'Mahasantri',
              modul: 'Presensi',
              aktivitas: 'Presensi Shubuh berhasil',
              createdAt: '2026-10-18T05:00:00.000Z',
            ),
          ],
          page: 1,
          limit: 20,
          total: 2,
          totalPages: 1,
        );
  }

  @override
  Future<ResetDeviceResult> resetDevice(String nim) async {
    resetDeviceCalls++;
    lastResetNim = nim;
    if (errorToThrow != null) throw errorToThrow!;
    return mockResetResult ??
        ResetDeviceResult(
          nim: nim,
          nama: 'Santri Uji Coba',
          username: 'santri_uji',
          deviceId: null,
        );
  }

  @override
  Future<JobTandaiResult> triggerJobTandai({String? tanggal, String? idJadwal}) async {
    triggerJobCalls++;
    lastJobTanggal = tanggal;
    lastJobIdJadwal = idJadwal;
    if (errorToThrow != null) throw errorToThrow!;
    return mockJobResult ??
        JobTandaiResult(
          tanggal: tanggal ?? '2026-10-18',
          idJadwal: idJadwal,
          tidakHadir: 4,
          izin: 1,
          totalDibuat: 5,
        );
  }
}
