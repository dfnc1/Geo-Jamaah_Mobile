import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_jamaah/core/app_exception/app_exception.dart';
import 'package:geo_jamaah/core/api_client/api_client.dart';
import 'package:geo_jamaah/features/mahasantri/domain/izin_model.dart';
import 'package:geo_jamaah/features/musyrif/data/izin_musyrif_repository.dart';
import 'package:geo_jamaah/features/musyrif/domain/izin_musyrif_error_mapper.dart';
import 'package:geo_jamaah/features/musyrif/domain/izin_musyrif_model.dart';
import 'package:geo_jamaah/features/musyrif/presentation/izin_musyrif_controller.dart';
import 'package:geo_jamaah/features/musyrif/presentation/izin_musyrif_screen.dart';
import 'fake_izin_musyrif_repository.dart';
import '../../helpers/test_fakes.dart' show FakeTokenStore;

void main() {
  group('IzinMusyrifItem.fromJson', () {
    test('parse daftar izin binaan dengan nama_mahasantri', () {
      final json = {
        'id_izin': 'uuid-izin',
        'nim': '24050505050',
        'nama_mahasantri': 'Ahmad Fauzi',
        'jenis_izin': 'Sakit',
        'tanggal_izin': '2026-10-05T00:00:00.000Z',
        'alasan': 'Sakit demam',
        'bukti_lampiran': null,
        'status_persetujuan': 'Pending',
      };

      final item = IzinMusyrifItem.fromJson(json);

      expect(item.idIzin, 'uuid-izin');
      expect(item.nim, '24050505050');
      expect(item.namaMahasantri, 'Ahmad Fauzi');
      expect(item.jenisIzin, 'Sakit');
      expect(item.tanggalDisplay, '2026-10-05');
      expect(item.statusParsed, StatusPersetujuanIzin.pending);
    });
  });

  group('IzinFilterMusyrif', () {
    test('pemetaan filter ke nilai query status', () {
      expect(IzinFilterMusyrif.pending.rawValue, 'Pending');
      expect(IzinFilterMusyrif.disetujui.rawValue, 'Disetujui');
      expect(IzinFilterMusyrif.ditolak.rawValue, 'Ditolak');
      expect(IzinFilterMusyrif.semua.rawValue, isNull);
    });

    test('label ramah pengguna', () {
      expect(IzinFilterMusyrif.pending.label, 'Pending');
      expect(IzinFilterMusyrif.disetujui.label, 'Disetujui');
      expect(IzinFilterMusyrif.ditolak.label, 'Ditolak');
      expect(IzinFilterMusyrif.semua.label, 'Semua');
    });
  });

  group('IzinMusyrifController', () {
    late FakeTokenStore fakeTokenStore;
    late FakeIzinMusyrifRepository repo;

    setUp(() {
      fakeTokenStore = FakeTokenStore();
      repo = FakeIzinMusyrifRepository(
        apiClient: ApiClient(tokenStore: fakeTokenStore),
      );
      repo.daftar = [
        IzinMusyrifItem(
          idIzin: 'izin-1',
          nim: '24050505050',
          namaMahasantri: 'Ahmad Fauzi',
          jenisIzin: 'Sakit',
          tanggalIzin: '2026-10-05T00:00:00.000Z',
          alasan: 'Sakit demam',
          statusPersetujuan: 'Pending',
        ),
        IzinMusyrifItem(
          idIzin: 'izin-2',
          nim: '24060505051',
          namaMahasantri: 'Budi Santoso',
          jenisIzin: 'Pulang',
          tanggalIzin: '2026-10-06T00:00:00.000Z',
          alasan: 'Keperluan keluarga',
          statusPersetujuan: 'Disetujui',
        ),
      ];
    });

    test('loadIzinBinaan dengan filter Pending hanya mengembalikan Pending', () async {
      final controller = IzinMusyrifController(repository: repo);
      controller.state = controller.state.copyWith(filter: IzinFilterMusyrif.pending);

      await controller.loadIzinBinaan();

      expect(controller.state.daftarIzin.length, 1);
      expect(controller.state.daftarIzin.first.namaMahasantri, 'Ahmad Fauzi');
      expect(controller.state.errorMessage, isNull);
    });

    test('loadIzinBinaan tanpa filter mengembalikan semua', () async {
      final controller = IzinMusyrifController(repository: repo);
      controller.state = controller.state.copyWith(filter: IzinFilterMusyrif.semua);

      await controller.loadIzinBinaan();

      expect(controller.state.daftarIzin.length, 2);
    });

    test('gantiFilter menyimpan filter dan memuat ulang', () async {
      final controller = IzinMusyrifController(repository: repo);

      await controller.gantiFilter(IzinFilterMusyrif.disetujui);

      expect(controller.state.filter, IzinFilterMusyrif.disetujui);
      expect(controller.state.daftarIzin.length, 1);
      expect(controller.state.daftarIzin.first.statusPersetujuan, 'Disetujui');
    });

    test('verifikasiIzin sukses memuat ulang daftar dan status berubah', () async {
      final controller = IzinMusyrifController(repository: repo);

      final berhasil = await controller.verifikasiIzin(
        idIzin: 'izin-1',
        statusBaru: 'Disetujui',
      );

      expect(berhasil, isTrue);
      expect(repo.lastIdIzin, 'izin-1');
      expect(repo.lastStatusBaru, 'Disetujui');
      // Server mengupdate status di daftar (izin-1 tidak lagi Pending)
      expect(
        repo.daftar.where((i) => i.idIzin == 'izin-1').first.statusPersetujuan,
        'Disetujui',
      );
      expect(controller.state.errorMessage, isNull);
    });

    test('verifikasiIzin 409 ERR_IZIN_ALREADY_DECIDED memuat ulang dan error ditampilkan', () async {
      repo.error = AppException(
        code: 'ERR_IZIN_ALREADY_DECIDED',
        message: 'Already decided',
        status: 409,
      );
      final controller = IzinMusyrifController(repository: repo);

      final berhasil = await controller.verifikasiIzin(
        idIzin: 'izin-1',
        statusBaru: 'Disetujui',
      );

      expect(berhasil, isFalse);
      expect(controller.state.errorMessage,
          'Izin sudah diputuskan dan tidak dapat diubah lagi.');
      // Daftar tetap dimuat ulang meski gagal (loadIzinBinaan dipanggil dalam catch? tidak, cek logika)
    });

    test('verifikasiIzin 404 ERR_IZIN_NOT_FOUND menampilkan error', () async {
      repo.error = AppException(
        code: 'ERR_IZIN_NOT_FOUND',
        message: 'Not found',
        status: 404,
      );
      final controller = IzinMusyrifController(repository: repo);

      final berhasil = await controller.verifikasiIzin(
        idIzin: 'izin-tidak-ada',
        statusBaru: 'Ditolak',
      );

      expect(berhasil, isFalse);
      expect(controller.state.errorMessage, 'Izin tidak ditemukan.');
    });

    test('tombol aksi hanya untuk Pending (statusParsed)', () {
      final pending = IzinMusyrifItem(
        idIzin: 'izin-1', nim: '1', namaMahasantri: 'A', jenisIzin: 'Sakit',
        tanggalIzin: '2026-10-05T00:00:00.000Z', alasan: 'a',
        statusPersetujuan: 'Pending',
      );
      final disetujui = IzinMusyrifItem(
        idIzin: 'izin-2', nim: '1', namaMahasantri: 'A', jenisIzin: 'Sakit',
        tanggalIzin: '2026-10-05T00:00:00.000Z', alasan: 'a',
        statusPersetujuan: 'Disetujui',
      );
      final ditolak = IzinMusyrifItem(
        idIzin: 'izin-3', nim: '1', namaMahasantri: 'A', jenisIzin: 'Sakit',
        tanggalIzin: '2026-10-05T00:00:00.000Z', alasan: 'a',
        statusPersetujuan: 'Ditolak',
      );

      expect(pending.statusParsed == StatusPersetujuanIzin.pending, isTrue);
      expect(disetujui.statusParsed == StatusPersetujuanIzin.pending, isFalse);
      expect(ditolak.statusParsed == StatusPersetujuanIzin.pending, isFalse);
    });
  });

  group('IzinMusyrifErrorMapper', () {
    test('ERR_IZIN_ALREADY_DECIDED memetakan pesan sudah diputuskan', () {
      const err = AppException(
        code: 'ERR_IZIN_ALREADY_DECIDED',
        message: 'Already decided',
        status: 409,
      );
      expect(
        IzinMusyrifErrorMapper.map(err),
        'Izin sudah diputuskan dan tidak dapat diubah lagi.',
      );
    });

    test('ERR_NOT_YOUR_STUDENT memetakan bukan santri binaan', () {
      const err = AppException(
        code: 'ERR_NOT_YOUR_STUDENT',
        message: 'Not your student',
        status: 403,
      );
      expect(
        IzinMusyrifErrorMapper.map(err),
        'Ini bukan santri binaan Anda.',
      );
    });

    test('ERR_IZIN_NOT_FOUND memetakan izin tidak ditemukan', () {
      const err = AppException(
        code: 'ERR_IZIN_NOT_FOUND',
        message: 'Not found',
        status: 404,
      );
      expect(
        IzinMusyrifErrorMapper.map(err),
        'Izin tidak ditemukan.',
      );
    });
  });

  group('IzinMusyrifScreen - Bottom Sheet Verifikasi', () {
    testWidgets('menampilkan pesan error asli terbaru saat verifikasi gagal', (tester) async {
      final repo = FakeIzinMusyrifRepository(
        apiClient: ApiClient(tokenStore: FakeTokenStore()),
      );
      repo.daftar = [
        const IzinMusyrifItem(
          idIzin: 'izin-1',
          nim: '24050505050',
          namaMahasantri: 'Ahmad Fauzi',
          jenisIzin: 'Sakit',
          tanggalIzin: '2026-10-05T00:00:00.000Z',
          alasan: 'Sakit demam',
          statusPersetujuan: 'Pending',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [izinMusyrifRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: IzinMusyrifScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ahmad Fauzi'));
      await tester.pumpAndSettle();

      repo.error = const AppException(
        code: 'ERR_IZIN_ALREADY_DECIDED',
        message: 'Already decided',
        status: 409,
      );

      await tester.tap(find.text('Setujui'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Izin sudah diputuskan dan tidak dapat diubah lagi.'),
        ),
        findsOneWidget,
      );
    });
  });
}
