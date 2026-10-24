import 'package:flutter/material.dart';
import '../../../core/widgets/empty_state.dart';

/// Placeholder tab Izin Mahasantri (akan diimplementasikan penuh pada M5).
class MahasantriIzinPlaceholder extends StatelessWidget {
  const MahasantriIzinPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Izin'),
        automaticallyImplyLeading: false,
      ),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: EmptyState(
              icon: Icons.event_note_outlined,
              title: 'Pengajuan Izin',
              message:
                  'Fitur pengajuan dan riwayat izin mahasantri akan tersedia pada tahap berikutnya (M5).',
            ),
          ),
        ),
      ),
    );
  }
}
