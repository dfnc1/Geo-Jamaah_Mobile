import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/musyrif_models.dart';
import 'musyrif_dashboard_controller.dart';

/// Tab Santri Musyrif dengan tiga bagian: Kritis (DSS), Monitoring, Grafik.
class SantriTabScreen extends ConsumerStatefulWidget {
  const SantriTabScreen({super.key});

  @override
  ConsumerState<SantriTabScreen> createState() => _SantriTabScreenState();
}

class _SantriTabScreenState extends ConsumerState<SantriTabScreen> {
  // 0 = Kritis, 1 = Monitoring, 2 = Grafik
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = ref.read(musyrifDashboardControllerProvider.notifier);
      controller.loadKritis();
      controller.loadTren();
      controller.loadMonitoring();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(musyrifDashboardControllerProvider);
    final controller = ref.read(musyrifDashboardControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Santri Binaan'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Segmented control untuk tiga bagian
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 0,
                    icon: Icon(Icons.warning_outlined),
                    label: Text('Kritis'),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: Icon(Icons.table_view_outlined),
                    label: Text('Monitoring'),
                  ),
                  ButtonSegment(
                    value: 2,
                    icon: Icon(Icons.show_chart_outlined),
                    label: Text('Grafik'),
                  ),
                ],
                selected: {_tabIndex},
                onSelectionChanged: (set) => setState(() => _tabIndex = set.first),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildTab(context, state, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    MusyrifDashboardState state,
    MusyrifDashboardController controller,
  ) {
    switch (_tabIndex) {
      case 0:
        return _KritisSection(state: state, controller: controller);
      case 1:
        return _MonitoringSection(state: state, controller: controller);
      case 2:
        return _TrenSection(state: state, controller: controller);
      default:
        return const SizedBox.shrink();
    }
  }
}

// =========================================================================
// Bagian Kritis (DSS)
// =========================================================================

class _KritisSection extends ConsumerWidget {
  const _KritisSection({
    required this.state,
    required this.controller,
  });

  final MusyrifDashboardState state;
  final MusyrifDashboardController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoadingKritis && state.daftarKritis.isEmpty) {
      return const LoadingView(message: 'Memuat data santri kritis...');
    }

    if (state.errorKritis != null &&
        state.errorKritis!.isNotEmpty &&
        state.daftarKritis.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ErrorBanner(
                title: 'Gagal Memuat Data Kritis',
                message: state.errorKritis!,
                onRetry: () => controller.loadKritis(),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Coba Lagi',
                icon: Icons.refresh,
                onPressed: () => controller.loadKritis(),
              ),
            ],
          ),
        ),
      );
    }

    if (state.daftarKritis.isEmpty) {
      return const EmptyState(
        icon: Icons.warning_outlined,
        title: 'Tidak Ada Santri Kritis',
        message:
            'Semua santri binaan memiliki rasio kehadiran di atas batas kritis.',
      );
    }

    final hasError = state.errorKritis != null && state.errorKritis!.isNotEmpty;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => controller.loadKritis(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.daftarKritis.length + (hasError ? 1 : 0),
        itemBuilder: (context, index) {
          if (hasError && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ErrorBanner(
                title: 'Gagal Memperbarui Data Kritis',
                message: state.errorKritis!,
                onRetry: () => controller.loadKritis(),
                onDismiss: () => controller.clearError(),
              ),
            );
          }
          final kritis = state.daftarKritis[hasError ? index - 1 : index];
          return _KritisCard(kritis: kritis);
        },
      ),
    );
  }
}

class _KritisCard extends StatelessWidget {
  final SantriKritis kritis;

