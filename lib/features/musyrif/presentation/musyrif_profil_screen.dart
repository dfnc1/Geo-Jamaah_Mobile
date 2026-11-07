import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/auth_controller.dart';

/// Halaman Profil Musyrif.
/// Menampilkan nama dan nomor telepon dari data user tersimpan,
/// serta tombol Keluar dengan konfirmasi.
class MusyrifProfilScreen extends ConsumerWidget {
  const MusyrifProfilScreen({super.key});

  Future<void> _konfirmasiKeluar(BuildContext context, WidgetRef ref) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          PrimaryButton(
            label: 'Keluar',
            isOutlined: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (yakin == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final profil = user?.profil;

    final nama = profil?['nama']?.toString() ??
        user?.displayName ??
        'Musyrif';
    final noTelp = profil?['no_telepon']?.toString() ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Musyrif'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.supervisor_account,
                          size: 40,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        nama,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kontak: $noTelp',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Keluar',
                icon: Icons.logout,
                isOutlined: true,
                onPressed: () => _konfirmasiKeluar(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
