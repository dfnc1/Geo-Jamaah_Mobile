import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client/api_client.dart';
import '../domain/izin_musyrif_model.dart';

final izinMusyrifRepositoryProvider = Provider<IzinMusyrifRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return IzinMusyrifRepository(apiClient: apiClient);
});

/// Repository untuk fitur Verifikasi Izin Musyrif.
/// Endpoint: GET /v1/musyrif/izin?status= dan PATCH /v1/musyrif/izin/:id_izin/verify
class IzinMusyrifRepository {
  final ApiClient apiClient;

  IzinMusyrifRepository({required this.apiClient});

  /// Mengambil daftar izin santri binaan Musyrif.
  /// Endpoint: GET /v1/musyrif/izin?status=
  /// [status] opsional: Pending | Disetujui | Ditolak, atau null untuk semua.
  Future<List<IzinMusyrifItem>> getIzinBinaan({String? status}) async {
    final queryParameters = <String, dynamic>{};
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }

    final response = await apiClient.get<dynamic>(
      '/v1/musyrif/izin',
      queryParameters: queryParameters,
    );
    if (response.data is List) {
      final list = response.data as List;
      final items = <IzinMusyrifItem>[];
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          items.add(IzinMusyrifItem.fromJson(item));
        }
      }
      return items;
    }
    throw const FormatException('Format respons daftar izin binaan tidak valid');
  }

  /// Memverifikasi (setujui/tolak) izin.
  /// Endpoint: PATCH /v1/musyrif/izin/:id_izin/verify
  /// [statusBaru] harus "Disetujui" atau "Ditolak" (bukan Pending).
  Future<IzinMusyrifItem> verifikasiIzin({
    required String idIzin,
    required String statusBaru,
  }) async {
    final response = await apiClient.patch<dynamic>(
      '/v1/musyrif/izin/${Uri.encodeComponent(idIzin)}/verify',
      data: {'status_persetujuan': statusBaru},
    );
    if (response.data is Map<String, dynamic>) {
      return IzinMusyrifItem.fromJson(response.data as Map<String, dynamic>);
    }
    throw const FormatException('Format respons verifikasi izin tidak valid');
  }
}
