import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client/api_client.dart';
import '../domain/presensi_models.dart';

final presensiRepositoryProvider = Provider<PresensiRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PresensiRepository(apiClient: apiClient);
});

class PresensiRepository {
  final ApiClient apiClient;

  PresensiRepository({required this.apiClient});

  /// Mengirim data presensi ke server.
  /// Endpoint: POST /v1/presensi
  /// Server yang menghitung jarak, window waktu, dan status.
  Future<PresensiResult> postPresensi(PresensiRequest request) async {
    final response = await apiClient.post<dynamic>(
      '/v1/presensi',
      data: request.toJson(),
    );
    if (response.data is Map<String, dynamic>) {
      return PresensiResult.fromJson(response.data as Map<String, dynamic>);
    }
    throw const FormatException('Format respons presensi tidak valid');
  }
}
