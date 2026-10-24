import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client/api_client.dart';
import '../domain/presensi_hari_ini_model.dart';

final mahasantriRepositoryProvider = Provider<MahasantriRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MahasantriRepository(apiClient: apiClient);
});

class MahasantriRepository {
  final ApiClient apiClient;

  MahasantriRepository({required this.apiClient});

  /// Mengambil data presensi & jadwal shalat hari ini untuk santri login.
  /// Endpoint: GET /v1/presensi/hari-ini
  Future<PresensiHariIniResponse> getPresensiHariIni() async {
    final response = await apiClient.get<dynamic>('/v1/presensi/hari-ini');
    if (response.data is Map<String, dynamic>) {
      return PresensiHariIniResponse.fromJson(response.data as Map<String, dynamic>);
    } else {
      throw const FormatException('Format respons presensi hari ini tidak valid');
    }
  }
}
