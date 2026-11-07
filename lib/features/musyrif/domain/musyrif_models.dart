/// Model data santri kritis dari GET /v1/musyrif/dss/santri-kritis.
class SantriKritis {
  final String nim;
  final String nama;
  final String kategoriRisiko; // "KRITIS"
  final double? rasioKehadiran; // persen 1 desimal, null bila tanpa data
  final int streakAlpha;
  final int jumlahHadir;
  final int jumlahTidakHadir;
  final int jumlahIzin;
  final List<String> alasan; // subset ["rasio", "streak"]
  final String rekomendasiTindakan;

  const SantriKritis({
    required this.nim,
    required this.nama,
    required this.kategoriRisiko,
    this.rasioKehadiran,
    required this.streakAlpha,
    required this.jumlahHadir,
    required this.jumlahTidakHadir,
    required this.jumlahIzin,
    required this.alasan,
    required this.rekomendasiTindakan,
  });

  factory SantriKritis.fromJson(Map<String, dynamic> json) {
    final jumlah = json['jumlah'] is Map
        ? json['jumlah'] as Map<String, dynamic>
        : <String, dynamic>{};
    final alasanRaw = json['alasan'];
    final List<String> alasanList = [];
    if (alasanRaw is List) {
      for (final a in alasanRaw) {
        if (a is String) alasanList.add(a);
      }
    }

    return SantriKritis(
      nim: json['nim']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      kategoriRisiko: json['kategori_risiko']?.toString() ?? '',
      rasioKehadiran:
          (json['rasio_kehadiran'] as num?)?.toDouble(),
      streakAlpha: (json['streak_alpha'] as num?)?.toInt() ?? 0,
      jumlahHadir: (jumlah['hadir'] as num?)?.toInt() ?? 0,
      jumlahTidakHadir: (jumlah['tidak_hadir'] as num?)?.toInt() ?? 0,
      jumlahIzin: (jumlah['izin'] as num?)?.toInt() ?? 0,
      alasan: alasanList,
      rekomendasiTindakan: json['rekomendasi_tindakan']?.toString() ?? '',
    );
  }

  /// Rasio diformat 1 desimal, atau "-" bila null.
  String get rasioDisplay {
    if (rasioKehadiran == null) return '-';
    return rasioKehadiran!.toStringAsFixed(1);
  }

  /// Petakan kode alasan server ke teks ramah pengguna.
  List<String> get alasanTeks {
    final teks = <String>[];
    for (final a in alasan) {
      switch (a) {
        case 'rasio':
          teks.add('Kehadiran rendah');
        case 'streak':
          teks.add('Alpha berturut-turut');
        default:
          teks.add(a);
      }
    }
    return teks;
  }
}

/// Model satu jadwal dalam monitoring.
class MonitoringJadwal {
  final String idJadwal;
  final String namaSholat;
  final String waktuAzan;
  final String waktuMulaiPresensi;
  final String waktuAkhirPresensi;

  const MonitoringJadwal({
    required this.idJadwal,
    required this.namaSholat,
    required this.waktuAzan,
    required this.waktuMulaiPresensi,
    required this.waktuAkhirPresensi,
  });

  factory MonitoringJadwal.fromJson(Map<String, dynamic> json) {
    return MonitoringJadwal(
      idJadwal: json['id_jadwal']?.toString() ?? '',
      namaSholat: json['nama_sholat']?.toString() ?? '',
      waktuAzan: json['waktu_azan']?.toString() ?? '',
      waktuMulaiPresensi: json['waktu_mulai_presensi']?.toString() ?? '',
      waktuAkhirPresensi: json['waktu_akhir_presensi']?.toString() ?? '',
    );
  }
}

/// Model status satu sel (santri × jadwal) dalam monitoring.
class MonitoringStatusSel {
  final String idJadwal;
  final String namaSholat;
  final String status; // Hadir | Tidak_Hadir | Izin | Manual | Belum

  const MonitoringStatusSel({
    required this.idJadwal,
    required this.namaSholat,
    required this.status,
  });

  factory MonitoringStatusSel.fromJson(Map<String, dynamic> json) {
    return MonitoringStatusSel(
      idJadwal: json['id_jadwal']?.toString() ?? '',
      namaSholat: json['nama_sholat']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Belum',
    );
  }
}

/// Model satu santri dalam monitoring.
class MonitoringSantri {
  final String nim;
  final String nama;
  final String kamar;
  final List<MonitoringStatusSel> status;

  const MonitoringSantri({
    required this.nim,
    required this.nama,
    required this.kamar,
    required this.status,
  });

  factory MonitoringSantri.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'];
    final List<MonitoringStatusSel> statusList = [];
    if (rawStatus is List) {
      for (final s in rawStatus) {
        if (s is Map<String, dynamic>) {
          statusList.add(MonitoringStatusSel.fromJson(s));
        }
      }
    }

