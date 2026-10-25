import 'package:flutter_test/flutter_test.dart';
import 'package:geo_jamaah/features/presensi/domain/presensi_models.dart';

void main() {
  group('PresensiRequest.toJson', () {
    test('semua field dikirim dengan nama kunci yang benar', () {
      const req = PresensiRequest(
        idJadwal: 'uuid-j',
        idMasjid: 'uuid-m',
        latitudeUser: -7.9671,
        longitudeUser: 112.6326,
        akurasiMeter: 12.5,
        isMockLocation: false,
      );

      final json = req.toJson();

      expect(json['id_jadwal'], 'uuid-j');
      expect(json['id_masjid'], 'uuid-m');
      expect(json['latitude_user'], -7.9671);
      expect(json['longitude_user'], 112.6326);
      expect(json['akurasi_meter'], 12.5);
      expect(json['is_mock_location'], false);
    });
  });

  group('PresensiResult.fromJson', () {
    test('parse respons sukses dengan benar', () {
      final json = {
        'status_presensi': 'Hadir',
        'nama_sholat': 'Subuh',
        'jarak_meter': 23.5,
      };

      final result = PresensiResult.fromJson(json);

      expect(result.statusPresensi, 'Hadir');
      expect(result.namaSholat, 'Subuh');
      expect(result.jarakMeter, 23.5);
    });

    test('nilai default saat field tidak ada', () {
      final result = PresensiResult.fromJson({});
      expect(result.statusPresensi, 'Hadir');
      expect(result.namaSholat, '');
      expect(result.jarakMeter, 0.0);
    });

    test('konversi num ke double untuk jarak_meter', () {
      final json = {
        'status_presensi': 'Hadir',
        'nama_sholat': 'Isya',
        'jarak_meter': 55, // int, bukan double
      };
      final result = PresensiResult.fromJson(json);
      expect(result.jarakMeter, 55.0);
      expect(result.jarakMeter, isA<double>());
    });
  });
}
