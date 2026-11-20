import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_jamaah/core/api_client/api_client.dart';
import 'package:geo_jamaah/features/admin/data/admin_repository.dart';
import 'package:geo_jamaah/features/admin/presentation/admin_screen.dart';
import 'package:geo_jamaah/features/auth/domain/auth_state.dart';
import 'package:geo_jamaah/features/auth/domain/user_model.dart';
import 'package:geo_jamaah/features/auth/presentation/auth_controller.dart';
import '../../helpers/test_fakes.dart';

Widget buildAdminScreenApp({
  required FakeAdminRepository fakeRepo,
  required AuthController authController,
}) {
  return ProviderScope(
    overrides: [
      adminRepositoryProvider.overrideWithValue(fakeRepo),
      authControllerProvider.overrideWith((ref) => authController),
    ],
    child: const MaterialApp(
      home: AdminScreen(),
    ),
  );
}

void main() {
  late FakeAdminRepository fakeRepo;
  late AuthController authController;

  setUp(() {
    final client = ApiClient(
      customDio: Dio(),
      tokenStore: FakeTokenStore(),
      baseUrl: 'http://localhost:3000',
    );
    fakeRepo = FakeAdminRepository(apiClient: client);

    final fakeAuthRepo = FakeAuthRepository(
      apiClient: client,
      tokenStore: FakeTokenStore(),
    );
    authController = AuthController(
      authRepository: fakeAuthRepo,
      deviceIdService: MockDeviceIdService(),
      autoRestore: false,
    );
    authController.state = AuthState.authenticated(
      user: const UserModel(
        idPengguna: 'adm-1',
        username: 'admin',
        role: 'Admin',
      ),
      token: 'jwt-token-admin',
    );
  });

  group('AdminScreen - Widget & Tab Navigation Test', () {
    testWidgets('menampilkan AppBar dan 3 item Bottom Navigation', (tester) async {
      await tester.pumpWidget(buildAdminScreenApp(
        fakeRepo: fakeRepo,
        authController: authController,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Admin Panel'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('Ringkasan'), findsOneWidget);
      expect(find.text('Log Aktivitas'), findsOneWidget);
      expect(find.text('Kelola'), findsOneWidget);
    });

    testWidgets('Tab 0: menampilkan kartu rekapitulasi dan tren kehadiran', (tester) async {
      await tester.pumpWidget(buildAdminScreenApp(
        fakeRepo: fakeRepo,
        authController: authController,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Santri Aktif'), findsOneWidget);
      expect(find.text('Santri Kritis (DSS)'), findsOneWidget);
      expect(find.text('Rekap Presensi (30 Hari)'), findsOneWidget);
      expect(find.text('Pengajuan Izin'), findsOneWidget);
      expect(find.text('Tren Kehadiran Global'), findsOneWidget);
    });

    testWidgets('Tab 1: navigasi ke Log Aktivitas menampilkan filter chip dan item log', (tester) async {
      await tester.pumpWidget(buildAdminScreenApp(
        fakeRepo: fakeRepo,
        authController: authController,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Pindah ke Tab 1 (Log Aktivitas)
      await tester.tap(find.text('Log Aktivitas'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.widgetWithText(FilterChip, 'Semua'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Auth'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Presensi'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Masjid'), findsOneWidget);

      // Verifikasi item log dari FakeAdminRepository
      expect(find.text('Mengubah radius toleransi masjid'), findsOneWidget);
      expect(find.text('Presensi Shubuh berhasil'), findsOneWidget);
    });

    testWidgets('Tab 2: navigasi ke Kelola menampilkan fitur aksi cepat', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildAdminScreenApp(
        fakeRepo: fakeRepo,
        authController: authController,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Pindah ke Tab 2 (Kelola)
      await tester.tap(find.text('Kelola'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Reset Device ID Mahasantri'), findsOneWidget);
      expect(find.text('NIM Mahasantri'), findsOneWidget);
      expect(find.text('Reset Ikatan Device'), findsOneWidget);

      expect(find.text('Pemicu Job Presensi Otomatis'), findsOneWidget);
      expect(find.text('Jalankan Hari Ini'), findsOneWidget);
      expect(find.text('Backfill Tanggal'), findsOneWidget);

      expect(find.text('Keluar dari Aplikasi'), findsOneWidget);
    });
  });
}
