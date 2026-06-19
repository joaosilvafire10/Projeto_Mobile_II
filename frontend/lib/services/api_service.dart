import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Serviço central de HTTP.
/// - Usa [FlutterSecureStorage] para armazenar tokens de forma segura.
/// - Adiciona automaticamente o header Authorization em todas as requisições.
/// - Faz refresh automático do access_token quando recebe 401.
class ApiService {
  static ApiService? _instance;
  factory ApiService() {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  late Dio dio;

  // Armazenamento seguro — NUNCA usa SharedPreferences para tokens
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyAccessToken = 'accessToken';
  static const _keyRefreshToken = 'refreshToken';

  ApiService._internal() {
    String baseUrl;
    if (kIsWeb) {
      baseUrl = 'http://api.193.122.213.155.nip.io/api';
    } else {
      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          baseUrl = 'http://10.0.2.2:3000/api';
        } else {
          baseUrl = 'http://127.0.0.1:3000/api';
        }
      } catch (_) {
        baseUrl = 'http://127.0.0.1:3000/api';
      }
    }

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 45),
      contentType: 'application/json',
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _keyAccessToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final isNotAuthRoute = !error.requestOptions.path.contains('/auth/login') &&
            !error.requestOptions.path.contains('/auth/refresh');

        if (isUnauthorized && isNotAuthRoute) {
          final success = await _refreshToken();
          if (success) {
            final token = await _storage.read(key: _keyAccessToken);
            error.requestOptions.headers['Authorization'] = 'Bearer $token';

            final opts = Options(
              method: error.requestOptions.method,
              headers: error.requestOptions.headers,
            );

            try {
              final response = await dio.request(
                error.requestOptions.path,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
                options: opts,
              );
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  // ── Métodos de token (acesso seguro) ──────────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);

  // ── Refresh automático do access_token ───────────────────────────────────

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: _keyRefreshToken);
      if (refreshToken == null) return false;

      final response = await dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await saveTokens(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        );
        return true;
      }
    } catch (_) {
      await clearTokens();
    }
    return false;
  }
}
