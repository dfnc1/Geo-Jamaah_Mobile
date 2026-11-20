/// Ringkasan Presensi Global dari GET /v1/admin/rekap
class PresensiRekap {
  final int hadir;
  final int tidakHadir;
  final int izin;
  final int manual;
  final int total;

  const PresensiRekap({
    required this.hadir,
    required this.tidakHadir,
    required this.izin,
    required this.manual,
    required this.total,
  });

  factory PresensiRekap.fromJson(Map<String, dynamic> json) {
    return PresensiRekap(
      hadir: (json['hadir'] as num?)?.toInt() ?? 0,
      tidakHadir: (json['tidak_hadir'] as num?)?.toInt() ?? 0,
      izin: (json['izin'] as num?)?.toInt() ?? 0,
      manual: (json['manual'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Ringkasan Izin Global dari GET /v1/admin/rekap
class IzinRekap {
  final int pending;
  final int disetujui;
  final int ditolak;
  final int total;

  const IzinRekap({
    required this.pending,
    required this.disetujui,
    required this.ditolak,
    required this.total,
  });

  factory IzinRekap.fromJson(Map<String, dynamic> json) {
    return IzinRekap(
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      disetujui: (json['disetujui'] as num?)?.toInt() ?? 0,
      ditolak: (json['ditolak'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Model respons GET /v1/admin/rekap
class AdminRekap {
  final int jumlahSantriAktif;
  final PresensiRekap presensi;
  final IzinRekap izin;
  final int jumlahSantriKritis;

  const AdminRekap({
    required this.jumlahSantriAktif,
    required this.presensi,
    required this.izin,
    required this.jumlahSantriKritis,
  });

  factory AdminRekap.fromJson(Map<String, dynamic> json) {
    return AdminRekap(
      jumlahSantriAktif: (json['jumlah_santri_aktif'] as num?)?.toInt() ?? 0,
      presensi: PresensiRekap.fromJson(
        json['presensi'] is Map<String, dynamic>
            ? json['presensi'] as Map<String, dynamic>
            : <String, dynamic>{},
      ),
      izin: IzinRekap.fromJson(
        json['izin'] is Map<String, dynamic>
            ? json['izin'] as Map<String, dynamic>
            : <String, dynamic>{},
      ),
      jumlahSantriKritis:
          (json['jumlah_santri_kritis'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Model respons POST /v1/admin/mahasantri/:nim/reset-device
class ResetDeviceResult {
  final String nim;
  final String nama;
  final String username;
  final String? deviceId;

  const ResetDeviceResult({
    required this.nim,
    required this.nama,
    required this.username,
    this.deviceId,
  });

  factory ResetDeviceResult.fromJson(Map<String, dynamic> json) {
    return ResetDeviceResult(
      nim: json['nim']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      deviceId: json['device_id']?.toString(),
    );
  }
}

/// Model respons POST /v1/admin/jobs/tandai-tidak-hadir
class JobTandaiResult {
  final String tanggal;
  final String? idJadwal;
  final int tidakHadir;
  final int izin;
  final int totalDibuat;

  const JobTandaiResult({
    required this.tanggal,
    this.idJadwal,
    required this.tidakHadir,
    required this.izin,
    required this.totalDibuat,
  });

  factory JobTandaiResult.fromJson(Map<String, dynamic> json) {
    final dibuat = json['dibuat'] is Map<String, dynamic>
        ? json['dibuat'] as Map<String, dynamic>
        : <String, dynamic>{};
    return JobTandaiResult(
      tanggal: json['tanggal']?.toString() ?? '',
      idJadwal: json['id_jadwal']?.toString(),
      tidakHadir: (dibuat['Tidak_Hadir'] as num?)?.toInt() ?? 0,
      izin: (dibuat['Izin'] as num?)?.toInt() ?? 0,
      totalDibuat: (json['total_dibuat'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Model satu log pada GET /v1/admin/activity-logs
class ActivityLogItem {
  final String idLog;
  final String username;
  final String role;
  final String modul;
  final String aktivitas;
  final String createdAt;

  const ActivityLogItem({
    required this.idLog,
    required this.username,
    required this.role,
    required this.modul,
    required this.aktivitas,
    required this.createdAt,
  });

  factory ActivityLogItem.fromJson(Map<String, dynamic> json) {
    return ActivityLogItem(
      idLog: json['id_log']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      modul: json['modul']?.toString() ?? '',
      aktivitas: json['aktivitas']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

/// Model respons paginasi GET /v1/admin/activity-logs
class ActivityLogResponse {
  final List<ActivityLogItem> logs;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const ActivityLogResponse({
    required this.logs,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory ActivityLogResponse.fromJson(Map<String, dynamic> json) {
    final logsRaw = json['logs'];
    final List<ActivityLogItem> list = [];
    if (logsRaw is List) {
      for (final item in logsRaw) {
        if (item is Map<String, dynamic>) {
          list.add(ActivityLogItem.fromJson(item));
        }
      }
    }

    final pagination = json['pagination'] is Map<String, dynamic>
        ? json['pagination'] as Map<String, dynamic>
        : <String, dynamic>{};

    return ActivityLogResponse(
      logs: list,
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      limit: (pagination['limit'] as num?)?.toInt() ?? 20,
      total: (pagination['total'] as num?)?.toInt() ?? 0,
      totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 0,
    );
  }
}
