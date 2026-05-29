import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService apiService;

  String? _token;
  String? _role;
  bool _isLoading = false;
  String? _lastError;

  AuthProvider(this.apiService) {
    _loadToken();
  }

  String? get token => _token;
  String? get role => _role;
  bool get isAuthenticated => _token != null && !JwtDecoder.isExpired(_token!);
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    if (_token != null && !JwtDecoder.isExpired(_token!)) {
      apiService.setToken(_token);
      _decodeRole(_token!);
    } else {
      _token = null;
      apiService.setToken(null);
    }
    notifyListeners();
  }

  void _decodeRole(String token) {
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    _role = decodedToken['role'];
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);

        apiService.setToken(_token);
        _decodeRole(_token!);

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _lastError = 'Credenciales inválidas';
    } catch (e) {
      debugPrint("Login error: $e");
      _lastError = 'Error de conexión con el servidor';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password, String role) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await apiService.post('/auth/register', {
        'nombre': name,
        'email': email,
        'password': password,
        'rol': role,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return {'success': true};
      }

      String msg = 'Error del servidor';
      try {
        final body = json.decode(response.body);
        msg = body['message'] ?? 'Error $response.statusCode';
      } catch (_) {}

      _lastError = msg;
      return {'success': false, 'error': msg};
    } catch (e) {
      debugPrint("Register error: $e");
      _lastError = 'Error de conexión con el servidor';
      return {'success': false, 'error': _lastError};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    apiService.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    notifyListeners();
  }
}
