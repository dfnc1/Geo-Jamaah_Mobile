import 'package:intl/intl.dart';

/// Enum status presensi untuk satu jadwal shalat.
enum StatusPresensiJadwal {
  hadir('Hadir'),
  tidakHadir('Tidak_Hadir'),
  izin('Izin'),
  manual('Manual'),
  belum('Belum'),
  unknown('Unknown');

  final String rawValue;
  const StatusPresensiJadwal(this.rawValue);

  static StatusPresensiJadwal fromString(String? value) {
    if (value == null) return StatusPresensiJadwal.unknown;
    final normalized = value.trim().toLowerCase().replaceAll(' ', '_');
    switch (normalized) {
      case 'hadir':
        return StatusPresensiJadwal.hadir;
      case 'tidak_hadir':
      case 'tidakhadir':
        return StatusPresensiJadwal.tidakHadir;
      case 'izin':
        return StatusPresensiJadwal.izin;
      case 'manual':
        return StatusPresensiJadwal.manual;
      case 'belum':
        return StatusPresensiJadwal.belum;
      default:
        return StatusPresensiJadwal.unknown;
    }
  }

  bool get isBelum => this == StatusPresensiJadwal.belum;
}

/// Data informasi masjid utama dari server.
class MasjidModel {
  final String idMasjid;
  final String namaMasjid;
  final double latitude;
  final double longitude;
  final int radiusToleransi;

  const MasjidModel({
    required this.idMasjid,
    required this.namaMasjid,
    required this.latitude,
    required this.longitude,
    required this.radiusToleransi,
  });

  factory MasjidModel.fromJson(Map<String, dynamic> json) {
    return MasjidModel(
      idMasjid: json['id_masjid']?.toString() ?? '',
      namaMasjid: json['nama_masjid']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      radiusToleransi: (json['radius_toleransi'] as num?)?.toInt() ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_masjid': idMasjid,
      'nama_masjid': namaMasjid,
      'latitude': latitude,
      'longitude': longitude,
      'radius_toleransi': radiusToleransi,
    };
  }
}

/// Data satu item jadwal shalat hari ini beserta status kehadiran santri.
class JadwalHariIniModel {
  final String idJadwal;
  final String namaSholat;
  final String waktuAzan;
  final String waktuIqamah;
  final String waktuMulaiPresensi;
  final String waktuAkhirPresensi;
  final StatusPresensiJadwal status;
  final bool sedangDalamWindow;

  const JadwalHariIniModel({
    required this.idJadwal,
    required this.namaSholat,
    required this.waktuAzan,
    required this.waktuIqamah,
    required this.waktuMulaiPresensi,
    required this.waktuAkhirPresensi,
    required this.status,
    required this.sedangDalamWindow,
  });

  factory JadwalHariIniModel.fromJson(Map<String, dynamic> json) {
    return JadwalHariIniModel(
      idJadwal: json['id_jadwal']?.toString() ?? '',
      namaSholat: json['nama_sholat']?.toString() ?? '',
      waktuAzan: json['waktu_azan']?.toString() ?? '',
      waktuIqamah: json['waktu_iqamah']?.toString() ?? '',
      waktuMulaiPresensi: json['waktu_mulai_presensi']?.toString() ?? '',
      waktuAkhirPresensi: json['waktu_akhir_presensi']?.toString() ?? '',
      status: StatusPresensiJadwal.fromString(json['status']?.toString()),
      sedangDalamWindow: json['sedang_dalam_window'] == true,
    );
  }

  /// Rentang waktu presensi (misal "04:20 - 05:00")
  String get rentangPresensi => '$waktuMulaiPresensi - $waktuAkhirPresensi';

  /// Apakah kartu memenuhi kriteria untuk tombol "Presensi" aktif
  bool get bisaPresensi => status.isBelum && sedangDalamWindow;

  /// Teks keterangan netral jika belum presensi dan di luar window
  String? get keteranganNetral {
    if (status.isBelum && !sedangDalamWindow) {
      return 'Di luar waktu presensi';
    }
    return null;
  }
}

/// Respons data lengkap dari endpoint GET /v1/presensi/hari-ini.
class PresensiHariIniResponse {
  final String tanggal;
  final MasjidModel? masjid;
  final List<JadwalHariIniModel> jadwal;

  const PresensiHariIniResponse({
    required this.tanggal,
    this.masjid,
    required this.jadwal,
  });

  factory PresensiHariIniResponse.fromJson(Map<String, dynamic> json) {
    final rawJadwal = json['jadwal'];
    final jadwalList = <JadwalHariIniModel>[];

    if (rawJadwal is List) {
      for (final item in rawJadwal) {
        if (item is Map<String, dynamic>) {
          jadwalList.add(JadwalHariIniModel.fromJson(item));
        }
      }
    }

    return PresensiHariIniResponse(
      tanggal: json['tanggal']?.toString() ?? '',
      masjid: json['masjid'] is Map<String, dynamic>
          ? MasjidModel.fromJson(json['masjid'] as Map<String, dynamic>)
          : null,
      jadwal: jadwalList,
    );
  }

  /// Format tanggal Indonesia ramah pengguna (contoh: "Senin, 19 Oktober 2026").
  String get formattedTanggalIndonesia {
    if (tanggal.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(tanggal);
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(parsed);
    } catch (_) {
      return tanggal;
    }
  }
}
