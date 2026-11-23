import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_jamaah/core/api_client/api_client.dart';
import 'package:geo_jamaah/core/app_exception/app_exception.dart';
import 'package:geo_jamaah/core/token_store/token_store.dart';
import 'package:geo_jamaah/features/mahasantri/data/izin_repository.dart';
import 'package:geo_jamaah/features/mahasantri/domain/izin_model.dart';
import 'package:geo_jamaah/features/mahasantri/presentation/izin_screen.dart';

/// Fake TokenStore in-memory untuk widget test.
class FakeTokenStoreForWidget extends TokenStore {
  String? _token;
  Map<String, dynamic>? _user;
  @override
  Future<void> saveToken(String t) async => _token = t;
  @override
  Future<String?> getToken() async => _token;
  @override
  Future<void> deleteToken() async => _token = null;
  @override
  Future<void> saveUser(Map<String, dynamic> u) async => _user = u;
  @override
  Future<Map<String, dynamic>?> getUser() async => _user;
  @override
  Future<void> deleteUser() async => _user = null;
  @override
  Future<void> clear() async { _token = null; _user = null; }
}

/// Fake repository untuk widget test IzinScreen.
class FakeIzinRepositoryWidget extends IzinRepository {
  bool shouldFail = false;
  int callCount = 0;
  int loadCount = 0;
  List<IzinItem> mockDaftar = [];

  FakeIzinRepositoryWidget({required super.apiClient});

  @override
  Future<IzinResult> ajukanIzin(IzinRequest request) async {
    callCount++;
    if (shouldFail) {
      throw AppException(code: 'ERR_VALIDATION', message: 'Server error', status: 400);
    }
    return IzinResult(
      idIzin: 'uuid-izin', nim: '24050505050', jenisIzin: request.jenisIzin,
      tanggalIzin: '2026-10-05T00:00:00.000Z', alasan: request.alasan,
      buktiLampiran: null, statusPersetujuan: 'Pending',
    );
  }

  @override
  Future<List<IzinItem>> getIzinSaya() async {
    loadCount++;
    if (shouldFail) throw AppException(code: 'ERR_CONNECTION', message: 'Connection failed');
    return mockDaftar;
  }
}

void main() {
  testWidgets('form kosong menunjukkan 3 pesan validasi saat submit', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    final repo = FakeIzinRepositoryWidget(apiClient: ApiClient(tokenStore: FakeTokenStoreForWidget()));
    await tester.pumpWidget(ProviderScope(
      overrides: [izinRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: IzinScreen()),
    ));

    await tester.tap(find.text('Ajukan Izin'));
    await tester.pump();

    expect(find.text('Jenis izin wajib dipilih'), findsOneWidget);
    expect(find.text('Tanggal izin wajib diisi'), findsOneWidget);
    expect(find.text('Alasan wajib diisi'), findsOneWidget);
    expect(repo.callCount, 0);
  });

  testWidgets('form kosong tidak memanggil repository meski repo gagal', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    final repo = FakeIzinRepositoryWidget(apiClient: ApiClient(tokenStore: FakeTokenStoreForWidget()));
    repo.shouldFail = true;
    await tester.pumpWidget(ProviderScope(
      overrides: [izinRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: IzinScreen()),
    ));

    await tester.tap(find.text('Ajukan Izin'));
    await tester.pump();

    expect(repo.callCount, 0);
    expect(find.text('Jenis izin wajib dipilih'), findsOneWidget);
    expect(find.text('Tanggal izin wajib diisi'), findsOneWidget);
    expect(find.text('Alasan wajib diisi'), findsOneWidget);
  });

  testWidgets('otomatis memuat daftar izin saat layar dibuka', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repo = FakeIzinRepositoryWidget(apiClient: ApiClient(tokenStore: FakeTokenStoreForWidget()));
    repo.mockDaftar = const [
      IzinItem(
        idIzin: 'izin-1',
        nim: '24050505050',
        jenisIzin: 'Sakit',
        tanggalIzin: '2026-10-05T00:00:00.000Z',
        alasan: 'Demam tinggi',
        statusPersetujuan: 'Pending',
      ),
    ];

    await tester.pumpWidget(ProviderScope(
      overrides: [izinRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: IzinScreen()),
    ));
    await tester.pumpAndSettle();

    expect(repo.loadCount, 1);
    expect(find.text('Demam tinggi'), findsOneWidget);
  });
}
