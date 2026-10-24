import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_jamaah/core/api_client/api_client.dart';
import 'package:geo_jamaah/core/app_exception/app_exception.dart';
import 'package:geo_jamaah/core/token_store/token_store.dart';

/// Mock HttpClientAdapter untuk menyimulasikan berbagai respons server dan kondisi jaringan.
class MockHttpAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  MockHttpAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Fake TokenStore in-memory untuk pengujian unit.
class FakeTokenStore extends TokenStore {
  String? _token;
  Map<String, dynamic>? _user;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> deleteToken() async => _token = null;

  @override
  Future<void> saveUser(Map<String, dynamic> userJson) async => _user = userJson;

  @override
  Future<Map<String, dynamic>?> getUser() async => _user;

  @override
  Future<void> deleteUser() async => _user = null;

  @override
  Future<void> clear() async {
    _token = null;
    _user = null;
  }
}

void main() {
  late FakeTokenStore tokenStore;

  setUp(() {
    tokenStore = FakeTokenStore();
  });

  group('ApiClient - Pembuka Bungkus Response {data}', () {
    test('berhasil membuka payload Map dari {success, statusCode, message, data}', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        final payload = {
          'success': true,
          'statusCode': 200,
          'message': 'Operasi berhasil',
          'data': {'id': 'M001', 'nama': 'Ahmad Fauzi'},
        };
        return ResponseBody.fromString(
          jsonEncode(payload),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = ApiClient(
        tokenStore: tokenStore,
        customDio: dio,
      );

      final res = await client.get('/v1/test');

      expect(res.data, isA<Map<String, dynamic>>());
      expect(res.data['id'], equals('M001'));
      expect(res.data['nama'], equals('Ahmad Fauzi'));
    });

    test('berhasil membuka payload List dari {success, statusCode, message, data}', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        final payload = {
          'success': true,
          'statusCode': 200,
          'message': 'OK',
          'data': [
            {'nama_sholat': 'Subuh'},
            {'nama_sholat': 'Dzuhur'},
          ],
        };
        return ResponseBody.fromString(
          jsonEncode(payload),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = ApiClient(
        tokenStore: tokenStore,
        customDio: dio,
      );

      final res = await client.get('/v1/jadwal');

      expect(res.data, isA<List>());
      expect((res.data as List).length, equals(2));
      expect(res.data[0]['nama_sholat'], equals('Subuh'));
    });

    test('menangani data null pada respons sukses', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        final payload = {
          'success': true,
          'statusCode': 200,
          'message': 'Data dihapus',
          'data': null,
        };
        return ResponseBody.fromString(
          jsonEncode(payload),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = ApiClient(
        tokenStore: tokenStore,
        customDio: dio,
      );

      final res = await client.delete('/v1/item/1');

      expect(res.data, isNull);
    });
  });

  group('ApiClient - Pemetaan Error ke AppException', () {
    test('memetakan respons error server 404 ke AppException yang tepat', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        final payload = {
          'success': false,
          'statusCode': 404,
          'message': 'Masjid tidak ditemukan',
          'error': 'ERR_MASJID_NOT_FOUND',
        };
        return ResponseBody.fromString(
          jsonEncode(payload),
          404,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = ApiClient(
        tokenStore: tokenStore,
        customDio: dio,
      );

      try {
        await client.get('/v1/masjid/999');
        fail('Seharusnya melempar AppException');
      } on AppException catch (e) {
        expect(e.code, equals('ERR_MASJID_NOT_FOUND'));
        expect(e.message, equals('Masjid tidak ditemukan'));
        expect(e.status, equals(404));
      }
    });

    test('memetakan respons validasi 400 ke AppException', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        final payload = {
          'success': false,
          'statusCode': 400,
          'message': 'device_id harus diisi',
          'error': 'ERR_DEVICE_ID_REQUIRED',
        };
        return ResponseBody.fromString(
          jsonEncode(payload),
          400,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = ApiClient(
        tokenStore: tokenStore,
        customDio: dio,
      );

      try {
        await client.post('/v1/auth/login', data: {'username': 'test'});
        fail('Seharusnya melempar AppException');
      } on AppException catch (e) {
        expect(e.code, equals('ERR_DEVICE_ID_REQUIRED'));
        expect(e.message, equals('device_id harus diisi'));
        expect(e.status, equals(400));
      }
    });

    test('memetakan timeout jaringan ke AppException(code: ERR_TIMEOUT)', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timed out',
        );
      });

      final client = ApiClient(
        tokenStore: tokenStore,
        customDio: dio,
      );

      try {
        await client.get('/v1/timeout');
        fail('Seharusnya melempar AppException');
      } on AppException catch (e) {
        expect(e.code, equals('ERR_TIMEOUT'));
        expect(e.message, contains('Batas waktu koneksi'));
      }
    });
  });

  group('ApiClient - Autentikasi dan Logout 401', () {
    test('menyisipkan header Authorization: Bearer bila token tersimpan', () async {
      await tokenStore.saveToken('jwt-sample-token-12345');
      String? capturedAuthHeader;

      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        capturedAuthHeader = options.headers['Authorization'] as String?;
        return ResponseBody.fromString(
          jsonEncode({'success': true, 'statusCode': 200, 'message': 'OK', 'data': {}}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = ApiClient(
        tokenStore: tokenStore,
        customDio: dio,
      );

      await client.get('/v1/protected');

      expect(capturedAuthHeader, equals('Bearer jwt-sample-token-12345'));
    });

    test('memanggil callback onLogout saat menerima 401 pada request terautentikasi', () async {
      await tokenStore.saveToken('expired-token');
      bool logoutCalled = false;

      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        final payload = {
          'success': false,
          'statusCode': 401,
          'message': 'Token kedaluwarsa',
          'error': 'ERR_UNAUTHORIZED',
        };
        return ResponseBody.fromString(
          jsonEncode(payload),
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = ApiClient(
        tokenStore: tokenStore,
        onLogout: () {
          logoutCalled = true;
        },
        customDio: dio,
      );

      try {
        await client.get('/v1/me');
      } catch (_) {}

      expect(logoutCalled, isTrue);
    });

    test('tidak memanggil onLogout pada 401 jika request tidak terautentikasi (misal login gagal)', () async {
      bool logoutCalled = false;

      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        final payload = {
          'success': false,
          'statusCode': 401,
          'message': 'Username atau password salah',
          'error': 'ERR_INVALID_CREDENTIALS',
        };
        return ResponseBody.fromString(
          jsonEncode(payload),
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = ApiClient(
        tokenStore: tokenStore,
        onLogout: () {
          logoutCalled = true;
        },
        customDio: dio,
      );

      try {
        await client.post('/v1/auth/login', data: {'username': 'wrong'});
      } catch (_) {}

      expect(logoutCalled, isFalse);
    });
  });
}
