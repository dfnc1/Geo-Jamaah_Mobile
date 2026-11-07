import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/admin_placeholder_screen.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/mahasantri/presentation/mahasantri_beranda_screen.dart';
import '../../features/mahasantri/presentation/izin_screen.dart';
import '../../features/mahasantri/presentation/mahasantri_profil_screen.dart';
import '../../features/mahasantri/presentation/mahasantri_shell.dart';
import '../../features/musyrif/presentation/izin_musyrif_screen.dart';
import '../../features/musyrif/presentation/musyrif_profil_screen.dart';
import '../../features/musyrif/presentation/musyrif_shell.dart';
import '../../features/musyrif/presentation/santri_tab_screen.dart';
import '../../features/presensi/presentation/presensi_controller.dart';
import '../../features/presensi/presentation/presensi_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

/// Provider GoRouter terintegrasi dengan status autentikasi Riverpod.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthStateListenable(ref),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MahasantriShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mahasantri',
                builder: (context, state) => const MahasantriBerandaScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mahasantri/izin',
                builder: (context, state) => const IzinScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mahasantri/profil',
                builder: (context, state) => const MahasantriProfilScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MusyrifShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/musyrif',
                builder: (context, state) => const IzinMusyrifScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/musyrif/santri',
                builder: (context, state) => const SantriTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/musyrif/profil',
                builder: (context, state) => const MusyrifProfilScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminPlaceholderScreen(),
      ),
      // Rute presensi — di luar shell tab agar navigasi bawah tersembunyi
      GoRoute(
        path: '/mahasantri/presensi',
        builder: (context, state) {
          // Args diteruskan lewat extra (objek PresensiArgs)
          final args = state.extra as PresensiArgs?;
          if (args == null) {
            // Fallback: tidak seharusnya terjadi, kembali ke beranda
            return const MahasantriBerandaScreen();
          }
          return PresensiScreen(args: args);
        },
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      // 1. Masih dalam proses inisialisasi / restore session
      if (authState.status == AuthStatus.initial) {
        return location == '/splash' ? null : '/splash';
      }

      // 2. Belum terautentikasi (selalu diarahkan ke /login)
      if (authState.status == AuthStatus.unauthenticated) {
        return location == '/login' ? null : '/login';
      }

      // 3. Sudah terautentikasi (tidak boleh membuka /login atau /splash)
      if (authState.status == AuthStatus.authenticated) {
        final role = authState.user?.role.toLowerCase();

        if (location == '/login' || location == '/splash') {
          return _targetRouteForRole(role);
        }

        // Mencegah akses lintas peran
        if (role == 'mahasantri' && !location.startsWith('/mahasantri')) {
          return '/mahasantri';
        }
        if (role == 'musyrif' && !location.startsWith('/musyrif')) {
          return '/musyrif';
        }
        if (role == 'admin' && !location.startsWith('/admin')) {
          return '/admin';
        }
      }

      return null;
    },
  );
});

String _targetRouteForRole(String? role) {
  switch (role) {
    case 'mahasantri':
      return '/mahasantri';
    case 'musyrif':
      return '/musyrif';
    case 'admin':
      return '/admin';
    default:
      return '/login';
  }
}

/// Helper Listenable yang memberitahu GoRouter saat AuthState berubah
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (_, __) {
      notifyListeners();
    });
  }
}
