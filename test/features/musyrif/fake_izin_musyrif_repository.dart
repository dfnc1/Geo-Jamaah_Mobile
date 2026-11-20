import 'package:geo_jamaah/core/app_exception/app_exception.dart';
import 'package:geo_jamaah/features/musyrif/data/izin_musyrif_repository.dart';
import 'package:geo_jamaah/features/musyrif/domain/izin_musyrif_model.dart';

/// Fake repository untuk tes Musyrif. Menyimpan daftar izin dalam memori
/// dan mendukung override verifikasi + pemaksaan error.
class FakeIzinMusyrifRepository extends IzinMusyrifRepository {
  List<IzinMusyrifItem> daftar = [];
  AppException? error;
  String? lastStatusBaru;
  String? lastIdIzin;

  FakeIzinMusyrifRepository({required super.apiClient});

  @override
  Future<List<IzinMusyrifItem>> getIzinBinaan({String? status}) async {
    if (error != null) throw error!;
    return daftar.where((i) {
      if (status == null) return true;
      return i.statusPersetujuan == status;
    }).toList();
  }

  @override
  Future<IzinMusyrifItem> verifikasiIzin({
    required String idIzin,
    required String statusBaru,
  }) async {
    lastIdIzin = idIzin;
    lastStatusBaru = statusBaru;
    if (error != null) throw error!;
    final idx = daftar.indexWhere((i) => i.idIzin == idIzin);
    if (idx == -1) {
      throw AppException(
        code: 'ERR_IZIN_NOT_FOUND',
        message: 'Izin tidak ditemukan',
        status: 404,
      );
    }
    final baru = IzinMusyrifItem(
      idIzin: daftar[idx].idIzin,
      nim: daftar[idx].nim,
      namaMahasantri: daftar[idx].namaMahasantri,
      jenisIzin: daftar[idx].jenisIzin,
      tanggalIzin: daftar[idx].tanggalIzin,
      alasan: daftar[idx].alasan,
      buktiLampiran: daftar[idx].buktiLampiran,
      statusPersetujuan: statusBaru,
    );
    daftar[idx] = baru;
    return baru;
  }
}
