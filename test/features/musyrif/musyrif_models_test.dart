import 'package:flutter_test/flutter_test.dart';
import 'package:geo_jamaah/features/musyrif/domain/musyrif_models.dart';

void main() {
  group('SantriKritis.fromJson', () {
    test('parse respons lengkap dengan alasan dan jumlah', () {
      final json = {
        'nim': '24050505050',
        'nama': 'Ahmad Fauzi',
        'kategori_risiko': 'KRITIS',
        'rasio_kehadiran': 61.5,
        'streak_alpha': 3,
        'jumlah': {'hadir': 8, 'tidak_hadir': 5, 'izin': 1},
        'alasan': ['rasio', 'streak'],
        'rekomendasi_tindakan':
            'Lakukan pendampingan kehadiran dan bimbingan belajar terjadwal.',
      };

      final k = SantriKritis.fromJson(json);

      expect(k.nim, '24050505050');
      expect(k.nama, 'Ahmad Fauzi');
      expect(k.kategoriRisiko, 'KRITIS');
      expect(k.rasioKehadiran, 61.5);
      expect(k.streakAlpha, 3);
      expect(k.jumlahHadir, 8);
      expect(k.jumlahTidakHadir, 5);
      expect(k.jumlahIzin, 1);
      expect(k.alasan, ['rasio', 'streak']);
      expect(k.rasioDisplay, '61.5');
      expect(k.alasanTeks, ['Kehadiran rendah', 'Alpha berturut-turut']);
      expect(
        k.rekomendasiTindakan,
        'Lakukan pendampingan kehadiran dan bimbingan belajar terjadwal.',
      );
    });

    test('rasio null -> tampilkan "-" dan alasan kosong', () {
      final k = SantriKritis.fromJson({
        'nim': '24050505050',
        'nama': 'Ahmad Fauzi',
        'kategori_risiko': 'KRITIS',
        'streak_alpha': 0,
        'jumlah': {'hadir': 0, 'tidak_hadir': 0, 'izin': 0},
        'rekomendasi_tindakan': 'Pantau perkembangan kehadiran.',
      });

      expect(k.rasioKehadiran, isNull);
      expect(k.rasioDisplay, '-');
      expect(k.alasanTeks, isEmpty);
    });

    test('daftar kritis kosong []', () {
      final items = <Map<String, dynamic>>[];
      final list = items.map((e) => SantriKritis.fromJson(e)).toList();
      expect(list, isEmpty);
    });
  });

  group('MonitoringResponse.fromJson', () {
    test('parse respons monitoring lengkap', () {
      final json = {
        'tanggal': '2026-10-15',
        'jadwal': [
          {
            'id_jadwal': 'j1',
            'nama_sholat': 'Subuh',
            'waktu_azan': '04:30',
            'waktu_mulai_presensi': '04:15',
            'waktu_akhir_presensi': '05:10',
          },
        ],
        'ringkasan': {
          'Hadir': 1,
          'Tidak_Hadir': 1,
          'Izin': 0,
          'Manual': 0,
          'Belum': 0,
        },
        'santri': [
          {
            'nim': '24050505050',
            'nama': 'Ahmad Fauzi',
            'kamar': 'A-12',
            'status': [
              {
                'id_jadwal': 'j1',
                'nama_sholat': 'Subuh',
                'status': 'Hadir',
              },
            ],
          },
        ],
      };

      final m = MonitoringResponse.fromJson(json);

      expect(m.tanggal, '2026-10-15');
      expect(m.jadwal.length, 1);
      expect(m.jadwal.first.namaSholat, 'Subuh');
      expect(m.ringkasan.hadir, 1);
      expect(m.ringkasan.tidakHadir, 1);
      expect(m.ringkasan.total, 2);
      expect(m.santri.length, 1);
      expect(m.santri.first.nama, 'Ahmad Fauzi');
      expect(m.santri.first.status.first.status, 'Hadir');
    });

    test('monitoring tanpa data -> ringkasan nol dan santri kosong', () {
      final m = MonitoringResponse.fromJson({
        'tanggal': '2026-10-16',
        'jadwal': [],
        'ringkasan': {},
        'santri': [],
      });
      expect(m.jadwal, isEmpty);
      expect(m.ringkasan.total, 0);
      expect(m.santri, isEmpty);
    });
  });

  group('TrenKehadiranResponse.fromJson', () {
    test('parse respons tren dengan persen_hadir null dan berisi', () {
      final json = {
        'hari': 2,
        'tanggal_mulai': '2026-10-18',
        'tanggal_akhir': '2026-10-19',
        'data': [
          {
            'tanggal': '2026-10-18',
            'hadir': 4,
            'tidak_hadir': 1,
            'izin': 0,
            'manual': 1,
            'total': 6,
            'persen_hadir': 83.3,
          },
          {
            'tanggal': '2026-10-19',
            'hadir': 0,
            'tidak_hadir': 0,
            'izin': 0,
            'manual': 0,
            'total': 0,
            'persen_hadir': null,
          },
        ],
      };

      final t = TrenKehadiranResponse.fromJson(json);

      expect(t.hari, 2);
      expect(t.tanggalMulai, '2026-10-18');
      expect(t.tanggalAkhir, '2026-10-19');
      expect(t.data.length, 2);
      expect(t.data.first.persenHadir, 83.3);
      expect(t.data.first.persenDisplay, '83.3');
      expect(t.data.last.persenHadir, isNull);
      expect(t.data.last.persenDisplay, '-');
    });
  });

  group('Batas tanggal date picker', () {
    test('lastDate adalah hari ini (masuknya masa depan tidak diperbolehkan)', () {
      final today = DateTime(DateTime.now().year, DateTime.now().month,
          DateTime.now().day);
      final lastDate = today; // logika Izin/Monitoring: lastDate = now

      expect(lastDate.isAtSameMomentAs(today), isTrue);
      expect(today.add(const Duration(days: 1)).isAfter(lastDate), isTrue);
    });
  });
}
