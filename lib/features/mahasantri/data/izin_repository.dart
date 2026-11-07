import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client/api_client.dart';
import '../domain/izin_model.dart';

final izinRepositoryProvider = Provider<IzinRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return IzinRepository(apiClient: apiClient);
});

/// Repository untuk fitur Izin Mahasantri.
/// Endpoint: POST /v1/izin dan GET /v1/izin/saya
class IzinRepository {
  final ApiClient apiClient;

  IzinRepository({required this.apiClient});

  /// Mengajukan izin baru. Endpoint: POST /v1/izin
  Future<IzinResult> ajukanIzin(IzinRequest request) async {
    final response = await apiClient.post<dynamic>(
      '/v1/izin',
      data: request.toJson(),
    );
    if (response.data is Map<String, dynamic>) {
      return IzinResult.fromJson(response.data as Map<String, dynamic>);
    }
    throw const FormatException('Format respons pengajuan izin tidak valid');
  }

  /// Mengambil daftar izin milik sendiri. Endpoint: GET /v1/izin/saya
  /// Dikutirkan terbaru dulu (tanggal_izin menurun) oleh server.
  Future<List<IzinItem>> getIzinSaya() async {
    final response = await apiClient.get<dynamic>('/v1/izin/saya');
    if (response.data is List) {
      final list = response.data as List;
      final items = <IzinItem>[];
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          items.add(IzinItem.fromJson(item));
        }
      }
      return items;
    }
    throw const FormatException('Format respons daftar izin tidak valid');
  }
}
