import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/widgets.dart';

/// Root widget aplikasi Geo-Jamaah.
class GeoJamaahApp extends ConsumerWidget {
  const GeoJamaahApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Geo-Jamaah',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _PlaceholderScreen(),
    );
  }
}

/// Layar sementara pada tahap inisialisasi M1.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geo-Jamaah'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mosque,
                    size: 44,
                    color: AppColors.emerald,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Geo-Jamaah',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emerald,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Presensi Shalat Berjamaah Berbasis Geofencing',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              const InfoBanner(
                title: 'Inisialisasi Milestone 1 Selesai',
                message:
                    'Arsitektur terpusat siap: Theme, ApiClient, TokenStore, dan Komponen Desain terkonfigurasi.',
              ),
              const SizedBox(height: 20),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  StatusBadge(status: 'Hadir'),
                  StatusBadge(status: 'Tidak_Hadir'),
                  StatusBadge(status: 'Izin'),
                  StatusBadge(status: 'Manual'),
                  StatusBadge(status: 'Belum'),
                  StatusBadge(status: 'Pending'),
                  StatusBadge(status: 'Disetujui'),
                  StatusBadge(status: 'Ditolak'),
                ],
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Aplikasi Siap Digunakan',
                onPressed: () {},
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
