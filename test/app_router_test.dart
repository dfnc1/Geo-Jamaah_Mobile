import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_jamaah/core/api_client/api_client.dart';
import 'package:geo_jamaah/core/routing/app_router.dart';
import 'package:geo_jamaah/features/auth/domain/auth_state.dart';
import 'package:geo_jamaah/features/auth/domain/user_model.dart';
import 'package:geo_jamaah/features/auth/presentation/auth_controller.dart';
import 'api_client_test.dart';
import 'auth_controller_test.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late MockDeviceIdService mockDeviceIdService;
  late FakeTokenStore fakeTokenStore;

  setUp(() {
    fakeTokenStore = FakeTokenStore();
    final fakeApiClient = ApiClient(tokenStore: fakeTokenStore);
    mockDeviceIdService = MockDeviceIdService();
    fakeAuthRepository = FakeAuthRepository(
      apiClient: fakeApiClient,
      tokenStore: fakeTokenStore,
    );
  });

  Widget buildTestApp({required AuthController controller}) {
    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((ref) => controller),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(appRouterProvider);
          return MaterialApp.router(
            routerConfig: router,
          );
        },
      ),
    );
  }

  group('AppRouter - Pemilihan Rute per Peran & Proteksi Halaman', () {
    testWidgets('status initial menampilkan rute splash', (tester) async {
      final controller = AuthController(
        authRepository: fakeAuthRepository,
        deviceIdService: mockDeviceIdService,
        autoRestore: false,
      );
      controller.state = AuthState.initial();

      await tester.pumpWidget(buildTestApp(controller: controller));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('status unauthenticated selalu diarahkan ke layar /login', (tester) async {
      final controller = AuthController(
        authRepository: fakeAuthRepository,
        deviceIdService: mockDeviceIdService,
        autoRestore: false,
      );
      controller.state = AuthState.unauthenticated();

      await tester.pumpWidget(buildTestApp(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('PORTAL MAHASANTRI'), findsOneWidget);
      expect(find.text('Masuk Akun'), findsOneWidget);
    });

    testWidgets('peran Mahasantri diarahkan ke /mahasantri', (tester) async {
      final controller = AuthController(
        authRepository: fakeAuthRepository,
        deviceIdService: mockDeviceIdService,
        autoRestore: false,
      );
      controller.state = AuthState.authenticated(
        user: const UserModel(
          idPengguna: 'mhs-1',
          username: 'santri_andi',
          role: 'Mahasantri',
          profil: {'nama': 'Andi Pratama', 'nim': '2405001'},
        ),
        token: 'token-mhs',
      );

      await tester.pumpWidget(buildTestApp(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('Beranda Mahasantri'), findsOneWidget);
      expect(find.text('Andi Pratama'), findsOneWidget);
      expect(find.text('NIM: 2405001 · Kamar: -'), findsOneWidget);
    });

    testWidgets('peran Musyrif diarahkan ke /musyrif', (tester) async {
      final controller = AuthController(
        authRepository: fakeAuthRepository,
        deviceIdService: mockDeviceIdService,
        autoRestore: false,
      );
      controller.state = AuthState.authenticated(
        user: const UserModel(
          idPengguna: 'msy-1',
          username: 'ustadz_ahmad',
          role: 'Musyrif',
          profil: {'nama': 'Ustadz Ahmad', 'no_telepon': '08123456789'},
        ),
        token: 'token-msy',
      );

      await tester.pumpWidget(buildTestApp(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('Portal Musyrif'), findsOneWidget);
      expect(find.text('Ustadz Ahmad'), findsOneWidget);
      expect(find.text('Kontak: 08123456789'), findsOneWidget);
    });

    testWidgets('peran Admin diarahkan ke halaman belum tersedia /admin', (tester) async {
      final controller = AuthController(
        authRepository: fakeAuthRepository,
        deviceIdService: mockDeviceIdService,
        autoRestore: false,
      );
      controller.state = AuthState.authenticated(
        user: const UserModel(
          idPengguna: 'adm-1',
          username: 'admin',
          role: 'Admin',
        ),
        token: 'token-adm',
      );

      await tester.pumpWidget(buildTestApp(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('Admin Panel'), findsOneWidget);
      expect(
        find.text('Peran Admin belum tersedia di aplikasi mobile'),
        findsOneWidget,
      );
    });

    testWidgets('pengguna terautentikasi dicegah membuka /login', (tester) async {
      final controller = AuthController(
        authRepository: fakeAuthRepository,
        deviceIdService: mockDeviceIdService,
        autoRestore: false,
      );
      controller.state = AuthState.authenticated(
        user: const UserModel(
          idPengguna: 'mhs-1',
          username: 'santri_andi',
          role: 'Mahasantri',
        ),
        token: 'token-mhs',
      );

      await tester.pumpWidget(buildTestApp(controller: controller));
      await tester.pumpAndSettle();

      // Memastikan tetap di /mahasantri bukan di /login
      expect(find.text('Beranda Mahasantri'), findsOneWidget);
      expect(find.text('PORTAL MAHASANTRI'), findsNothing);
    });
  });
}
