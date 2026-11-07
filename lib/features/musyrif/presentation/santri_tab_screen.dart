import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
      final controller = ref.read(musyrifDashboardControllerProvider.notifier);
      controller.loadKritis();
      controller.loadTren();
      final today = DateTime.now();
      final formatted = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      controller.loadMonitoring(formatted);
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
            child: SegmentedButton<int>(
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

    if (state.errorMessage != null &&
        state.errorMessage!.isNotEmpty &&
        state.daftarKritis.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ErrorBanner(
              title: 'Gagal Memuat Data Kritis',
              message: state.errorMessage!,
              onRetry: () => controller.loadKritis(),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Coba Lagi',
              icon: Icons.refresh,
              onPressed: () => controller.loadKritis(),
            ),
          ],
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

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => controller.loadKritis(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.daftarKritis.length,
        itemBuilder: (context, index) {
          final kritis = state.daftarKritis[index];
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.slate),
              const SizedBox(width: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
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

    if (state.errorMessage != null &&
        state.errorMessage!.isNotEmpty &&
        state.monitoring == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ErrorBanner(
              title: 'Gagal Memuat Monitoring',
              message: state.errorMessage!,
              onRetry: () => controller.gantiTanggalMonitoring(
                state.tanggalMonitoring ?? DateTime.now(),
              ),
            ),
            const SizedBox(height: 20),
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
              Text(
                'Tanggal: $tanggal',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Ganti Tanggal',
                icon: Icons.calendar_today,
                isOutlined: true,
                width: 130,
                height: 40,
                onPressed: () => _pilihTanggal(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

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
    final total = ringkasan.total;
    return Row(
      children: [
        _RingkasanStat(
          label: 'Hadir',
          value: '${ringkasan.hadir}',
          color: AppColors.success,
        ),
        const SizedBox(width: 12),
        _RingkasanStat(
          label: 'Tidak Hadir',
          value: '${ringkasan.tidakHadir}',
          color: AppColors.error,
        ),
        const SizedBox(width: 12),
        _RingkasanStat(
          label: 'Izin',
          value: '${ringkasan.izin}',
          color: const Color(0xFFD39E00),
        ),
        const SizedBox(width: 12),
        _RingkasanStat(
          label: 'Belum',
          value: '${ringkasan.belum}',
          color: AppColors.slate,
        ),
        const Spacer(),
        Text(
          'Total sel: $total',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _RingkasanStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RingkasanStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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

    return Column(
      children: [
        // Header tabel (kolom nama + satu kolom per jadwal)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppTheme.borderRadius),
              topRight: Radius.circular(AppTheme.borderRadius),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 110),
              for (final j in jadwal)
                Expanded(
                  child: Text(
                    j.namaSholat,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Isi tabel: satu baris per santri
        Expanded(
          child: santri.isEmpty
              ? const EmptyState(
                  icon: Icons.table_view_outlined,
                  title: 'Tidak Ada Santri',
                  message: 'Tidak ada santri binaan aktif untuk tanggal ini.',
                )
              : ListView.builder(
                  itemCount: santri.length,
                  itemBuilder: (context, index) {
                    final s = santri[index];
                    return _MonitoringBaris(
                      santri: s,
                      jadwal: jadwal,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MonitoringBaris extends StatelessWidget {
  final MonitoringSantri santri;
  final List<MonitoringJadwal> jadwal;

  const _MonitoringBaris({required this.santri, required this.jadwal});

  @override
  Widget build(BuildContext context) {
    // Map status per id_jadwal untuk akses cepat
    final statusByJadwal = <String, String>{};
    for (final st in santri.status) {
      statusByJadwal[st.idJadwal] = st.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.lightGrey),
        ),
      ),
      child: Row(
        children: [
          // Kolom nama santri (tetap)
          SizedBox(
            width: 110,
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
            Expanded(
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

    if (state.errorMessage != null &&
        state.errorMessage!.isNotEmpty &&
        state.tren == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ErrorBanner(
              title: 'Gagal Memuat Grafik',
              message: state.errorMessage!,
              onRetry: () => controller.loadTren(),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Coba Lagi',
              icon: Icons.refresh,
              onPressed: () => controller.loadTren(),
            ),
          ],
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
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              ..._pilihHari(context, state.tren?.hari ?? 7),
            ],
          ),
        ),
        const SizedBox(height: 12),

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

/// Grafik garis persen_hadir sederhana tanpa dependensi eksternal.
class TrenGrafik extends StatelessWidget {
  final List<TrenHarian> data;

  const TrenGrafik({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Persen Kehadiran per Hari',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Label sumbu Y
          Row(
            children: [
              const SizedBox(width: 44),
              Text('100', style: _labelStyle),
              const Spacer(),
              Text('50', style: _labelStyle),
              const Spacer(),
              Text('0', style: _labelStyle),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _GarisGrafik(data: data),
          ),
          const SizedBox(height: 12),
          // Label sumbu X (tanggal)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: data.length,
              itemBuilder: (context, index) {
                final d = data[index];
                final label = _singkatTanggal(d.tanggal);
                return Container(
                  width: 60,
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Ringkasan nilai terakhir
          if (data.isNotEmpty)
            InfoBanner(
              icon: Icons.info_outline,
              color: AppColors.accent,
              message:
                  'Nilai terakhir (${data.last.tanggal}): ${data.last.persenDisplay}% (${data.last.total} data)',
            ),
        ],
      ),
    );
  }

  static TextStyle get _labelStyle => const TextStyle(
        fontSize: 11,
        color: AppColors.textSecondary,
      );

  static String _singkatTanggal(String tanggal) {
    try {
      final parsed = DateTime.parse(tanggal);
      return DateFormat('dd/MM').format(parsed);
    } catch (_) {
      return tanggal;
    }
  }
}

/// Custom painter untuk garis grafik. Nilai null digambarkan terputus.
class _GarisGrafik extends StatefulWidget {
  final List<TrenHarian> data;

  const _GarisGrafik({required this.data});

  @override
  State<_GarisGrafik> createState() => _GarisGrafikState();
}

class _GarisGrafikState extends State<_GarisGrafik> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _LinePainter(data: widget.data),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<TrenHarian> data;

  _LinePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paintLine = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final paintDot = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    double maxX = (data.length - 1).toDouble();
    if (maxX == 0) maxX = 1;

    double? prevX;
    double? prevY;

    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      final x = (size.width / maxX) * i;
      double? y;
      if (d.persenHadir != null) {
        y = size.height * (1 - (d.persenHadir! / 100));
      }

      if (y != null && prevY != null && prevX != null) {
        canvas.drawLine(
          Offset(prevX, prevY),
          Offset(x, y),
          paintLine,
        );
      }
      if (y != null) {
        canvas.drawCircle(Offset(x, y), 3, paintDot);
      }
      prevX = x;
      prevY = y;
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    if (oldDelegate.data.length != data.length) return true;
    for (int i = 0; i < data.length; i++) {
      if (oldDelegate.data[i] != data[i]) return true;
    }
    return false;
  }
}
