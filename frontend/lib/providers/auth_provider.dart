import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  // Usuários de demonstração
  static final Map<String, Map<String, String>> _demoUsers = {
    'admin@empresa.com': {
      'password': 'admin123',
      'name': 'Administrador',
      'department': 'TI',
      'role': 'admin',
    },
    'joao@empresa.com': {
      'password': '123456',
      'name': 'João Silva',
      'department': 'Financeiro',
      'role': 'user',
    },
    'maria@empresa.com': {
      'password': '123456',
      'name': 'Maria Santos',
      'department': 'RH',
      'role': 'user',
    },
    'pedro@empresa.com': {
      'password': '123456',
      'name': 'Pedro Costa',
      'department': 'Comercial',
      'role': 'user',
    },
  };

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Simula delay de autenticação
    await Future.delayed(const Duration(milliseconds: 1500));

    final userInfo = _demoUsers[email.toLowerCase().trim()];

    if (userInfo == null || userInfo['password'] != password) {
      _isLoading = false;
      _errorMessage = 'E-mail ou senha incorretos';
      notifyListeners();
      return false;
    }

    _currentUser = UserModel(
      id: email.hashCode.toString(),
      name: userInfo['name']!,
      email: email.toLowerCase().trim(),
      department: userInfo['department']!,
      role: userInfo['role']!,
    );

    _isLoading = false;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
