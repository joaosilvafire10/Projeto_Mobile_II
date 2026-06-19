import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço central de HTTP.
/// - Na Web usa [SharedPreferences] (localStorage) para tokens.
/// - No mobile usa [FlutterSecureStorage] (keychain/keystore).
/// - Adiciona automaticamente o header Authorization em todas as requisições.
/// - Faz refresh automático do access_token quando recebe 401.
class ApiService {
  static ApiService? _instance;
  factory ApiService() {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  late Dio dio;

  // Secure storage apenas para mobile
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyAccessToken = 'accessToken';
  static const _keyRefreshToken = 'refreshToken';

  // ── Abstração de storage compatível com Web e Mobile ─────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccessToken, accessToken);
      await prefs.setString(_keyRefreshToken, refreshToken);
    } else {
      await _secureStorage.write(key: _keyAccessToken, value: accessToken);
      await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
    }
  }

  Future<void> clearTokens() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAccessToken);
      await prefs.remove(_keyRefreshToken);
    } else {
      await _secureStorage.delete(key: _keyAccessToken);
      await _secureStorage.delete(key: _keyRefreshToken);
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyAccessToken);
    } else {
      return _secureStorage.read(key: _keyAccessToken);
    }
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRefreshToken);
    } else {
      return _secureStorage.read(key: _keyRefreshToken);
    }
  }

  // ── Construtor interno ────────────────────────────────────────────────────

  ApiService._internal() {
    const String prodUrl = 'http://api.193.122.213.155.nip.io/api';

    String baseUrl;

    if (kDebugMode) {
      if (kIsWeb) {
        baseUrl = 'http://127.0.0.1:3000/api';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        baseUrl = 'http://10.0.2.2:3000/api';
      } else {
        baseUrl = 'http://127.0.0.1:3000/api';
      }
    } else {
      baseUrl = prodUrl;
    }

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 45),
      contentType: 'application/json',
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {
          // Ignora erro de leitura do token — a requisição segue sem auth
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final isNotAuthRoute =
            !error.requestOptions.path.contains('/auth/login') &&
                !error.requestOptions.path.contains('/auth/refresh');

        if (isUnauthorized && isNotAuthRoute) {
          final success = await _refreshToken();
          if (success) {
            final token = await getAccessToken();
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

  // ── Refresh automático do access_token ───────────────────────────────────

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200) {
        final responseData = response.data['data'];
        final tokens = responseData['tokens'];

        await saveTokens(
          accessToken: tokens['accessToken'] as String,
          refreshToken: tokens['refreshToken'] as String,
        );
        return true;
      }
    } catch (_) {
      await clearTokens();
    }
    return false;
  }
}
