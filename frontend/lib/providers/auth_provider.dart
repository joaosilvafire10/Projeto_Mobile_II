import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

/// Provider de autenticação.
/// - Persiste tokens com [ApiService] (FlutterSecureStorage) — NUNCA SharedPreferences.
/// - Verifica sessão automaticamente ao abrir o app.
/// - Realiza refresh automático via interceptador do Dio.
class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _loadUser();
  }

  /// Verifica se há token salvo e recupera o perfil do usuário
  Future<void> _loadUser() async {
    final token = await _apiService.getAccessToken();
    if (token == null) return;

    try {
      final response = await _apiService.dio.get('/auth/me');
      if (response.statusCode == 200) {
        _currentUser = UserModel.fromMap(response.data['data']);
        notifyListeners();
      }
    } catch (_) {
      // Token inválido — limpa sessão silenciosamente
      await _apiService.clearTokens();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];

        // Armazena tokens com segurança via FlutterSecureStorage
        await _apiService.saveTokens(
          accessToken: data['tokens']['accessToken'] as String,
          refreshToken: data['tokens']['refreshToken'] as String,
        );

        _currentUser = UserModel.fromMap(data['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Erro no login: $e');
      if (e is DioException && e.response != null) {
        _errorMessage = e.response?.data['message'] ?? 'Erro ao realizar login';
      } else {
        _errorMessage = 'Sem conexão — verifique sua internet';
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? role,
    String? department,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'department': department,
      });

      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Erro no registro: $e');
      if (e is DioException && e.response != null) {
        _errorMessage = e.response?.data['message'] ?? 'Erro ao registrar usuário';
      } else {
        _errorMessage = 'Sem conexão — verifique sua internet';
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Encerra a sessão: remove tokens do armazenamento seguro e retorna à tela de login.
  Future<void> logout() async {
    try {
      await _apiService.dio.post('/auth/logout');
    } catch (e) {
      debugPrint('Erro ao invalidar token no logout: $e');
    }
    _currentUser = null;
    _errorMessage = null;
    // Remove tokens do FlutterSecureStorage
    await _apiService.clearTokens();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