  const _KritisCard({required this.kritis});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kritis.nama,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NIM: ${kritis.nim}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Text(
                    'KRITIS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _KritisStat(
                  label: 'Rasio',
                  value: kritis.rasioDisplay,
                  icon: Icons.percent_outlined,
                ),
                const SizedBox(width: 12),
                _KritisStat(
                  label: 'Streak Alpha',
                  value: '${kritis.streakAlpha}',
                  icon: Icons.repeat_outlined,
                ),
                const SizedBox(width: 12),
                _KritisStat(
                  label: 'H / A / I',
                  value:
                      '${kritis.jumlahHadir} / ${kritis.jumlahTidakHadir} / ${kritis.jumlahIzin}',
                  icon: Icons.event_note_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (kritis.alasanTeks.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kritis.alasanTeks
                    .map((a) => Chip(
                          label: Text(
                            a,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          backgroundColor: AppColors.lightGrey,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              kritis.rekomendasiTindakan,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KritisStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _KritisStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.slate),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Bagian Monitoring
// =========================================================================

class _MonitoringSection extends ConsumerWidget {
  const _MonitoringSection({
    required this.state,
    required this.controller,
  });

  final MusyrifDashboardState state;
  final MusyrifDashboardController controller;

  Future<void> _pilihTanggal(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.tanggalMonitoring,
      firstDate: DateTime(now.year - 1),
      lastDate: now, // tidak boleh masa depan
    );
    if (picked != null && context.mounted) {
      await controller.gantiTanggalMonitoring(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoadingMonitoring && state.monitoring == null) {
      return const LoadingView(message: 'Memuat monitoring...');
    }

    if (state.errorMonitoring != null &&
        state.errorMonitoring!.isNotEmpty &&
        state.monitoring == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ErrorBanner(
                title: 'Gagal Memuat Monitoring',
                message: state.errorMonitoring!,
                onRetry: () => controller.gantiTanggalMonitoring(
                  state.tanggalMonitoring ?? DateTime.now(),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Coba Lagi',
                icon: Icons.refresh,
                onPressed: () => state.tanggalMonitoring != null
                    ? controller
                        .gantiTanggalMonitoring(state.tanggalMonitoring!)
                    : null,
              ),
            ],
          ),
        ),
      );
    }

    final monitoring = state.monitoring;
    final tm = state.tanggalMonitoring ?? DateTime.now();
    final tanggal = monitoring?.tanggal ??
        '${tm.year}-${tm.month.toString().padLeft(2, '0')}-${tm.day.toString().padLeft(2, '0')}';

    return Column(
      children: [
        // Pilih tanggal
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tanggal: $tanggal',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _pilihTanggal(context),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: const Text('Ganti Tanggal'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.emerald,
                  side: const BorderSide(color: AppColors.emerald, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 38),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Error saat ganti tanggal sementara data lama masih tampil
        if (state.errorMonitoring != null &&
            state.errorMonitoring!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ErrorBanner(
              title: 'Gagal Memperbarui Monitoring',
              message: state.errorMonitoring!,
              onDismiss: () => controller.clearError(),
            ),
          ),
        ],

        // Ringkasan jumlah per status
        if (monitoring != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _RingkasanRow(ringkasan: monitoring.ringkasan),
          ),
        const SizedBox(height: 12),

        // Tabel santri x jadwal
        Expanded(
          child: monitoring == null
              ? const EmptyState(
                  icon: Icons.table_view_outlined,
                  title: 'Tidak Ada Data Monitoring',
                  message: 'Pilih tanggal untuk melihat monitoring presensi.',
                )
              : _MonitoringTable(monitoring: monitoring),
        ),
      ],
    );
  }
}

class _RingkasanRow extends StatelessWidget {
  final MonitoringRingkasan ringkasan;

