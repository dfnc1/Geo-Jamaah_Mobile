import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client/api_client.dart';
import '../domain/musyrif_models.dart';

final musyrifDashboardRepositoryProvider =
    Provider<MusyrifDashboardRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MusyrifDashboardRepository(apiClient: apiClient);
});

/// Repository untuk dashboard Musyrif (DSS, monitoring, tren kehadiran).
class MusyrifDashboardRepository {
  final ApiClient apiClient;

  MusyrifDashboardRepository({required this.apiClient});

  /// Mengambil daftar santri kritis.
  /// Endpoint: GET /v1/musyrif/dss/santri-kritis
  Future<List<SantriKritis>> getSantriKritis() async {
    final response = await apiClient.get<dynamic>('/v1/musyrif/dss/santri-kritis');
    if (response.data is List) {
      final list = response.data as List;
      final items = <SantriKritis>[];
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          items.add(SantriKritis.fromJson(item));
        }
      }
      return items;
    }
    throw const FormatException('Format respons santri kritis tidak valid');
  }

  /// Mengambil monitoring presensi per tanggal.
  /// Endpoint: GET /v1/musyrif/presensi/monitoring?tanggal=
  Future<MonitoringResponse> getMonitoring({required String tanggal}) async {
    final response = await apiClient.get<dynamic>(
      '/v1/musyrif/presensi/monitoring',
      queryParameters: {'tanggal': tanggal},
    );
    if (response.data is Map<String, dynamic>) {
      return MonitoringResponse.fromJson(response.data as Map<String, dynamic>);
    }
    throw const FormatException('Format respons monitoring tidak valid');
  }

  /// Mengambil tren kehadiran.
  /// Endpoint: GET /v1/musyrif/dashboard/tren-kehadiran?hari=
  Future<TrenKehadiranResponse> getTrenKehadiran({int? hari}) async {
    final queryParameters = <String, dynamic>{};
    if (hari != null) queryParameters['hari'] = hari;

    final response = await apiClient.get<dynamic>(
      '/v1/musyrif/dashboard/tren-kehadiran',
      queryParameters: queryParameters,
    );
    if (response.data is Map<String, dynamic>) {
      return TrenKehadiranResponse.fromJson(response.data as Map<String, dynamic>);
    }
    throw const FormatException('Format respons tren kehadiran tidak valid');
  }
}
