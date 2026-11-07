import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_badge.dart';
import 'izin_controller.dart';
import '../domain/izin_model.dart';

/// Layar Pengajuan & Daftar Izin Mahasantri.
///
/// Dua bagian utama:
/// 1. Form pengajuan izin baru (POST /v1/izin): jenis_izin, tanggal_izin, alasan.
/// 2. Daftar izin milik sendiri (GET /v1/izin/saya), urut terbaru dulu.
///
/// Semua pengecekan bisnis dilakukan server. Aplikasi hanya mengirim dan menampilkan.
class IzinScreen extends ConsumerStatefulWidget {
  const IzinScreen({super.key});

  @override
  ConsumerState<IzinScreen> createState() => _IzinScreenState();
}

class _IzinScreenState extends ConsumerState<IzinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _alasanController = TextEditingController();

  JenisIzin? _jenisIzinDipilih;
  DateTime? _tanggalIzin;

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final izinState = ref.watch(izinControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Izin'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang daftar',
            onPressed: izinState.isLoading
                ? null
                : () => ref
                    .read(izinControllerProvider.notifier)
                    .loadIzinSaya(),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ── Bagian 1: Form Pengajuan Izin Baru ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Ajukan Izin Baru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      InfoBanner(
                        icon: Icons.info_outline,
                        color: AppColors.accent,
                        message:
                            'Id_musyrif (pembina) dan status awal (Pending) diisi secara otomatis oleh server.',
                      ),
                      const SizedBox(height: 20),

                      // Jenis Izin
                      const Text(
                        'Jenis Izin *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<JenisIzin>(
                        key: ValueKey(_jenisIzinDipilih),
                        initialValue: _jenisIzinDipilih,
                        decoration: const InputDecoration(
                          hintText: 'Pilih jenis izin',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        items: JenisIzin.values.map((jenis) {
                          return DropdownMenuItem(
                            value: jenis,
                            child: Text(jenis.labelIndonesia),
                          );
                        }).toList(),
                        onChanged: izinState.isSubmitting
                            ? null
                            : (value) =>
                                setState(() => _jenisIzinDipilih = value),
                        validator: (value) =>
                            value == null ? 'Jenis izin wajib dipilih' : null,
                      ),
                      const SizedBox(height: 16),

                      // Tanggal Izin
                      const Text(
                        'Tanggal Izin *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        label: 'Tanggal (YYYY-MM-DD)',
                        readOnly: true,
                        onTap: izinState.isSubmitting
                            ? null
                            : () => _pilihTanggal(context),
                        prefixIcon: Icons.calendar_today_outlined,
                        controller: TextEditingController(
                          text: _tanggalIzin != null
                              ? DateFormat('yyyy-MM-dd').format(_tanggalIzin!)
                              : '',
                        ),
                        validator: (_) =>
                            _tanggalIzin == null ? 'Tanggal izin wajib diisi' : null,
                        enabled: !izinState.isSubmitting,
                      ),
                      const SizedBox(height: 16),

                      // Alasan
                      const Text(
                        'Alasan *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _alasanController,
                        label: 'Alasan izin',
                        hint: 'Contoh: Sakit demam, sudah ke puskesmas',
                        maxLines: 3,
                        prefixIcon: Icons.message_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Alasan wajib diisi';
                          }
                          if (value.trim().length > 500) {
                            return 'Alasan maksimal 500 karakter';
                          }
                          return null;
                        },
                        enabled: !izinState.isSubmitting,
                      ),
                      const SizedBox(height: 20),

                      PrimaryButton(
                        label: 'Ajukan Izin',
                        icon: Icons.event_note_outlined,
                        isLoading: izinState.isSubmitting,
                        onPressed: izinState.isSubmitting
                            ? null
                            : () => _ajukanIzin(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Bagian 2: Daftar Izin Saya ──
              const Text(
                'Daftar Izin Saya',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              if (izinState.isLoading && izinState.daftarIzin.isEmpty)
                const LoadingView(message: 'Memuat daftar izin...')
              else if (izinState.errorMessage != null &&
                  izinState.errorMessage!.isNotEmpty &&
                  izinState.daftarIzin.isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ErrorBanner(
                        title: 'Gagal Memuat Daftar Izin',
                        message: izinState.errorMessage!,
                        onRetry: () => ref
                            .read(izinControllerProvider.notifier)
                            .loadIzinSaya(),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: 'Coba Lagi',
                        icon: Icons.refresh,
                        onPressed: () => ref
                            .read(izinControllerProvider.notifier)
                            .loadIzinSaya(),
                      ),
                    ],
                  ),
                )
              else if (izinState.daftarIzin.isEmpty)
                const EmptyState(
                  icon: Icons.event_note_outlined,
                  title: 'Belum Ada Izin',
                  message:
                      'Anda belum memiliki pengajuan izin. Ajukan izin baru melalui formulir di atas.',
                )
              else
                ...izinState.daftarIzin.map((izin) => _IzinCard(izin: izin)),

              // Konfirmasi hasil pengajuan (jika ada)
              if (izinState.hasilAjukan != null) ...[
                const SizedBox(height: 24),
                Card(
                  color: AppColors.success.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pengajuan izin berhasil dicatat',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _InfoRowIzin(
                          label: 'Jenis',
                          value: izinState.hasilAjukan!.jenisIzin,
                        ),
                        _InfoRowIzin(
                          label: 'Tanggal',
                          value: izinState.hasilAjukan!.tanggalDisplay,
                        ),
                        _InfoRowIzin(
                          label: 'Status',
                          value: StatusPersetujuanIzin.fromString(
                                  izinState.hasilAjukan!.statusPersetujuan)
                              .labelIndonesia,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Membuka date picker untuk memilih tanggal izin.
  /// Rentang: 30 hari ke belakang hingga 90 hari ke depan dari hari ini.
  Future<void> _pilihTanggal(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalIzin ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _tanggalIzin = picked;
      });
    }
  }

  /// Mengajukan izin ke server.
  Future<void> _ajukanIzin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_jenisIzinDipilih == null || _tanggalIzin == null) return;

    final request = IzinRequest(
      jenisIzin: _jenisIzinDipilih!.rawValue,
      tanggalIzin: DateFormat('yyyy-MM-dd').format(_tanggalIzin!),
      alasan: _alasanController.text.trim(),
      buktiLampiran: null, // upload lampiran masih rencana (MinIO)
    );

    final berhasil = await ref
        .read(izinControllerProvider.notifier)
        .ajukanIzin(request);

    if (!mounted) return;

    if (berhasil) {
      _alasanController.clear();
      setState(() {
        _jenisIzinDipilih = null;
        _tanggalIzin = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan izin berhasil dikirim.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      // Error sudah ditampilkan oleh controller melalui state.errorMessage
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(izinStateError(ref) ?? 'Pengajuan izin gagal.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}

/// Kartu satu item izin dalam daftar.
class _IzinCard extends StatelessWidget {
  final IzinItem izin;

  const _IzinCard({required this.izin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        izin.jenisIzin.replaceAll('_', ' '),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tanggal: ${izin.tanggalDisplay}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: izin.statusPersetujuan),
              ],
            ),
            const SizedBox(height: 12),
            if (izin.alasan.isNotEmpty) ...[
              const Text(
                'Alasan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                izin.alasan,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                const Icon(
                  Icons.numbers_outlined,
                  size: 16,
                  color: AppColors.slate,
                ),
                const SizedBox(width: 6),
                Text(
                  'ID: ${izin.idIzin}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate,
                  ),
                ),
                const Spacer(),
                if (izin.buktiLampiran != null &&
                    izin.buktiLampiran!.isNotEmpty) ...[
                  const Icon(
                    Icons.attach_file_outlined,
                    size: 16,
                    color: AppColors.slate,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Lampiran tersedia',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris info kecil (label + nilai) di kartu konfirmasi hasil.
class _InfoRowIzin extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRowIzin({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ambil pesan error aktif dari state izin (untuk SnackBar gagal).
String? izinStateError(WidgetRef ref) {
  final state = ref.read(izinControllerProvider);
  return state.errorMessage;
}
