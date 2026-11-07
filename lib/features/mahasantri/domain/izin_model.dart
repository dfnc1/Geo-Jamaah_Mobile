/// Model request body untuk POST /v1/izin.
/// Semua validasi bisnis (jenis_izin, tanggal, alasan, bukti_lampiran) dilakukan server.
class IzinRequest {
  final String jenisIzin; // "Sakit" | "Pulang" | "Tugas_Kampus"
  final String tanggalIzin; // "YYYY-MM-DD"
  final String alasan; // maks 500 karakter
  final String? buktiLampiran; // opsional, object key maks 255 karakter

  const IzinRequest({
    required this.jenisIzin,
    required this.tanggalIzin,
    required this.alasan,
    this.buktiLampiran,
  });

  Map<String, dynamic> toJson() => {
        'jenis_izin': jenisIzin,
        'tanggal_izin': tanggalIzin,
        'alasan': alasan,
        if (buktiLampiran != null) 'bukti_lampiran': buktiLampiran,
      };
}

/// Jenis izin yang diterima server (enum dari API_CONTRACT.md).
enum JenisIzin {
  sakit('Sakit'),
  pulang('Pulang'),
  tugasKampus('Tugas_Kampus');

  final String rawValue;
  const JenisIzin(this.rawValue);

  static JenisIzin? fromString(String? value) {
    switch (value) {
      case 'Sakit':
        return JenisIzin.sakit;
      case 'Pulang':
        return JenisIzin.pulang;
      case 'Tugas_Kampus':
        return JenisIzin.tugasKampus;
      default:
        return null;
    }
  }

  String get labelIndonesia {
    switch (this) {
      case JenisIzin.sakit:
        return 'Sakit';
      case JenisIzin.pulang:
        return 'Pulang';
      case JenisIzin.tugasKampus:
        return 'Tugas Kampus';
    }
  }
}

/// Status persetujuan izin dari server.
enum StatusPersetujuanIzin {
  pending('Pending'),
  disetujui('Disetujui'),
  ditolak('Ditolak');

  final String rawValue;
  const StatusPersetujuanIzin(this.rawValue);

  static StatusPersetujuanIzin fromString(String? value) {
    switch (value) {
      case 'Pending':
        return StatusPersetujuanIzin.pending;
      case 'Disetujui':
        return StatusPersetujuanIzin.disetujui;
      case 'Ditolak':
        return StatusPersetujuanIzin.ditolak;
      default:
        return StatusPersetujuanIzin.pending;
    }
  }

  String get labelIndonesia {
    switch (this) {
      case StatusPersetujuanIzin.pending:
        return 'Menunggu';
      case StatusPersetujuanIzin.disetujui:
        return 'Disetujui';
      case StatusPersetujuanIzin.ditolak:
        return 'Ditolak';
    }
  }
}

/// Model satu item izin dari respons POST /v1/izin atau GET /v1/izin/saya.
/// Field sesuai API_CONTRACT.md (tanpa nama_mahasantri — itu hanya untuk Musyrif).
class IzinItem {
  final String idIzin;
  final String nim;
  final String jenisIzin;
  final String tanggalIzin; // ISO UTC midnight dari server; tampilkan 10 char pertama
  final String alasan;
  final String? buktiLampiran;
  final String statusPersetujuan; // "Pending" | "Disetujui" | "Ditolak"

  const IzinItem({
    required this.idIzin,
    required this.nim,
    required this.jenisIzin,
    required this.tanggalIzin,
    required this.alasan,
    this.buktiLampiran,
    required this.statusPersetujuan,
  });

  factory IzinItem.fromJson(Map<String, dynamic> json) {
    return IzinItem(
      idIzin: json['id_izin']?.toString() ?? '',
      nim: json['nim']?.toString() ?? '',
      jenisIzin: json['jenis_izin']?.toString() ?? '',
      tanggalIzin: json['tanggal_izin']?.toString() ?? '',
      alasan: json['alasan']?.toString() ?? '',
      buktiLampiran: json['bukti_lampiran']?.toString(),
      statusPersetujuan:
          json['status_persetujuan']?.toString() ?? 'Pending',
    );
  }

  /// Tanggal dalam format YYYY-MM-DD (ambil 10 karakter pertama dari ISO UTC).
  String get tanggalDisplay {
    if (tanggalIzin.isEmpty) return '-';
    return tanggalIzin.length >= 10 ? tanggalIzin.substring(0, 10) : tanggalIzin;
  }

  StatusPersetujuanIzin get statusParsed =>
      StatusPersetujuanIzin.fromString(statusPersetujuan);
}

/// Respons sukses POST /v1/izin (data sudah di-unwrap ApiClient).
class IzinResult {
  final String idIzin;
  final String nim;
  final String jenisIzin;
  final String tanggalIzin;
  final String alasan;
  final String? buktiLampiran;
  final String statusPersetujuan;

  const IzinResult({
    required this.idIzin,
    required this.nim,
    required this.jenisIzin,
    required this.tanggalIzin,
    required this.alasan,
    this.buktiLampiran,
    required this.statusPersetujuan,
  });

  factory IzinResult.fromJson(Map<String, dynamic> json) {
    return IzinResult(
      idIzin: json['id_izin']?.toString() ?? '',
      nim: json['nim']?.toString() ?? '',
      jenisIzin: json['jenis_izin']?.toString() ?? '',
      tanggalIzin: json['tanggal_izin']?.toString() ?? '',
      alasan: json['alasan']?.toString() ?? '',
      buktiLampiran: json['bukti_lampiran']?.toString(),
      statusPersetujuan:
          json['status_persetujuan']?.toString() ?? 'Pending',
    );
  }

  /// Tanggal dalam format YYYY-MM-DD (ambil 10 karakter pertama dari ISO UTC).
  String get tanggalDisplay {
    if (tanggalIzin.isEmpty) return '-';
    return tanggalIzin.length >= 10 ? tanggalIzin.substring(0, 10) : tanggalIzin;
  }
}
