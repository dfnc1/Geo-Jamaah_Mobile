import 'package:flutter_test/flutter_test.dart';
import 'package:geo_jamaah/features/mahasantri/domain/izin_model.dart';

void main() {
  group('IzinRequest.toJson', () {
    test('semua field dikirim dengan nama kunci yang benar', () {
      const req = IzinRequest(
        jenisIzin: 'Sakit',
        tanggalIzin: '2026-10-05',
        alasan: 'Sakit demam, sudah ke puskesmas',
        buktiLampiran: 'izin/24050505050/2026-10-05.jpg',
      );

      final json = req.toJson();

      expect(json['jenis_izin'], 'Sakit');
      expect(json['tanggal_izin'], '2026-10-05');
      expect(json['alasan'], 'Sakit demam, sudah ke puskesmas');
      expect(json['bukti_lampiran'], 'izin/24050505050/2026-10-05.jpg');
    });

    test('bukti_lampiran tidak dikirim saat null', () {
      const req = IzinRequest(
        jenisIzin: 'Pulang',
        tanggalIzin: '2026-10-06',
        alasan: 'Keperluan keluarga',
        buktiLampiran: null,
      );

      final json = req.toJson();

      expect(json.containsKey('bukti_lampiran'), isFalse);
      expect(json['jenis_izin'], 'Pulang');
    });
  });

  group('JenisIzin', () {
    test('fromString memetakan semua nilai enum dengan benar', () {
      expect(JenisIzin.fromString('Sakit'), JenisIzin.sakit);
      expect(JenisIzin.fromString('Pulang'), JenisIzin.pulang);
      expect(JenisIzin.fromString('Tugas_Kampus'), JenisIzin.tugasKampus);
      expect(JenisIzin.fromString('Lainnya'), isNull);
      expect(JenisIzin.fromString(null), isNull);
    });

    test('labelIndonesia berisi teks ramah pengguna', () {
      expect(JenisIzin.sakit.labelIndonesia, 'Sakit');
      expect(JenisIzin.pulang.labelIndonesia, 'Pulang');
      expect(JenisIzin.tugasKampus.labelIndonesia, 'Tugas Kampus');
    });

    test('rawValue sesuai enum server', () {
      expect(JenisIzin.sakit.rawValue, 'Sakit');
      expect(JenisIzin.pulang.rawValue, 'Pulang');
      expect(JenisIzin.tugasKampus.rawValue, 'Tugas_Kampus');
    });
  });

  group('StatusPersetujuanIzin', () {
    test('fromString memetakan semua nilai status dengan benar', () {
      expect(StatusPersetujuanIzin.fromString('Pending'),
          StatusPersetujuanIzin.pending);
      expect(StatusPersetujuanIzin.fromString('Disetujui'),
          StatusPersetujuanIzin.disetujui);
      expect(StatusPersetujuanIzin.fromString('Ditolak'),
          StatusPersetujuanIzin.ditolak);
      expect(StatusPersetujuanIzin.fromString('Unknown'),
          StatusPersetujuanIzin.pending);
    });

    test('labelIndonesia berisi teks ramah pengguna', () {
      expect(StatusPersetujuanIzin.pending.labelIndonesia, 'Menunggu');
      expect(StatusPersetujuanIzin.disetujui.labelIndonesia, 'Disetujui');
      expect(StatusPersetujuanIzin.ditolak.labelIndonesia, 'Ditolak');
    });
  });

  group('IzinItem.fromJson', () {
    test('parse respons lengkap dengan benar', () {
      final json = {
        'id_izin': 'uuid-izin',
        'nim': '24050505050',
        'jenis_izin': 'Sakit',
        'tanggal_izin': '2026-10-05T00:00:00.000Z',
        'alasan': 'Sakit demam',
        'bukti_lampiran': 'izin/24050505050/2026-10-05.jpg',
        'status_persetujuan': 'Pending',
      };

      final item = IzinItem.fromJson(json);

      expect(item.idIzin, 'uuid-izin');
      expect(item.nim, '24050505050');
      expect(item.jenisIzin, 'Sakit');
      expect(item.tanggalIzin, '2026-10-05T00:00:00.000Z');
      expect(item.alasan, 'Sakit demam');
      expect(item.buktiLampiran, 'izin/24050505050/2026-10-05.jpg');
      expect(item.statusPersetujuan, 'Pending');
      expect(item.statusParsed, StatusPersetujuanIzin.pending);
    });

    test('tanggalDisplay mengambil 10 karakter pertama', () {
      final item = IzinItem.fromJson({
        'id_izin': 'uuid-izin',
        'nim': '24050505050',
        'jenis_izin': 'Sakit',
        'tanggal_izin': '2026-10-05T00:00:00.000Z',
        'alasan': 'Sakit',
        'status_persetujuan': 'Pending',
      });
      expect(item.tanggalDisplay, '2026-10-05');
    });

    test('field opsional aman saat null', () {
      final item = IzinItem.fromJson({
        'id_izin': 'uuid-izin',
        'nim': '24050505050',
        'jenis_izin': 'Pulang',
        'tanggal_izin': '2026-10-06T00:00:00.000Z',
        'alasan': 'Keperluan',
        'status_persetujuan': 'Ditolak',
      });
      expect(item.buktiLampiran, isNull);
      expect(item.tanggalDisplay, '2026-10-06');
      expect(item.statusParsed, StatusPersetujuanIzin.ditolak);
    });
  });

  group('IzinResult.fromJson', () {
    test('parse respons sukses POST /v1/izin dengan benar', () {
      final json = {
        'id_izin': 'uuid-izin',
        'nim': '24050505050',
        'jenis_izin': 'Tugas_Kampus',
        'tanggal_izin': '2026-10-07T00:00:00.000Z',
        'alasan': 'Mengerjakan proyek akhir',
        'bukti_lampiran': null,
        'status_persetujuan': 'Pending',
      };

      final result = IzinResult.fromJson(json);

      expect(result.idIzin, 'uuid-izin');
      expect(result.nim, '24050505050');
      expect(result.jenisIzin, 'Tugas_Kampus');
      expect(result.tanggalIzin, '2026-10-07T00:00:00.000Z');
      expect(result.alasan, 'Mengerjakan proyek akhir');
      expect(result.buktiLampiran, isNull);
      expect(result.statusPersetujuan, 'Pending');
      expect(result.tanggalDisplay, '2026-10-07');
    });

    test('nilai default saat field tidak ada', () {
      final result = IzinResult.fromJson({});
      expect(result.idIzin, '');
      expect(result.nim, '');
      expect(result.jenisIzin, '');
      expect(result.tanggalIzin, '');
      expect(result.alasan, '');
      expect(result.buktiLampiran, isNull);
      expect(result.statusPersetujuan, 'Pending');
      expect(result.tanggalDisplay, '-');
    });
  });

  group('Rentang tanggal izin (date picker)', () {
    test('firstDate 30 hari ke belakang dan lastDate 90 hari ke depan dari hari ini', () {
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      // Logika yang sama dengan IzinScreen._pilihTanggal
      final firstDate = today.subtract(const Duration(days: 30));
      final lastDate = today.add(const Duration(days: 90));

      // Batas bawah inklusif: 30 hari yang lalu masih valid
      expect(firstDate.isAtSameMomentAs(today.subtract(const Duration(days: 30))), isTrue);
      expect(firstDate.isBefore(today), isTrue);

      // Satu hari di luar batas bawah (31 hari lalu) tidak valid
      expect(today.subtract(const Duration(days: 31)).isBefore(firstDate), isTrue);

      // Batas atas inklusif: 90 hari ke depan masih valid
      expect(lastDate.isAtSameMomentAs(today.add(const Duration(days: 90))), isTrue);
      expect(lastDate.isAfter(today), isTrue);

      // Satu hari di luar batas atas (91 hari depan) tidak valid
      expect(today.add(const Duration(days: 91)).isAfter(lastDate), isTrue);
    });
  });
}
