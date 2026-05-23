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

  AuthProvider(this.apiService) {
    _loadToken();
  }

  String? get token => _token;
  String? get role => _role;
  bool get isAuthenticated => _token != null && !JwtDecoder.isExpired(_token!);
  bool get isLoading => _isLoading;

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
    } catch (e) {
      print("Login error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String name, String email, String password, String role) async {
    _isLoading = true;
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
        return true;
      }
    } catch (e) {
      print("Register error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
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
