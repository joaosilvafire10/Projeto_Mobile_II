import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  Map<String, dynamic>? _currentUser;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> tryAutoLogin() async {
    final token = await _apiService.getAccessToken();
    if (token == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.dio.get('/auth/me');

      if (response.statusCode == 200 && response.data['success'] == true) {
        _currentUser = response.data['data'];
        _errorMessage = null;
        return true;
      }
      return false;
    } catch (e) {
      await logout();
      return false;
    } finaly {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _apiService.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final responseData = response.data['data'];
        final tokens = responseData['tokens'];
        _currentUser = responseData['user'];

        await _apiService.saveTokens(
          accessToken: tokens['accessToken'] as String,
          refreshToken: tokens['refreshToken'] as String,
        );

        _errorMessage = null;
        return true;
      }

      _errorMessage = 'Falha ao realizar login. Tente novamente.';
      return false;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data != null && e.response?.data['message'] != null) {
          _errorMessage = e.response?.data['message'].toString();
        } else {
          _errorMessage = 'Erro de conexão com o servidor Dokploy.';
        }
      } else {
        _errorMessage = 'Ocorreu um erro inesperado.';
      }
      return false;
    } finaly {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.dio.post('/auth/logout');
    } catch (_) {
    } finaly {
      await _apiService.clearTokens();
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    }
  }
}
