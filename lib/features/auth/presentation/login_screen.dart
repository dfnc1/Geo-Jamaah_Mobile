import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/auth_state.dart';
import 'auth_controller.dart';

/// Layar Login Geo-Jamaah sesuai spesifikasi desain Portal Mahasantri.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    // Sembunyikan keyboard
    FocusScope.of(context).unfocus();

    ref.read(authControllerProvider.notifier).login(
          username: _usernameController.text,
          password: _passwordController.text,
        );
  }

  void _showDeviceMismatchDialog(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Perangkat tidak sesuai',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(110, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authControllerProvider.notifier).clearError();
            },
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Dengarkan perubahan state untuk menampilkan dialog modal bila terjadi device mismatch
    ref.listen<AuthState>(authControllerProvider, (previous, current) {
      final err = current.error;
      if (err != null && err.isDeviceMismatch) {
        _showDeviceMismatchDialog(err.message);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo & Identitas Header ───────────────────────────────
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.emerald,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mosque,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      'Geo-Jamaah',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.emerald,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'PORTAL MAHASANTRI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.emerald,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Sistem Presensi Jamaah Real-Time',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Masuk untuk mengakses presensi jamaah dengan akun Ma'had Anda.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Form Input ──────────────────────────────────────────
                  AppTextField(
                    controller: _usernameController,
                    label: 'Username/NIM',
                    hint: 'Masukkan username / NIM',
                    prefixIcon: Icons.person_outline,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Masukkan password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 24),

                  // ── Tombol Masuk Akun ───────────────────────────────────
                  PrimaryButton(
                    label: 'Masuk Akun',
                    icon: Icons.arrow_forward,
                    isLoading: authState.isLoading,
                    onPressed: authState.isLoading ? null : _submit,
                  ),

                  // ── Error Banner (Di bawah tombol) ──────────────────────
                  if (authState.error != null &&
                      !authState.error!.isDeviceMismatch) ...[
                    const SizedBox(height: 16),
                    ErrorBanner(
                      title: authState.error!.title,
                      message: authState.error!.message,
                      onDismiss: () {
                        ref.read(authControllerProvider.notifier).clearError();
                      },
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Info Banner Perangkat ───────────────────────────────
                  const InfoBanner(
                    message:
                        'Perangkat Anda akan diikat secara otomatis via Device ID saat login pertama.',
                  ),
                  const SizedBox(height: 32),

                  // ── Teks Bawah ──────────────────────────────────────────
                  const Center(
                    child: Text(
                      "Akses khusus Mahasantri Ma'had",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.slate,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
