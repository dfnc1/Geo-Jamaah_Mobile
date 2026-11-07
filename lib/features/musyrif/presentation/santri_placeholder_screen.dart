import 'package:flutter/material.dart';
import '../../../core/widgets/empty_state.dart';

/// Placeholder tab Santri Musyrif (akan diimplementasikan penuh pada M7).
class SantriPlaceholderScreen extends StatelessWidget {
  const SantriPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Santri Binaan'),
        automaticallyImplyLeading: false,
      ),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: EmptyState(
              icon: Icons.people_outline,
              title: 'Daftar Santri Binaan',
              message:
                  'Fitur daftar dan detail santri binaan akan tersedia pada tahap berikutnya (M7).',
            ),
          ),
        ),
      ),
    );
  }
}
