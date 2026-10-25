/// Model request body untuk POST /v1/presensi.
/// Semua pengecekan (jarak, window waktu, akurasi) dilakukan server.
class PresensiRequest {
  final String idJadwal;
  final String idMasjid;
  final double latitudeUser;
  final double longitudeUser;
  final double akurasiMeter;
  final bool isMockLocation;

  const PresensiRequest({
    required this.idJadwal,
    required this.idMasjid,
    required this.latitudeUser,
    required this.longitudeUser,
    required this.akurasiMeter,
    required this.isMockLocation,
  });

  Map<String, dynamic> toJson() => {
        'id_jadwal': idJadwal,
        'id_masjid': idMasjid,
        'latitude_user': latitudeUser,
        'longitude_user': longitudeUser,
        'akurasi_meter': akurasiMeter,
        'is_mock_location': isMockLocation,
      };
}

/// Model respons sukses dari POST /v1/presensi (data sudah di-unwrap ApiClient).
/// Server mengembalikan { status_presensi, nama_sholat, jarak_meter }.
class PresensiResult {
  final String statusPresensi;
  final String namaSholat;
  final double jarakMeter;

  const PresensiResult({
    required this.statusPresensi,
    required this.namaSholat,
    required this.jarakMeter,
  });

  factory PresensiResult.fromJson(Map<String, dynamic> json) {
    return PresensiResult(
      statusPresensi: json['status_presensi']?.toString() ?? 'Hadir',
      namaSholat: json['nama_sholat']?.toString() ?? '',
      jarakMeter: (json['jarak_meter'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
