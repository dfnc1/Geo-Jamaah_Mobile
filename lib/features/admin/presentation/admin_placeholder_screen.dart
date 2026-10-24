import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/auth_controller.dart';

/// Halaman placeholder untuk peran Admin.
class AdminPlaceholderScreen extends ConsumerWidget {
  const AdminPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EmptyState(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Peran Admin belum tersedia di aplikasi mobile',
                message:
                    'Pengelolaan data master (Masjid, Jadwal, Santri, dan Musyrif) dapat diakses melalui Web Dashboard Admin.',
              ),
              const SizedBox(height: 32),
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
