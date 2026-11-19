import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/auth_controller.dart';

/// Layar Profil Mahasantri.
/// Menampilkan data profil santri langsung dari state autentikasi tanpa request tambahan.
class MahasantriProfilScreen extends ConsumerWidget {
  const MahasantriProfilScreen({super.key});

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text(
            'Konfirmasi Keluar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                ref.read(authControllerProvider.notifier).logout();
              },
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    final nim = user?.nim ?? '-';
    final nama = user?.namaLengkap ?? '-';
    final kamar = user?.kamar ?? '-';
    final namaMusyrif = user?.namaMusyrif ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Mahasantri'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar & Header Profil
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.emerald.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: AppColors.emerald,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      nama,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NIM: $nim',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.slate,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Kartu Detail Informasi
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      _ProfileRow(
                        icon: Icons.badge_outlined,
                        label: 'NIM',
                        value: nim,
                      ),
                      const Divider(height: 1, color: AppColors.lightGrey),
                      _ProfileRow(
                        icon: Icons.person_outline,
                        label: 'Nama Lengkap',
                        value: nama,
                      ),
                      const Divider(height: 1, color: AppColors.lightGrey),
                      _ProfileRow(
                        icon: Icons.meeting_room_outlined,
                        label: 'Kamar / Asrama',
                        value: kamar,
                      ),
                      const Divider(height: 1, color: AppColors.lightGrey),
                      _ProfileRow(
                        icon: Icons.supervisor_account_outlined,
                        label: 'Musyrif Pembina',
                        value: namaMusyrif,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Tombol Keluar
              PrimaryButton(
                label: 'Keluar',
                isOutlined: true,
                icon: Icons.logout,
                onPressed: () => _confirmLogout(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.slate),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
