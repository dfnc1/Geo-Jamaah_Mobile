import 'package:flutter_test/flutter_test.dart';
import 'package:geo_jamaah/core/api_client/api_client.dart';
import 'package:geo_jamaah/core/app_exception/app_exception.dart';
import 'package:geo_jamaah/core/services/device_id_service.dart';
import 'package:geo_jamaah/core/token_store/token_store.dart';
import 'package:geo_jamaah/features/auth/data/auth_repository.dart';
import 'package:geo_jamaah/features/auth/domain/auth_state.dart';
import 'package:geo_jamaah/features/auth/domain/user_model.dart';
import 'package:geo_jamaah/features/auth/presentation/auth_controller.dart';

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
  }
}

void main() {
  late MockDeviceIdService mockDeviceIdService;
  late FakeAuthRepository fakeAuthRepository;
  late TokenStore fakeTokenStore;

  setUp(() {
    mockDeviceIdService = MockDeviceIdService();
    fakeTokenStore = TokenStore();
    fakeAuthRepository = FakeAuthRepository(
      apiClient: ApiClient(tokenStore: fakeTokenStore),
      tokenStore: fakeTokenStore,
    );
  });

  group('AuthController - Validasi Form & Alur Login', () {
    test('validasi form gagal jika username kosong', () async {
      final controller = AuthController(
        authRepository: fakeAuthRepository,
        deviceIdService: mockDeviceIdService,
      );

      final success = await controller.login(
        username: '   ',
        password: 'password123',
      );

      expect(success, isFalse);
      expect(controller.state.status, equals(AuthStatus.unauthenticated));
      expect(controller.state.error?.message, equals('Username/NIM dan Password wajib diisi.'));
    });

    test('validasi form gagal jika password kosong', () async {
      final controller = AuthController(
        authRepository: fakeAuthRepository,
        deviceIdService: mockDeviceIdService,
      );

      final success = await controller.login(
        username: 'santri1',
        password: '',
      );

      expect(success, isFalse);
      expect(controller.state.status, equals(AuthStatus.unauthenticated));
      expect(controller.state.error?.message, equals('Username/NIM dan Password wajib diisi.'));
    });

    test('login gagal jika Device ID tidak terbaca dari perangkat', () async {
      mockDeviceIdService.deviceIdToReturn = null;

      final controller = AuthController(
        authRepository: fakeAuthRepository,
        deviceIdService: mockDeviceIdService,
      );

      final success = await controller.login(
        username: 'santri1',
        password: 'password123',
      );

      expect(success, isFalse);
      expect(controller.state.status, equals(AuthStatus.unauthenticated));
      expect(controller.state.error?.message, equals('Device ID tidak terbaca. Hubungi Admin.'));
    });

    test('login berhasil mengarahkan state ke authenticated dengan user dan token', () async {
      fakeAuthRepository.sessionData = (
        user: const UserModel(
          idPengguna: 'usr-001',
          username: 'ahmad_fauzi',
          role: 'Mahasantri',
          profil: {'nim': '24050505050', 'nama': 'Ahmad Fauzi'},
        ),
        token: 'access-token-12345'
      );

      final controller = AuthController(
        authRepository: fakeAuthRepository,
        deviceIdService: mockDeviceIdService,
      );

      final success = await controller.login(
        username: 'ahmad_fauzi',
        password: 'rahasia123',
      );

      expect(success, isTrue);
      expect(controller.state.status, equals(AuthStatus.authenticated));
      expect(controller.state.user?.username, equals('ahmad_fauzi'));
      expect(controller.state.user?.role, equals('Mahasantri'));
      expect(controller.state.token, equals('access-token-12345'));
      expect(controller.state.error, isNull);
    });

    test('login gagal menangkap AppException dan memetakan pesan error', () async {
      fakeAuthRepository.exceptionToThrow = const AppException(
        code: 'ERR_INVALID_CREDENTIALS',
        message: 'Invalid credentials',
        status: 401,
      );

      final controller = AuthController(
        authRepository: fakeAuthRepository,
        deviceIdService: mockDeviceIdService,
      );

      final success = await controller.login(
        username: 'ahmad_fauzi',
        password: 'wrongpassword',
      );

      expect(success, isFalse);
      expect(controller.state.status, equals(AuthStatus.unauthenticated));
      expect(controller.state.error?.title, equals('Tidak dapat masuk'));
      expect(
        controller.state.error?.message,
        equals('Username/NIM atau password salah. Periksa kembali data Anda.'),
      );
    });
  });

  group('AuthController - Pemulihan Sesi & Logout', () {
    test('memulihkan sesi yang tersimpan di storage saat startup', () async {
      fakeAuthRepository.sessionData = (
        user: const UserModel(
          idPengguna: 'usr-musyrif-1',
          username: 'ustadz_abdul',
          role: 'Musyrif',
        ),
        token: 'stored-jwt-token'
      );

      final controller = AuthController(
        authRepository: fakeAuthRepository,
        deviceIdService: mockDeviceIdService,
      );

      await controller.restoreSession();

      expect(controller.state.status, equals(AuthStatus.authenticated));
      expect(controller.state.user?.role, equals('Musyrif'));
      expect(controller.state.token, equals('stored-jwt-token'));
    });

    test('menjadi unauthenticated jika tidak ada sesi tersimpan', () async {
      fakeAuthRepository.sessionData = null;

      final controller = AuthController(
        authRepository: fakeAuthRepository,
        deviceIdService: mockDeviceIdService,
      );

      await controller.restoreSession();

      expect(controller.state.status, equals(AuthStatus.unauthenticated));
      expect(controller.state.user, isNull);
    });

    test('logout menghapus sesi dan mengembalikan status ke unauthenticated', () async {
      fakeAuthRepository.sessionData = (
        user: const UserModel(
          idPengguna: 'u1',
          username: 'santri1',
          role: 'Mahasantri',
        ),
        token: 'token'
      );

      final controller = AuthController(
        authRepository: fakeAuthRepository,
        deviceIdService: mockDeviceIdService,
      );

      await controller.restoreSession();
      expect(controller.state.status, equals(AuthStatus.authenticated));

      await controller.logout();
      expect(controller.state.status, equals(AuthStatus.unauthenticated));
      expect(controller.state.user, isNull);
    });

    test('handleSessionExpired menetapkan pesan sesi berakhir', () {
      final controller = AuthController(
        authRepository: fakeAuthRepository,
        deviceIdService: mockDeviceIdService,
      );

      controller.handleSessionExpired();

      expect(controller.state.status, equals(AuthStatus.unauthenticated));
      expect(controller.state.error?.message, equals('Sesi Anda telah berakhir. Silakan masuk kembali.'));
    });
  });
}
