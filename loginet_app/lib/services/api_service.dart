import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  final String _baseUrl = Constants.apiUrl;
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.get(url, headers: _headers).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw SocketException('Tiempo de espera agotado'),
    );
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.post(url, headers: _headers, body: json.encode(body)).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw SocketException('Tiempo de espera agotado'),
    );
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.put(url, headers: _headers, body: json.encode(body)).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw SocketException('Tiempo de espera agotado'),
    );
  }
}
