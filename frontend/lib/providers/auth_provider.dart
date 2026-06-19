import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

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
    } finally {
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
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          _errorMessage = 'Tempo de conexão esgotado. Verifique o servidor.';
        } else if (e.type == DioExceptionType.connectionError) {
          _errorMessage = 'Não foi possível conectar ao servidor. Verifique a URL da API.';
        } else {
          _errorMessage = 'Erro de rede: ${e.message}';
        }
      } else {
        _errorMessage = 'Erro: ${e.toString()}';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String department,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _apiService.dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'department': department,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _errorMessage = null;
        return true;
      }

      _errorMessage = 'Falha ao criar usuário. Tente novamente.';
      return false;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data != null && e.response?.data['message'] != null) {
          _errorMessage = e.response?.data['message'].toString();
        } else {
          _errorMessage = 'Erro de conexão com o servidor.';
        }
      } else {
        _errorMessage = 'Ocorreu um erro inesperado.';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.dio.post('/auth/logout');
    } catch (_) {
    } finally {
      await _apiService.clearTokens();
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    }
  }
}
