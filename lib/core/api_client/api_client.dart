import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_exception/app_exception.dart';
import '../token_store/token_store.dart';

/// Notifier event autentikasi (seperti sesi kedaluwarsa 401).
class AuthEventNotifier extends ChangeNotifier {
  void notifySessionExpired() => notifyListeners();
}

/// Provider untuk event autentikasi global.
final authEventProvider = Provider<AuthEventNotifier>((ref) {
  final notifier = AuthEventNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Provider global untuk ApiClient.
final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStore = ref.watch(tokenStoreProvider);
  final authEvent = ref.watch(authEventProvider);
  return ApiClient(
    tokenStore: tokenStore,
    onLogout: () async {
      await tokenStore.clear();
      authEvent.notifySessionExpired();
    },
  );
});

/// Client HTTP berbasis Dio dengan interceptor:
/// 1. Menyertakan token `Authorization: Bearer <token>`
/// 2. Membuka bungkus respons { data }
/// 3. Mengubah error menjadi AppException(code, message, status)
/// 4. Logout callback pada HTTP 401 untuk request terautentikasi
/// 5. Normalisasi base URL dan path endpoint /v1
class ApiClient {
  final Dio dio;
  final TokenStore tokenStore;
  final FutureOr<void> Function()? onLogout;

  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/v1',
  );

  /// Memastikan base URL selalu berakhir dengan prefix `/v1`
  static String normalizeBaseUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (!trimmed.endsWith('/v1')) {
      trimmed = '$trimmed/v1';
    }
    return trimmed;
  }

  ApiClient({
    required this.tokenStore,
    this.onLogout,
    String? baseUrl,
    Dio? customDio,
  }) : dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: normalizeBaseUrl(baseUrl ?? defaultBaseUrl),
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    dio.interceptors.add(_buildInterceptor());
  }

  Interceptor _buildInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Normalisasi path agar tidak terjadi duplikasi '/v1/v1/'
        final base = options.baseUrl;
        final hasV1InBase = base.endsWith('/v1') || base.endsWith('/v1/');
        if (hasV1InBase && options.path.startsWith('/v1/')) {
          options.path = options.path.substring(3); // '/v1/path' -> '/path'
        } else if (hasV1InBase && options.path.startsWith('v1/')) {
          options.path = '/${options.path.substring(3)}';
        } else if (!options.path.startsWith('/') &&
            !options.path.startsWith('http://') &&
            !options.path.startsWith('https://')) {
          options.path = '/${options.path}';
        }

        // Jangan tempel token sisa ke endpoint login publik agar 401 gagal login tidak memicu logout global.
        if (options.path != '/auth/login') {
          final token = await tokenStore.getToken();
          if (token != null &&
              token.isNotEmpty &&
              !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Membuka bungkus { data } dari format server { success, statusCode, message, data }
        if (response.data is Map<String, dynamic>) {
          final map = response.data as Map<String, dynamic>;
          if (map.containsKey('data')) {
            response.data = map['data'];
          }
        }
        return handler.next(response);
      },
      onError: (err, handler) async {
        final errResponse = err.response;
        int? statusCode = errResponse?.statusCode;
        String code = 'ERR_NETWORK';
        String message = 'Terjadi kesalahan jaringan. Periksa koneksi Anda.';
        dynamic details;

        if (errResponse != null && errResponse.data is Map<String, dynamic>) {
          final resData = errResponse.data as Map<String, dynamic>;
          code = resData['error']?.toString() ?? 'ERR_SERVER';
          message = resData['message']?.toString() ?? 'Terjadi kesalahan pada server';
          statusCode = (resData['statusCode'] as num?)?.toInt() ?? statusCode;
          details = resData;
        } else if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.sendTimeout) {
          code = 'ERR_TIMEOUT';
          message = 'Batas waktu koneksi terlampaui. Silakan coba lagi.';
        } else if (err.type == DioExceptionType.badCertificate) {
          code = 'ERR_CERTIFICATE';
          message = 'Sertifikat keamanan tidak valid.';
        } else if (err.type == DioExceptionType.connectionError) {
          code = 'ERR_CONNECTION';
          message = 'Gagal terhubung ke server. Pastikan server aktif.';
        }

        // Panggil callback logout jika 401 pada request terautentikasi
        final authHeader = err.requestOptions.headers['Authorization'];
        final isAuthRequest = authHeader != null &&
            authHeader is String &&
            authHeader.trim().isNotEmpty;

        if (statusCode == 401 && isAuthRequest) {
          await onLogout?.call();
        }

        final appException = AppException(
          code: code,
          message: message,
          status: statusCode,
          details: details,
        );

        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            type: err.type,
            error: appException,
            message: message,
          ),
        );
      },
    );
  }

  // ── Helper Methods ────────────────────────────────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'ERR_UNKNOWN', message: e.message ?? 'Unknown error');
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'ERR_UNKNOWN', message: e.message ?? 'Unknown error');
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'ERR_UNKNOWN', message: e.message ?? 'Unknown error');
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'ERR_UNKNOWN', message: e.message ?? 'Unknown error');
    }
  }
}
