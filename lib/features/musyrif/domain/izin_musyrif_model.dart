import '../../mahasantri/domain/izin_model.dart';

/// Model data izin santri binaan untuk Musyrif (GET /v1/musyrif/izin).
/// Sama dengan IzinItem Mahasantri ditambah nama_mahasantri.
class IzinMusyrifItem {
  final String idIzin;
  final String nim;
  final String namaMahasantri;
  final String jenisIzin;
  final String tanggalIzin; // ISO UTC midnight dari server
  final String alasan;
  final String? buktiLampiran;
  final String statusPersetujuan; // "Pending" | "Disetujui" | "Ditolak"

  const IzinMusyrifItem({
    required this.idIzin,
    required this.nim,
    required this.namaMahasantri,
    required this.jenisIzin,
    required this.tanggalIzin,
    required this.alasan,
    this.buktiLampiran,
    required this.statusPersetujuan,
  });

  factory IzinMusyrifItem.fromJson(Map<String, dynamic> json) {
    return IzinMusyrifItem(
      idIzin: json['id_izin']?.toString() ?? '',
      nim: json['nim']?.toString() ?? '',
      namaMahasantri: json['nama_mahasantri']?.toString() ?? '',
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

/// Filter izin untuk Musyrif.
enum IzinFilterMusyrif {
  pending('Pending'),
  disetujui('Disetujui'),
  ditolak('Ditolak'),
  semua(null);

  final String? rawValue;
  const IzinFilterMusyrif(this.rawValue);

  String get label {
    switch (this) {
      case IzinFilterMusyrif.pending:
        return 'Pending';
      case IzinFilterMusyrif.disetujui:
        return 'Disetujui';
      case IzinFilterMusyrif.ditolak:
        return 'Ditolak';
      case IzinFilterMusyrif.semua:
        return 'Semua';
    }
  }
}
