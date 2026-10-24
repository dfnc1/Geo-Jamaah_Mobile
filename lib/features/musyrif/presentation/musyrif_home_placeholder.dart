import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/auth_controller.dart';

/// Halaman placeholder Musyrif yang menampilkan nama pembina dan tombol Keluar.
class MusyrifHomePlaceholder extends ConsumerWidget {
  const MusyrifHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final nama = user?.displayName ?? 'Ustadz / Musyrif';
    final noTelp = user?.profil?['no_telepon']?.toString() ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal Musyrif'),
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
                      const SizedBox(height: 12),
                      const StatusBadge(status: 'Disetujui', small: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const InfoBanner(
                title: 'Portal Pembina Musyrif',
                message:
                    'Fitur monitoring presensi santri binaan, verifikasi izin, dan Early Warning System (EWS) akan hadir.',
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Keluar',
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
