import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client/api_client.dart';
import '../../musyrif/domain/musyrif_models.dart';
import '../domain/admin_models.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminRepository(apiClient: apiClient);
});

class AdminRepository {
  final ApiClient apiClient;

  AdminRepository({required this.apiClient});

  /// GET /v1/admin/rekap
  Future<AdminRekap> getRekap() async {
    final response = await apiClient.get<dynamic>('/v1/admin/rekap');
    if (response.data is Map<String, dynamic>) {
      return AdminRekap.fromJson(response.data as Map<String, dynamic>);
    }
    throw const FormatException('Format respons rekap admin tidak valid');
  }

  /// GET /v1/admin/dashboard/tren-kehadiran?hari=7
  Future<TrenKehadiranResponse> getTrenKehadiran({int hari = 7}) async {
    final response = await apiClient.get<dynamic>(
      '/v1/admin/dashboard/tren-kehadiran',
      queryParameters: {'hari': hari},
    );
    if (response.data is Map<String, dynamic>) {
      return TrenKehadiranResponse.fromJson(response.data as Map<String, dynamic>);
    }
    throw const FormatException('Format respons tren kehadiran admin tidak valid');
  }

  /// POST /v1/admin/mahasantri/:nim/reset-device
  Future<ResetDeviceResult> resetDevice(String nim) async {
    final response = await apiClient.post<dynamic>(
      '/v1/admin/mahasantri/$nim/reset-device',
    );
    if (response.data is Map<String, dynamic>) {
      return ResetDeviceResult.fromJson(response.data as Map<String, dynamic>);
    }
    throw const FormatException('Format respons reset device tidak valid');
  }

  /// POST /v1/admin/jobs/tandai-tidak-hadir
  Future<JobTandaiResult> triggerJobTandai({String? tanggal, String? idJadwal}) async {
    final data = <String, dynamic>{};
    if (tanggal != null && tanggal.trim().isNotEmpty) {
      data['tanggal'] = tanggal.trim();
    }
    if (idJadwal != null && idJadwal.trim().isNotEmpty) {
      data['id_jadwal'] = idJadwal.trim();
    }

    final response = await apiClient.post<dynamic>(
      '/v1/admin/jobs/tandai-tidak-hadir',
      data: data.isNotEmpty ? data : null,
    );
    if (response.data is Map<String, dynamic>) {
      return JobTandaiResult.fromJson(response.data as Map<String, dynamic>);
    }
    throw const FormatException('Format respons job tandai tidak valid');
  }

  /// GET /v1/admin/activity-logs
  Future<ActivityLogResponse> getActivityLogs({
    int page = 1,
    int limit = 20,
    String? modul,
    String? role,
    String? from,
    String? to,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (modul != null && modul.isNotEmpty && modul != 'Semua') {
      params['modul'] = modul;
    }
    if (role != null && role.isNotEmpty) {
      params['role'] = role;
    }
    if (from != null && from.isNotEmpty) {
      params['from'] = from;
    }
    if (to != null && to.isNotEmpty) {
      params['to'] = to;
    }

    final response = await apiClient.get<dynamic>(
      '/v1/admin/activity-logs',
      queryParameters: params,
    );
    if (response.data is Map<String, dynamic>) {
      return ActivityLogResponse.fromJson(response.data as Map<String, dynamic>);
    }
    throw const FormatException('Format respons activity logs tidak valid');
  }
}
