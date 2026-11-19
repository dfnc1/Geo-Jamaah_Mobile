import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../musyrif/presentation/santri_tab_screen.dart';
import 'admin_dashboard_controller.dart';

/// Layar utama Admin dengan 3 tab navigasi:
/// 0 = Ringkasan & Tren Kehadiran Global
/// 1 = Log Aktivitas Audit (Activity Logs)
/// 2 = Kelola (Reset Device, Pemicu Job, dan Logout)
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  int _currentIndex = 0;
  final TextEditingController _nimController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(adminDashboardControllerProvider.notifier);
      controller.loadRekap();
      controller.loadTren(hari: 7);
      controller.loadLogs(refresh: true);
    });
  }

  @override
  void dispose() {
    _nimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDashboardControllerProvider);
    final controller = ref.read(adminDashboardControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan Data',
            onPressed: () {
              if (_currentIndex == 0) {
                controller.loadRekap();
                controller.loadTren();
              } else if (_currentIndex == 1) {
                controller.loadLogs(refresh: true);
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildRingkasanTab(state, controller),
          _buildActivityLogsTab(state, controller),
          _buildKelolaTab(state, controller),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 0 && state.rekap == null) {
            controller.loadRekap();
            controller.loadTren();
          } else if (index == 1 && state.logs.isEmpty) {
            controller.loadLogs(refresh: true);
          }
        },
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.accent),
            label: 'Ringkasan',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppColors.accent),
            label: 'Log Aktivitas',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: AppColors.accent),
            label: 'Kelola',
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 0: Ringkasan & Tren
  // =========================================================================

  Widget _buildRingkasanTab(
    AdminDashboardState state,
    AdminDashboardController controller,
  ) {
    if (state.isLoadingRekap && state.rekap == null) {
      return const LoadingView(message: 'Memuat rekap data admin...');
    }

    if (state.errorRekap != null && state.rekap == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ErrorBanner(
                title: 'Gagal Memuat Rekap',
                message: state.errorRekap!,
                onRetry: () {
                  controller.loadRekap();
                  controller.loadTren();
                },
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Coba Lagi',
                icon: Icons.refresh,
                onPressed: () {
                  controller.loadRekap();
                  controller.loadTren();
                },
              ),
            ],
          ),
        ),
      );
    }

    final rekap = state.rekap;

    return RefreshIndicator(
      onRefresh: () async {
        await controller.loadRekap();
        await controller.loadTren();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (rekap != null) ...[
            // Baris Santri Aktif & Santri Kritis
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Santri Aktif',
                    value: '${rekap.jumlahSantriAktif}',
                    icon: Icons.school,
                    color: AppColors.emerald,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Santri Kritis (DSS)',
                    value: '${rekap.jumlahSantriKritis}',
                    icon: Icons.warning_amber_rounded,
                    color: rekap.jumlahSantriKritis > 0
                        ? AppColors.error
                        : AppColors.slate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card Presensi 30 Hari
            Container(
              padding: const EdgeInsets.all(16),
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
                        'Rekap Presensi (30 Hari)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Total: ${rekap.presensi.total}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'Hadir',
                          value: '${rekap.presensi.hadir}',
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniStat(
                          label: 'Tidak Hadir',
                          value: '${rekap.presensi.tidakHadir}',
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniStat(
                          label: 'Izin',
                          value: '${rekap.presensi.izin}',
                          color: const Color(0xFFD39E00),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniStat(
                          label: 'Manual',
                          value: '${rekap.presensi.manual}',
                          color: AppColors.slate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card Pengajuan Izin
            Container(
              padding: const EdgeInsets.all(16),
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
                        'Pengajuan Izin',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Total: ${rekap.izin.total}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'Pending',
                          value: '${rekap.izin.pending}',
                          color: const Color(0xFFD39E00),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniStat(
                          label: 'Disetujui',
                          value: '${rekap.izin.disetujui}',
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniStat(
                          label: 'Ditolak',
                          value: '${rekap.izin.ditolak}',
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Grafik Tren Kehadiran Global
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tren Kehadiran Global',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [7, 14, 30].map((h) {
                  final isSelected = state.trenHari == h;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: ChoiceChip(
                      label: Text('$h h'),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) controller.loadTren(hari: h);
                      },
                      visualDensity: VisualDensity.compact,
                      selectedColor: AppColors.accent.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (state.isLoadingTren && state.tren == null)
            const SizedBox(
              height: 200,
              child: LoadingView(message: 'Memuat grafik tren...'),
            )
          else if (state.errorTren != null && state.tren == null)
            ErrorBanner(
              title: 'Gagal Memuat Grafik',
              message: state.errorTren!,
              onRetry: () => controller.loadTren(),
            )
          else if (state.tren != null)
            Container(
              height: 320,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: TrenGrafik(data: state.tren!.data),
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: Log Aktivitas (Activity Logs)
  // =========================================================================

  Widget _buildActivityLogsTab(
    AdminDashboardState state,
    AdminDashboardController controller,
  ) {
    const modulList = [
      'Semua',
      'Auth',
      'Presensi',
      'Izin',
      'Masjid',
      'Jadwal',
      'Mahasantri',
      'Jobs'
    ];

    return Column(
      children: [
        // Filter horizontal
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: modulList.length,
            itemBuilder: (context, index) {
              final m = modulList[index];
              final isSelected = state.selectedModul == m;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(m),
                  selected: isSelected,
                  onSelected: (_) => controller.setFilterModul(m),
                  visualDensity: VisualDensity.compact,
                  selectedColor: AppColors.accent.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? AppColors.accent : AppColors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),

        // List Log
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => controller.loadLogs(refresh: true),
            child: state.isLoadingLogs && state.logs.isEmpty
                ? const LoadingView(message: 'Memuat log aktivitas...')
                : state.errorLogs != null && state.logs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ErrorBanner(
                                title: 'Gagal Memuat Log',
                                message: state.errorLogs!,
                                onRetry: () =>
                                    controller.loadLogs(refresh: true),
                              ),
                              const SizedBox(height: 16),
                              PrimaryButton(
                                label: 'Coba Lagi',
                                icon: Icons.refresh,
                                onPressed: () =>
                                    controller.loadLogs(refresh: true),
                              ),
                            ],
                          ),
                        ),
                      )
                    : state.logs.isEmpty
                        ? const EmptyState(
                            icon: Icons.history_toggle_off,
                            title: 'Belum Ada Log Aktivitas',
                            message:
                                'Tidak ada log aktivitas untuk filter modul yang dipilih.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.logs.length +
                                (state.logPage < state.logTotalPages ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              if (index == state.logs.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          controller.muatLebihBanyakLogs(),
                                      icon: const Icon(Icons.arrow_downward,
                                          size: 16),
                                      label: const Text('Muat Lebih Banyak'),
                                    ),
                                  ),
                                );
                              }
                              final log = state.logs[index];
                              return _LogCard(log: log);
                            },
                          ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 2: Kelola (Reset Device, Pemicu Job, Logout)
  // =========================================================================

  Widget _buildKelolaTab(
    AdminDashboardState state,
    AdminDashboardController controller,
  ) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Feedback notifikasi
        if (state.actionMessage != null) ...[
          InfoBanner(
            icon: Icons.check_circle_outline,
            color: AppColors.success,
            message: state.actionMessage!,
          ),
          const SizedBox(height: 16),
        ],
        if (state.actionError != null) ...[
          ErrorBanner(
            title: 'Aksi Gagal',
            message: state.actionError!,
            onRetry: () => controller.clearActionFeedback(),
          ),
          const SizedBox(height: 16),
        ],

        // Card 1: Reset Device ID Mahasantri
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.phone_android,
                        size: 20, color: AppColors.accent),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Reset Device ID Mahasantri',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Gunakan fitur ini jika mahasantri berganti HP atau mengalami error "Perangkat tidak sesuai". Akun akan dilepas dari HP lama.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'NIM Mahasantri',
                hint: 'Masukkan NIM (contoh: 24050505050)',
                controller: _nimController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Reset Ikatan Device',
                icon: Icons.lock_reset,
                isLoading: state.isActionLoading,
                onPressed: () async {
                  final nim = _nimController.text.trim();
                  if (nim.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('NIM wajib diisi.')),
                    );
                    return;
                  }
                  final yakin = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Konfirmasi Reset Device'),
                      content: Text(
                        'Anda yakin ingin mereset ikatan device untuk NIM $nim?\n\nMahasantri dapat login dari perangkat baru setelah ini.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text(
                            'Ya, Reset',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (yakin == true && context.mounted) {
                    final sukses = await controller.resetDevice(nim);
                    if (sukses && context.mounted) {
                      _nimController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            state.actionMessage ??
                                'Device ID berhasil direset.',
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Card 2: Pemicu Job Kehadiran Manual
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.alarm_on,
                        size: 20, color: AppColors.emerald),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pemicu Job Presensi Otomatis',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Tandai Mahasantri yang belum presensi setelah jendela waktu usai. Santri berizin disetujui akan ditandai "Izin", sisanya "Tidak Hadir".',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Jalankan Hari Ini',
                      icon: Icons.play_arrow,
                      isLoading: state.isActionLoading,
                      onPressed: () async {
                        final yakin = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Jalankan Job Presensi'),
                            content: const Text(
                              'Jalankan penandaan otomatis untuk seluruh jadwal sholat hari ini yang sudah melewati batas waktu presensi?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Jalankan'),
                              ),
                            ],
                          ),
                        );
                        if (yakin == true && context.mounted) {
                          await controller.triggerJob();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Backfill Tanggal',
                      icon: Icons.calendar_month,
                      isOutlined: true,
                      isLoading: state.isActionLoading,
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: now.subtract(const Duration(days: 1)),
                          firstDate: now.subtract(const Duration(days: 60)),
                          lastDate: now,
                        );
                        if (picked != null && context.mounted) {
                          final formatted =
                              DateFormat('yyyy-MM-dd').format(picked);
                          final yakin = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Konfirmasi Backfill'),
                              content: Text(
                                'Jalankan penandaan otomatis (backfill) untuk tanggal $formatted?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Jalankan Backfill'),
                                ),
                              ],
                            ),
                          );
                          if (yakin == true && context.mounted) {
                            await controller.triggerJob(tanggal: formatted);
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Card 3: Profil & Keluar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.emerald.withValues(alpha: 0.1),
                  child: const Icon(Icons.admin_panel_settings,
                      color: AppColors.emerald),
                ),
                title: Text(
                  user?.displayName ?? 'Administrator',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('Role: ${user?.role.name ?? 'Admin'}'),
              ),
              const Divider(height: 24),
              PrimaryButton(
                label: 'Keluar dari Aplikasi',
                icon: Icons.logout,
                isOutlined: true,
                onPressed: () async {
                  final yakin = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Keluar'),
                      content:
                          const Text('Anda yakin ingin keluar dari akun Admin?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Keluar',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  if (yakin == true && context.mounted) {
                    await ref.read(authControllerProvider.notifier).logout();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Widget Helper ────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
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

class _LogCard extends StatelessWidget {
  final ActivityLogItem log;

  const _LogCard({required this.log});

  Color _getModulColor(String modul) {
    switch (modul) {
      case 'Auth':
        return AppColors.accent;
      case 'Presensi':
        return AppColors.success;
      case 'Izin':
        return const Color(0xFFD39E00);
      case 'Jobs':
        return Colors.purple;
      case 'Masjid':
      case 'Jadwal':
        return AppColors.emerald;
      default:
        return AppColors.slate;
    }
  }

  String _formatTimestamp(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final modulColor = _getModulColor(log.modul);

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: modulColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: modulColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  log.modul,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: modulColor,
                  ),
                ),
              ),
              Text(
                _formatTimestamp(log.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            log.aktivitas,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Oleh: ${log.username} (${log.role})',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
