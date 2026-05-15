import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static ApiService? _instance;
  factory ApiService() {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  late Dio dio;

  ApiService._internal() {
    String baseUrl;
    if (kIsWeb) {
      baseUrl = 'http://localhost:3000/api';
    } else {
      baseUrl = 'http://localhost:3000/api';
      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          baseUrl = 'http://10.0.2.2:3000/api';
        }
      } catch (_) {
        // Fallback para localhost
      }
    }

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401 &&
            error.requestOptions.path != '/auth/login' &&
            error.requestOptions.path != '/auth/refresh') {
          final success = await _refreshToken();
          if (success) {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('accessToken');
            error.requestOptions.headers['Authorization'] = 'Bearer $token';

            final opts = Options(
              method: error.requestOptions.method,
              headers: error.requestOptions.headers,
            );

            final response = await dio.request(
              error.requestOptions.path,
              data: error.requestOptions.data,
              queryParameters: error.requestOptions.queryParameters,
              options: opts,
            );
            return handler.resolve(response);
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refreshToken');

      if (refreshToken == null) return false;

      final response = await dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await prefs.setString('accessToken', data['accessToken']);
        await prefs.setString('refreshToken', data['refreshToken']);
        return true;
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
    }
    return false;
  }
}
