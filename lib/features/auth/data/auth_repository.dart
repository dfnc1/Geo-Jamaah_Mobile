import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client/api_client.dart';
import '../../../core/token_store/token_store.dart';
import '../domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStore = ref.watch(tokenStoreProvider);
  return AuthRepository(
    apiClient: apiClient,
    tokenStore: tokenStore,
  );
});

class AuthRepository {
  final ApiClient apiClient;
  final TokenStore tokenStore;

  AuthRepository({
    required this.apiClient,
    required this.tokenStore,
  });

  /// Mengirim permintaan login ke POST /v1/auth/login
  /// Mengembalikan pasangan (UserModel, access_token) jika sukses.
  Future<({UserModel user, String token})> login({
    required String username,
    required String password,
    required String deviceId,
  }) async {
    final response = await apiClient.post(
      '/v1/auth/login',
      data: {
        'username': username,
        'password': password,
        'device_id': deviceId,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['access_token'] as String;
    final userJson = data['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);

    // Simpan token dan data user ke secure storage
    await tokenStore.saveToken(token);
    await tokenStore.saveUser(userJson);

    return (user: user, token: token);
  }

  /// Memulihkan sesi pengguna dari secure storage saat aplikasi dibuka
  Future<({UserModel user, String token})?> restoreSession() async {
    final token = await tokenStore.getToken();
    final userJson = await tokenStore.getUser();

    if (token != null && token.isNotEmpty && userJson != null) {
      final user = UserModel.fromJson(userJson);
      const validRoles = {'mahasantri', 'musyrif', 'admin'};
      if (!validRoles.contains(user.role.toLowerCase())) {
        await tokenStore.clear();
        return null;
      }
      return (user: user, token: token);
    }
    return null;
  }

  /// Menghapus sesi lokal
  Future<void> logout() async {
    await tokenStore.clear();
  }
}
