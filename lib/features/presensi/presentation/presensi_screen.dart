import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import 'presensi_controller.dart';

/// Layar presensi geofencing.
///
/// Dibuka dari kartu jadwal beranda dengan membawa [PresensiArgs].
/// Tidak ada logika jarak/window/status di aplikasi — semua dilakukan server.
///
/// Alur:
///   1. periksaIzin   -> minta ACCESS_FINE_LOCATION
///   2. ambilPosisi   -> getCurrentPosition (akurasi tinggi, timeout 20 detik)
///   3. akurasiKurang -> jika akurasi > 50 m, jangan kirim, minta ambil ulang
///   4. mengirim      -> POST /v1/presensi
///   5. berhasil / sudahPresensi / error
class PresensiScreen extends ConsumerStatefulWidget {
  final PresensiArgs args;

  const PresensiScreen({super.key, required this.args});

  @override
  ConsumerState<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends ConsumerState<PresensiScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(presensiControllerProvider.notifier).mulai(widget.args);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(presensiControllerProvider);
    final args = widget.args;

    return Scaffold(
      appBar: AppBar(
        title: Text('Presensi ${args.namaSholat}'),
        // Tombol kembali bawaan AppBar selalu tersedia
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: _buildBody(context, state, args),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PresensiState state,
    PresensiArgs args,
  ) {
    switch (state.tahap) {
      case TahapPresensi.periksaIzin:
        return _buildLoading(
          icon: Icons.location_searching,
          pesan: 'Memeriksa izin lokasi...',
        );

      case TahapPresensi.ambilPosisi:
        return _buildAmbilPosisi(state);

      case TahapPresensi.akurasiKurang:
        return _buildAkurasiKurang(state, args);

      case TahapPresensi.mengirim:
        return _buildLoading(
          icon: Icons.cloud_upload_outlined,
          pesan: 'Mengirim data presensi ke server...',
        );

      case TahapPresensi.berhasil:
        return _buildBerhasil(context, state);

      case TahapPresensi.sudahPresensi:
        return _buildSudahPresensi(context, state);

      case TahapPresensi.error:
        return _buildError(context, state, args);
    }
  }

  // ── Tahap: Loading ───────────────────────────────────────────────────────

  Widget _buildLoading({required IconData icon, required String pesan}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.emerald),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: AppColors.emerald),
          const SizedBox(height: 20),
          Text(
            pesan,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tahap: Ambil Posisi ──────────────────────────────────────────────────

  Widget _buildAmbilPosisi(PresensiState state) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.gps_fixed, size: 64, color: AppColors.emerald),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: AppColors.emerald),
          const SizedBox(height: 20),
          const Text(
            'Mengambil lokasi...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (state.akurasiSaatIni != null) ...[
            Text(
              'Akurasi saat ini: ${state.akurasiSaatIni!.toStringAsFixed(0)} m',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ] else ...[
            const Text(
              'Menunggu sinyal GPS...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Aplikasi memerlukan lokasi untuk memastikan\nAnda berada di area masjid.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.slate,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tahap: Akurasi Kurang ────────────────────────────────────────────────

  Widget _buildAkurasiKurang(PresensiState state, PresensiArgs args) {
    final akurasi = state.akurasiSaatIni ?? 0;
    final isBusy = ref.watch(presensiControllerProvider.notifier).isProcessing;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.gps_not_fixed, size: 64, color: AppColors.warning),
          const SizedBox(height: 20),
          const Text(
            'Akurasi GPS Kurang Baik',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              'Akurasi GPS kurang baik (${akurasi.toStringAsFixed(0)} m).\nPindah ke area terbuka lalu coba lagi.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Ambil Ulang Lokasi',
            icon: Icons.refresh,
            onPressed: isBusy
                ? null
                : () => ref
                    .read(presensiControllerProvider.notifier)
                    .cobaLagi(args),
          ),
        ],
      ),
    );
  }

  // ── Tahap: Berhasil (Hanya jika benar-benar baru dicatat) ─────────────────

  Widget _buildBerhasil(BuildContext context, PresensiState state) {
    final hasil = state.hasil;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 52,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Presensi Berhasil!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 12),
          if (hasil != null) ...[
            _InfoRow(
              icon: Icons.mosque_outlined,
              label: 'Shalat',
              value: hasil.namaSholat,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.straighten,
              label: 'Jarak ke masjid',
              value: '${hasil.jarakMeter.toStringAsFixed(1)} m',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.verified_outlined,
              label: 'Status',
              value: hasil.statusPresensi,
            ),
          ],
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Kembali ke Beranda',
            icon: Icons.home_outlined,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  // ── Tahap: Sudah Presensi (ERR_ALREADY_PRESENT: Netral, Bukan Sukses) ─────

  Widget _buildSudahPresensi(BuildContext context, PresensiState state) {
    final pesan = state.pesanError ?? 'Anda sudah presensi untuk shalat ini.';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              size: 52,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sudah Presensi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              pesan,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Kembali ke Beranda',
            icon: Icons.home_outlined,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  // ── Tahap: Error ─────────────────────────────────────────────────────────

  Widget _buildError(
    BuildContext context,
    PresensiState state,
    PresensiArgs args,
  ) {
    final jenisError = state.jenisError ?? JenisErrorPresensi.lainnya;
    final pesan = state.pesanError ?? 'Terjadi kesalahan pada sistem.';
    final isBusy = ref.watch(presensiControllerProvider.notifier).isProcessing;

    IconData iconError;
    Color iconColor;
    switch (jenisError) {
      case JenisErrorPresensi.izinDitolak:
      case JenisErrorPresensi.izinPermanen:
        iconError = Icons.location_off_outlined;
        iconColor = AppColors.error;
        break;
      case JenisErrorPresensi.gpsNonaktif:
        iconError = Icons.gps_off_outlined;
        iconColor = AppColors.warning;
        break;
      case JenisErrorPresensi.gpsGagal:
        iconError = Icons.signal_wifi_off_outlined;
        iconColor = AppColors.warning;
        break;
      case JenisErrorPresensi.lainnya:
        iconError = Icons.error_outline;
        iconColor = AppColors.error;
        break;
    }

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconError, size: 64, color: iconColor),
            const SizedBox(height: 20),
            Text(
              _judulError(jenisError),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                pesan,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ..._tombolError(context, jenisError, args, isBusy),
          ],
        ),
      ),
    );
  }

  String _judulError(JenisErrorPresensi jenis) {
    switch (jenis) {
      case JenisErrorPresensi.izinDitolak:
        return 'Izin Lokasi Diperlukan';
      case JenisErrorPresensi.izinPermanen:
        return 'Izin Lokasi Diblokir';
      case JenisErrorPresensi.gpsNonaktif:
        return 'GPS Tidak Aktif';
      case JenisErrorPresensi.gpsGagal:
        return 'Gagal Mengambil Lokasi';
      case JenisErrorPresensi.lainnya:
        return 'Presensi Gagal';
    }
  }

  List<Widget> _tombolError(
    BuildContext context,
    JenisErrorPresensi jenis,
    PresensiArgs args,
    bool isBusy,
  ) {
    switch (jenis) {
      case JenisErrorPresensi.izinDitolak:
        return [
          PrimaryButton(
            label: 'Coba Lagi',
            icon: Icons.refresh,
            onPressed: isBusy
                ? null
                : () => ref
                    .read(presensiControllerProvider.notifier)
                    .cobaLagi(args),
          ),
        ];
      case JenisErrorPresensi.izinPermanen:
        return [
          PrimaryButton(
            label: 'Buka Pengaturan',
            icon: Icons.settings,
            onPressed: isBusy
                ? null
                : () => ref
                    .read(presensiControllerProvider.notifier)
                    .bukaSettingAplikasi(),
          ),
        ];
      case JenisErrorPresensi.gpsNonaktif:
        return [
          PrimaryButton(
            label: 'Buka Pengaturan Lokasi',
            icon: Icons.location_on_outlined,
            onPressed: isBusy
                ? null
                : () => ref
                    .read(presensiControllerProvider.notifier)
                    .bukaSettingLokasi(),
          ),
        ];
      case JenisErrorPresensi.gpsGagal:
        return [
          PrimaryButton(
            label: 'Coba Lagi',
            icon: Icons.refresh,
            onPressed: isBusy
                ? null
                : () => ref
                    .read(presensiControllerProvider.notifier)
                    .cobaLagi(args),
          ),
        ];
      case JenisErrorPresensi.lainnya:
        return [
          PrimaryButton(
            label: 'Coba Lagi',
            icon: Icons.refresh,
            onPressed: isBusy
                ? null
                : () => ref
                    .read(presensiControllerProvider.notifier)
                    .cobaLagi(args),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: isBusy ? null : () => Navigator.of(context).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ];
    }
  }
}

/// Baris info kecil (ikon + label + nilai) di layar berhasil.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.slate),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
