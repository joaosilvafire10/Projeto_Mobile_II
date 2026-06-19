import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'api_service.dart'; // Certifique-se de que o caminho do import esteja correto

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  Map<String, dynamic>? _currentUser;
  String? _errorMessage;

  // Getters para expor o estado para a UI
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// Tenta restaurar a sessão do usuário ao iniciar o app (Auto-Login)
  Future<bool> tryAutoLogin() async {
    final token = await _apiService.getAccessToken();
    if (token == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      // Chama a rota /api/auth/me do seu backend para revalidar o usuário
      final response = await _apiService.dio.get('/auth/me');

      if (response.statusCode == 200 && response.data['success'] == true) {
        _currentUser = response.data['data'];
        _errorMessage = null;
        return true;
      }
      
      return false;
    } catch (e) {
      // Se der erro (ex: token expirado e falha no refresh), limpa a sessão
      await logout();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Realiza o login utilizando o email e a senha
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
        
        // 🚀 CORREÇÃO CRUCIAL: Acessando a chave interna 'tokens' mapeada do backend
        final tokens = responseData['tokens'];
        _currentUser = responseData['user'];

        // Salva os tokens com segurança usando o FlutterSecureStorage através do seu ApiService
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
        if (error.response?.data != null && error.response?.data['message'] != null) {
          _errorMessage = error.response?.data['message'];
        } else {
          _errorMessage = 'Erro de conexão com o servidor Dokploy.';
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

  /// Finaliza a sessão do usuário tanto no backend quanto localmente
  Future<void> logout() async {
    try {
      // Tenta avisar o backend para invalidar o token atual
      await _apiService.dio.post('/auth/logout');
    } catch (_) {
      // Silencia erros de rede no logout para garantir que o cliente limpe o estado local de qualquer forma
    } finally {
      // Limpa os tokens do SecureStorage e reseta o estado do provider
      await _apiService.clearTokens();
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    }
  }
}