  const _RingkasanRow({required this.ringkasan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ringkasan Kehadiran',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Total: ${ringkasan.total} sel',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _RingkasanStat(
                  label: 'Hadir',
                  value: '${ringkasan.hadir}',
                  color: AppColors.success,
                  bgColor: AppColors.success.withValues(alpha: 0.08),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RingkasanStat(
                  label: 'Tidak Hadir',
                  value: '${ringkasan.tidakHadir}',
                  color: AppColors.error,
                  bgColor: AppColors.error.withValues(alpha: 0.08),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RingkasanStat(
                  label: 'Izin',
                  value: '${ringkasan.izin}',
                  color: const Color(0xFFD39E00),
                  bgColor: const Color(0xFFD39E00).withValues(alpha: 0.08),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _RingkasanStat(
                  label: 'Manual',
                  value: '${ringkasan.manual}',
                  color: AppColors.accent,
                  bgColor: AppColors.accent.withValues(alpha: 0.08),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _RingkasanStat(
                  label: 'Belum',
                  value: '${ringkasan.belum}',
                  color: AppColors.slate,
                  bgColor: AppColors.lightGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingkasanStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _RingkasanStat({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MonitoringTable extends StatelessWidget {
  final MonitoringResponse monitoring;

  const _MonitoringTable({required this.monitoring});

  @override
  Widget build(BuildContext context) {
    final jadwal = monitoring.jadwal;
    final santri = monitoring.santri;

    if (santri.isEmpty) {
      return const EmptyState(
        icon: Icons.table_view_outlined,
        title: 'Tidak Ada Santri',
        message: 'Tidak ada santri binaan aktif untuk tanggal ini.',
      );
    }

    const colWidthNama = 130.0;
    const colWidthJadwal = 90.0;
    final totalWidth = colWidthNama + (jadwal.length * colWidthJadwal) + 32.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalWidth < MediaQuery.of(context).size.width
            ? MediaQuery.of(context).size.width
            : totalWidth,
        child: Column(
          children: [
            // Header tabel
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.lightGrey,
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: colWidthNama,
                    child: Text(
                      'Nama Santri',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  for (final j in jadwal)
                    SizedBox(
                      width: colWidthJadwal,
                      child: Text(
                        j.namaSholat,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Isi tabel: satu baris per santri
            Expanded(
              child: ListView.builder(
                itemCount: santri.length,
                itemBuilder: (context, index) {
                  final s = santri[index];
                  return _MonitoringBaris(
                    santri: s,
                    jadwal: jadwal,
                    colWidthNama: colWidthNama,
                    colWidthJadwal: colWidthJadwal,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonitoringBaris extends StatelessWidget {
  final MonitoringSantri santri;
  final List<MonitoringJadwal> jadwal;
  final double colWidthNama;
  final double colWidthJadwal;

  const _MonitoringBaris({
    required this.santri,
    required this.jadwal,
    required this.colWidthNama,
    required this.colWidthJadwal,
  });

  @override
  Widget build(BuildContext context) {
    // Map status per id_jadwal untuk akses cepat
    final statusByJadwal = <String, String>{};
    for (final st in santri.status) {
      statusByJadwal[st.idJadwal] = st.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.lightGrey),
        ),
      ),
      child: Row(
        children: [
          // Kolom nama santri (tetap)
          SizedBox(
            width: colWidthNama,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  santri.nama,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  santri.nim,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Satu sel per jadwal
          for (final j in jadwal)
            SizedBox(
              width: colWidthJadwal,
              child: Center(
                child: StatusBadge(
                  status: statusByJadwal[j.idJadwal] ?? 'Belum',
                  small: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =========================================================================
// Bagian Grafik Tren Kehadiran
// =========================================================================

class _TrenSection extends ConsumerWidget {
  const _TrenSection({
    required this.state,
    required this.controller,
  });

  final MusyrifDashboardState state;
  final MusyrifDashboardController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoadingTren && state.tren == null) {
      return const LoadingView(message: 'Memuat grafik tren...');
    }

    if (state.errorTren != null &&
        state.errorTren!.isNotEmpty &&
        state.tren == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ErrorBanner(
                title: 'Gagal Memuat Grafik',
                message: state.errorTren!,
                onRetry: () => controller.loadTren(),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Coba Lagi',
                icon: Icons.refresh,
                onPressed: () => controller.loadTren(),
              ),
            ],
          ),
        ),
      );
    }

    final tren = state.tren;

    return Column(
      children: [
        // Pilihan jumlah hari
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              const Text(
                'Rentang: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              ..._pilihHari(context, state.tren?.hari ?? 7),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (state.errorTren != null && state.errorTren!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ErrorBanner(
              title: 'Gagal Memperbarui Grafik',
              message: state.errorTren!,
              onDismiss: () => controller.clearError(),
            ),
          ),
        ],

        // Grafik garis
        Expanded(
          child: tren == null || tren.data.isEmpty
              ? const EmptyState(
                  icon: Icons.show_chart_outlined,
                  title: 'Tidak Ada Data Grafik',
                  message: 'Data tren kehadiran belum tersedia.',
                )
              : TrenGrafik(data: tren.data),
        ),
      ],
    );
  }

  List<Widget> _pilihHari(BuildContext context, int aktif) {
    final daftar = <int>[7, 14, 30];
    return daftar.map((h) {
      final selected = h == aktif;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text('$h hari'),
          selected: selected,
          onSelected: (_) => controller.loadTren(hari: h),
          selectedColor: AppColors.accent.withValues(alpha: 0.15),
          backgroundColor: AppColors.lightGrey,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      );
    }).toList();
  }
}