    return MonitoringSantri(
      nim: json['nim']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      kamar: json['kamar']?.toString() ?? '-',
      status: statusList,
    );
  }
}

/// Ringkasan monitoring (jumlah sel per status).
class MonitoringRingkasan {
  final int hadir;
  final int tidakHadir;
  final int izin;
  final int manual;
  final int belum;

  const MonitoringRingkasan({
    required this.hadir,
    required this.tidakHadir,
    required this.izin,
    required this.manual,
    required this.belum,
  });

  int get total => hadir + tidakHadir + izin + manual + belum;

  factory MonitoringRingkasan.fromJson(Map<String, dynamic> json) {
    return MonitoringRingkasan(
      hadir: (json['Hadir'] as num?)?.toInt() ?? 0,
      tidakHadir: (json['Tidak_Hadir'] as num?)?.toInt() ?? 0,
      izin: (json['Izin'] as num?)?.toInt() ?? 0,
      manual: (json['Manual'] as num?)?.toInt() ?? 0,
      belum: (json['Belum'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Respons GET /v1/musyrif/presensi/monitoring?tanggal=
class MonitoringResponse {
  final String tanggal;
  final List<MonitoringJadwal> jadwal;
  final MonitoringRingkasan ringkasan;
  final List<MonitoringSantri> santri;

  const MonitoringResponse({
    required this.tanggal,
    required this.jadwal,
    required this.ringkasan,
    required this.santri,
  });

  factory MonitoringResponse.fromJson(Map<String, dynamic> json) {
    final rawJadwal = json['jadwal'];
    final List<MonitoringJadwal> jadwalList = [];
    if (rawJadwal is List) {
      for (final j in rawJadwal) {
        if (j is Map<String, dynamic>) {
          jadwalList.add(MonitoringJadwal.fromJson(j));
        }
      }
    }

    final rawRingkasan = json['ringkasan'];
    final ringkasan = rawRingkasan is Map
        ? MonitoringRingkasan.fromJson(Map<String, dynamic>.from(rawRingkasan))
        : const MonitoringRingkasan(
            hadir: 0, tidakHadir: 0, izin: 0, manual: 0, belum: 0);

    final rawSantri = json['santri'];
    final List<MonitoringSantri> santriList = [];
    if (rawSantri is List) {
      for (final s in rawSantri) {
        if (s is Map<String, dynamic>) {
          santriList.add(MonitoringSantri.fromJson(s));
        }
      }
    }

    return MonitoringResponse(
      tanggal: json['tanggal']?.toString() ?? '',
      jadwal: jadwalList,
      ringkasan: ringkasan,
      santri: santriList,
    );
  }
}

/// Model satu harian dalam tren kehadiran.
class TrenHarian {
  final String tanggal;
  final int hadir;
  final int tidakHadir;
  final int izin;
  final int manual;
  final int total;
  final double? persenHadir;

  const TrenHarian({
    required this.tanggal,
    required this.hadir,
    required this.tidakHadir,
    required this.izin,
    required this.manual,
    required this.total,
    this.persenHadir,
  });

  factory TrenHarian.fromJson(Map<String, dynamic> json) {
    return TrenHarian(
      tanggal: json['tanggal']?.toString() ?? '',
      hadir: (json['hadir'] as num?)?.toInt() ?? 0,
      tidakHadir: (json['tidak_hadir'] as num?)?.toInt() ?? 0,
      izin: (json['izin'] as num?)?.toInt() ?? 0,
      manual: (json['manual'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      persenHadir: (json['persen_hadir'] as num?)?.toDouble(),
    );
  }

  /// Persen hadir diformat 1 desimal, atau "-" bila null.
  String get persenDisplay {
    if (persenHadir == null) return '-';
    return persenHadir!.toStringAsFixed(1);
  }
}

/// Respons GET /v1/musyrif/dashboard/tren-kehadiran?hari=
class TrenKehadiranResponse {
  final int hari;
  final String tanggalMulai;
  final String tanggalAkhir;
  final List<TrenHarian> data;

  const TrenKehadiranResponse({
    required this.hari,
    required this.tanggalMulai,
    required this.tanggalAkhir,
    required this.data,
  });

  factory TrenKehadiranResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final List<TrenHarian> dataList = [];
    if (rawData is List) {
      for (final d in rawData) {
        if (d is Map<String, dynamic>) {
          dataList.add(TrenHarian.fromJson(d));
        }
      }
    }

    return TrenKehadiranResponse(
      hari: (json['hari'] as num?)?.toInt() ?? 0,
      tanggalMulai: json['tanggal_mulai']?.toString() ?? '',
      tanggalAkhir: json['tanggal_akhir']?.toString() ?? '',
      data: dataList,
    );
  }
}
