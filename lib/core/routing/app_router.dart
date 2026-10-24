import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/admin_placeholder_screen.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/mahasantri/presentation/mahasantri_home_placeholder.dart';
import '../../features/musyrif/presentation/musyrif_home_placeholder.dart';
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
      GoRoute(
        path: '/mahasantri',
        builder: (context, state) => const MahasantriHomePlaceholder(),
      ),
      GoRoute(
        path: '/musyrif',
        builder: (context, state) => const MusyrifHomePlaceholder(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminPlaceholderScreen(),
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
        final targetRoute = _targetRouteForRole(role);

        if (location == '/login' || location == '/splash') {
          return targetRoute;
        }

        // Mencegah akses lintas peran (misal Mahasantri membuka /musyrif)
        if (location != targetRoute) {
          return targetRoute;
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
