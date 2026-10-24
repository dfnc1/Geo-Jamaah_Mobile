import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/presensi_hari_ini_model.dart';
import 'beranda_controller.dart';

/// Layar Beranda Mahasantri.
/// Menampilkan ringkasan hari ini, jadwal shalat, status presensi real-time,
/// serta tombol presensi saat sedang dalam window waktu.
class MahasantriBerandaScreen extends ConsumerStatefulWidget {
  const MahasantriBerandaScreen({super.key});

  @override
  ConsumerState<MahasantriBerandaScreen> createState() =>
      _MahasantriBerandaScreenState();
}

class _MahasantriBerandaScreenState extends ConsumerState<MahasantriBerandaScreen>
    with WidgetsBindingObserver {
  Timer? _pollingTimer;
  bool _isScreenVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Muat data awal setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(berandaControllerProvider.notifier).loadInitial();
      _startPollingTimer();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPollingTimer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isScreenVisible = true;
      _startPollingTimer();
      // Segera sinkronisasi saat aplikasi kembali ke foreground
      ref.read(berandaControllerProvider.notifier).refreshSilently();
    } else {
      _isScreenVisible = false;
      _stopPollingTimer();
    }
  }

  void _startPollingTimer() {
    _stopPollingTimer();
    if (!_isScreenVisible) return;

    final interval = ref.read(berandaPollingIntervalProvider);
    if (interval == null) return;

    // Muat ulang otomatis berkala tanpa mengosongkan daftar
    _pollingTimer = Timer.periodic(interval, (_) {
      if (mounted && _isScreenVisible) {
        ref.read(berandaControllerProvider.notifier).refreshSilently();
      }
    });
  }

  void _stopPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _onPresensiPressed(BuildContext context, JadwalHariIniModel jadwal) {
    // TODO(M4): Buka layar presensi geofencing kamera/lokasi di Milestone 4
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Presensi segera hadir (${jadwal.namaSholat})'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final berandaState = ref.watch(berandaControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda Presensi'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _buildBody(context, berandaState, user),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    BerandaState state,
    dynamic user,
  ) {
    // Loading awal (saat belum ada data)
    if (state.isLoading && state.data == null) {
      return const LoadingView(
        message: 'Memuat jadwal presensi...',
      );
    }

    // Error awal (saat data kosong dan gagal memuat)
    if (state.errorMessage != null && state.data == null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ErrorBanner(
                title: 'Gagal Memuat Data',
                message: state.errorMessage!,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Coba Lagi',
                icon: Icons.refresh,
                onPressed: () {
                  ref.read(berandaControllerProvider.notifier).loadInitial();
                },
              ),
            ],
          ),
        ),
      );
    }

    final data = state.data;
    if (data == null) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      color: AppColors.emerald,
      onRefresh: () async {
        await ref.read(berandaControllerProvider.notifier).refresh();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        children: [
          // Banner Error jika silent refresh / pull-to-refresh gagal saat data lama masih ada
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) ...[
            ErrorBanner(
              title: 'Peringatan Pembaruan',
              message: state.errorMessage!,
            ),
            const SizedBox(height: 12),
          ],

          // Header Beranda (Sapaan, Nama, NIM, Tanggal, Masjid)
          _HeaderCard(
            nama: user?.namaLengkap ?? user?.displayName ?? 'Mahasantri',
            nim: user?.nim ?? '-',
            tanggalFormatted: data.formattedTanggalIndonesia,
            masjid: data.masjid,
          ),
          const SizedBox(height: 20),

          // Judul Section Jadwal Shalat
          const Row(
            children: [
              Icon(Icons.access_time_filled, size: 20, color: AppColors.emerald),
              SizedBox(width: 8),
              Text(
                'Jadwal Shalat Hari Ini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Daftar Kartu Jadwal Shalat atau EmptyState
          if (data.jadwal.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: EmptyState(
                icon: Icons.calendar_today_outlined,
                title: 'Belum Ada Jadwal',
                message: 'Tidak ada jadwal shalat yang tersedia untuk hari ini.',
              ),
            )
          else
            ...data.jadwal.map(
              (jadwal) => _JadwalCard(
                jadwal: jadwal,
                onPresensiPressed: () => _onPresensiPressed(context, jadwal),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Kartu Header Profil Singkat, Tanggal, dan Masjid
class _HeaderCard extends StatelessWidget {
  final String nama;
  final String nim;
  final String tanggalFormatted;
  final MasjidModel? masjid;

  const _HeaderCard({
    required this.nama,
    required this.nim,
    required this.tanggalFormatted,
    required this.masjid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.emerald,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sapaan & Nama
          Text(
            'Assalamu\'alaikum,',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            nama,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'NIM: $nim',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(
              height: 1,
              color: Colors.white24,
            ),
          ),

          // Tanggal Hari Ini
          Row(
            children: [
              const Icon(
                Icons.calendar_month,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tanggalFormatted,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Informasi Lokasi Masjid Utama
          Row(
            children: [
              Icon(
                masjid != null ? Icons.mosque_outlined : Icons.info_outline,
                size: 16,
                color: masjid != null ? Colors.white : AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  masjid != null
                      ? masjid!.namaMasjid
                      : 'Masjid belum diatur oleh Admin',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: masjid != null ? Colors.white : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kartu Jadwal Shalat
class _JadwalCard extends StatelessWidget {
  final JadwalHariIniModel jadwal;
  final VoidCallback onPresensiPressed;

  const _JadwalCard({
    required this.jadwal,
    required this.onPresensiPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isHighlighted = jadwal.bisaPresensi;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.emerald.withValues(alpha: 0.04)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? AppColors.emerald : AppColors.border,
          width: isHighlighted ? 2.0 : 1.0,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Atas: Nama Shalat & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  jadwal.namaSholat,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isHighlighted
                        ? AppColors.emerald
                        : AppColors.textPrimary,
                  ),
                ),
                StatusBadge(status: jadwal.status.rawValue),
              ],
            ),
            const SizedBox(height: 8),

            // Baris Waktu: Jam Azan & Rentang Presensi
            Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  size: 15,
                  color: AppColors.slate,
                ),
                const SizedBox(width: 6),
                Text(
                  'Azan ${jadwal.waktuAzan}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.slate,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.timer_outlined,
                  size: 15,
                  color: AppColors.slate,
                ),
                const SizedBox(width: 6),
                Text(
                  'Presensi: ${jadwal.rentangPresensi}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.slate,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // Bagian Aksi / Keterangan Netral
            if (isHighlighted) ...[
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Presensi',
                icon: Icons.fingerprint,
                height: 44,
                onPressed: onPresensiPressed,
              ),
            ] else if (jadwal.keteranganNetral != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 14,
                    color: AppColors.slate,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    jadwal.keteranganNetral!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
