import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Badge status presensi dan perizinan.
/// Mendukung 8 status: Hadir, Tidak_Hadir, Izin, Manual, Belum, Pending, Disetujui, Ditolak.
class StatusBadge extends StatelessWidget {
  final String status;
  final bool small;

  const StatusBadge({
    super.key,
    required this.status,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: config.color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: small ? 12 : 14,
            color: config.color,
          ),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: config.color,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getConfig(String status) {
    final normalized = status.trim().toLowerCase().replaceAll(' ', '_');

    switch (normalized) {
      case 'hadir':
        return const _BadgeConfig(
          label: 'Hadir',
          color: AppColors.success,
          icon: Icons.check_circle_outline,
        );
      case 'tidak_hadir':
      case 'tidakhadir':
        return const _BadgeConfig(
          label: 'Tidak Hadir',
          color: AppColors.error,
          icon: Icons.cancel_outlined,
        );
      case 'izin':
        return const _BadgeConfig(
          label: 'Izin',
          color: Color(0xFFD39E00), // Peringatan kontras gelap
          icon: Icons.event_note_outlined,
        );
      case 'manual':
        return const _BadgeConfig(
          label: 'Manual',
          color: AppColors.accent,
          icon: Icons.edit_note_outlined,
        );
      case 'belum':
        return const _BadgeConfig(
          label: 'Belum',
          color: AppColors.slate,
          icon: Icons.schedule_outlined,
        );
      case 'pending':
        return const _BadgeConfig(
          label: 'Pending',
          color: Color(0xFFE65100),
          icon: Icons.hourglass_empty_outlined,
        );
      case 'disetujui':
        return const _BadgeConfig(
          label: 'Disetujui',
          color: AppColors.success,
          icon: Icons.verified_outlined,
        );
      case 'ditolak':
        return const _BadgeConfig(
          label: 'Ditolak',
          color: AppColors.error,
          icon: Icons.block_outlined,
        );
      default:
        return _BadgeConfig(
          label: status,
          color: AppColors.slate,
          icon: Icons.info_outline,
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color color;
  final IconData icon;

  const _BadgeConfig({
    required this.label,
    required this.color,
    required this.icon,
  });
}
