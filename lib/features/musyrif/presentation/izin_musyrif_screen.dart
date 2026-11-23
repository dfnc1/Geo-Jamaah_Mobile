import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../mahasantri/domain/izin_model.dart';
import '../domain/izin_musyrif_model.dart';
import 'izin_musyrif_controller.dart';

/// Layar Daftar Izin Santri Binaan Musyrif.
///
/// Menampilkan daftar izin dengan filter chip (Pending default),
/// StatusBadge per item, dan bottom sheet detail + verifikasi saat diketuk.
class IzinMusyrifScreen extends ConsumerStatefulWidget {
  const IzinMusyrifScreen({super.key});

  @override
  ConsumerState<IzinMusyrifScreen> createState() => _IzinMusyrifScreenState();
}

class _IzinMusyrifScreenState extends ConsumerState<IzinMusyrifScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(izinMusyrifControllerProvider.notifier).loadIzinBinaan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(izinMusyrifControllerProvider);
    final controller = ref.read(izinMusyrifControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Izin Santri Binaan'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // ── Filter chips ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IzinFilterMusyrif.values.map((filter) {
                final selected = state.filter == filter;
                return FilterChip(
                  label: Text(
                    filter.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  selected: selected,
                  onSelected: (_) => controller.gantiFilter(filter),
                  backgroundColor: AppColors.lightGrey,
                  selectedColor: AppColors.accent,
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // ── Daftar izin ──
          Expanded(
            child: _buildBody(context, state, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    IzinMusyrifState state,
    IzinMusyrifController controller,
  ) {
    if (state.isLoading && state.daftarIzin.isEmpty) {
      return const LoadingView(message: 'Memuat daftar izin...');
    }

    if (state.errorMessage != null &&
        state.errorMessage!.isNotEmpty &&
        state.daftarIzin.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ErrorBanner(
              title: 'Gagal Memuat Daftar Izin',
              message: state.errorMessage!,
              onRetry: () => controller.loadIzinBinaan(),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Coba Lagi',
              icon: Icons.refresh,
              onPressed: () => controller.loadIzinBinaan(),
            ),
          ],
        ),
      );
    }

    if (state.daftarIzin.isEmpty) {
      return EmptyState(
        icon: Icons.event_note_outlined,
        title: 'Tidak Ada Izin ${state.filter.label}',
        message:
            'Belum ada pengajuan izin santri binaan dengan status ${state.filter.label}.',
      );
    }

    final hasError = state.errorMessage != null && state.errorMessage!.isNotEmpty;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => controller.loadIzinBinaan(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: state.daftarIzin.length + (hasError ? 1 : 0),
        itemBuilder: (context, index) {
          if (hasError && index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: ErrorBanner(
                title: 'Pemberitahuan',
                message: state.errorMessage!,
                onDismiss: () => controller.clearError(),
              ),
            );
          }
          final itemIndex = hasError ? index - 1 : index;
          final izin = state.daftarIzin[itemIndex];
          return _IzinMusyrifCard(
            izin: izin,
            onTap: () => _bukaDetail(context, izin),
          );
        },
      ),
    );
  }

  /// Membuka bottom sheet detail izin + tombol verifikasi (jika Pending).
  Future<void> _bukaDetail(
    BuildContext context,
    IzinMusyrifItem izin,
  ) async {
    final isPending = izin.statusParsed == StatusPersetujuanIzin.pending;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer(
          builder: (sheetContext, sheetRef, _) {
            final ctrlState = sheetRef.watch(izinMusyrifControllerProvider);
            final controller =
                sheetRef.read(izinMusyrifControllerProvider.notifier);
            final verifying = ctrlState.isVerifying;

            Future<void> handleVerify(String statusBaru, String successText, Color successColor) async {
              final berhasil = await controller.verifikasiIzin(
                idIzin: izin.idIzin,
                statusBaru: statusBaru,
              );
              if (berhasil && sheetContext.mounted) {
                Navigator.of(sheetContext).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(successText),
                      backgroundColor: successColor,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } else if (!berhasil && context.mounted) {
                final latestError =
                    sheetRef.read(izinMusyrifControllerProvider).errorMessage;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      (latestError != null && latestError.isNotEmpty)
                          ? latestError
                          : 'Verifikasi gagal.',
                    ),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            }

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.borderRadius),
                  topRight: Radius.circular(AppTheme.borderRadius),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                24 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.event_note_outlined,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detail Izin',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${izin.namaMahasantri} (${izin.nim})',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'Jenis Izin',
                    value: izin.jenisIzin.replaceAll('_', ' '),
                  ),
                  _DetailRow(
                    label: 'Tanggal',
                    value: izin.tanggalDisplay,
                  ),
                  _DetailRow(
                    label: 'Status',
                    value: izin.statusParsed.labelIndonesia,
                    badge: true,
                    status: izin.statusPersetujuan,
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Alasan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    izin.alasan,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol verifikasi hanya untuk Pending
                  if (isPending) ...[
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: 'Setujui',
                            icon: Icons.check_circle_outline,
                            isLoading: verifying,
                            onPressed: verifying
                                ? null
                                : () => handleVerify(
                                      'Disetujui',
                                      'Izin disetujui. Daftar diperbarui.',
                                      AppColors.success,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PrimaryButton(
                            label: 'Tolak',
                            icon: Icons.block_outlined,
                            isLoading: verifying,
                            backgroundColor: AppColors.error,
                            textColor: Colors.white,
                            onPressed: verifying
                                ? null
                                : () => handleVerify(
                                      'Ditolak',
                                      'Izin ditolak. Daftar diperbarui.',
                                      AppColors.error,
                                    ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  PrimaryButton(
                    label: 'Tutup',
                    icon: Icons.close,
                    onPressed: verifying
                        ? null
                        : () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Baris detail (label + nilai) dengan opsi StatusBadge.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool badge;
  final String? status;

  const _DetailRow({
    required this.label,
    required this.value,
    this.badge = false,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.slate,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge && status != null) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: status!),
                    ],
                  ),
                ] else ...[
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu satu item izin Musyrif.
class _IzinMusyrifCard extends StatelessWidget {
  final IzinMusyrifItem izin;
  final VoidCallback onTap;

  const _IzinMusyrifCard({required this.izin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          izin.namaMahasantri,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.numbers_outlined,
                  size: 14,
                  color: AppColors.slate,
                ),
                const SizedBox(width: 6),
                Text(
                  'NIM: ${izin.nim}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.slate,
                ),
                const SizedBox(width: 6),
                Text(
                  izin.tanggalDisplay,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.event_note_outlined,
                  size: 14,
                  color: AppColors.slate,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    izin.jenisIzin.replaceAll('_', ' '),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: StatusBadge(status: izin.statusPersetujuan),
        onTap: onTap,
      ),
      ),
    );
  }
}