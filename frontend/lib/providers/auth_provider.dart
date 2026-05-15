import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  ApiService? _apiServiceInstance;

  ApiService get _apiService {
    _apiServiceInstance ??= ApiService();
    return _apiServiceInstance!;
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token != null) {
      try {
        final response = await _apiService.dio.get('/auth/me');
        if (response.statusCode == 200) {
          _currentUser = UserModel.fromMap(response.data['data']);
          notifyListeners();
        }
      } catch (e) {
        // Token might be invalid or expired
        await logout();
      }
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
        final prefs = await SharedPreferences.getInstance();
        
        await prefs.setString('accessToken', data['tokens']['accessToken']);
        await prefs.setString('refreshToken', data['tokens']['refreshToken']);
        
        _currentUser = UserModel.fromMap(data['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        _errorMessage = e.response?.data['message'] ?? 'Erro ao realizar login';
      } else {
        _errorMessage = 'Erro de conexão com o servidor';
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
      if (e is DioException && e.response != null) {
        _errorMessage = e.response?.data['message'] ?? 'Erro ao registrar usuário';
      } else {
        _errorMessage = 'Erro de conexão com o servidor';
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    _errorMessage = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
