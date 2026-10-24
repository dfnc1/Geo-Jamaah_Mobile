import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/auth_controller.dart';

/// Halaman placeholder beranda Mahasantri (menampilkan identitas dan tombol keluar).
class MahasantriHomePlaceholder extends ConsumerWidget {
  const MahasantriHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final profil = user?.profil;
    final nama = user?.displayName ?? 'Mahasantri';
    final nim = profil?['nim']?.toString() ?? '-';
    final kamar = profil?['kamar']?.toString() ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda Mahasantri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
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
                        backgroundColor: AppColors.emerald.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.emerald,
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
                        'NIM: $nim · Kamar: $kamar',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const StatusBadge(status: 'Hadir', small: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const InfoBanner(
                title: 'Portal Mahasantri Aktif',
                message:
                    'Fitur presensi geofencing dan riwayat shalat berjamaah akan diaktifkan pada milestone berikutnya.',
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Keluar Akun',
                icon: Icons.logout,
                isOutlined: true,
                onPressed: () {
                  ref.read(authControllerProvider.notifier).logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
