import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  final ApiService apiService;
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  String _statusFilter = 'Todas';

  OrderProvider(this.apiService);

  List<Order> get orders {
    if (_statusFilter == 'Todas') return _orders;
    return _orders.where((o) => o.estado == _statusFilter).toList();
  }

  List<Order> get allOrders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get statusFilter => _statusFilter;

  set statusFilter(String value) {
    _statusFilter = value;
    notifyListeners();
  }

  int get countPendiente =>
      _orders.where((o) => o.estado == 'Pendiente').length;
  int get countEnCamino =>
      _orders.where((o) => o.estado == 'En Camino').length;
  int get countEntregado =>
      _orders.where((o) => o.estado == 'Entregado').length;

  void _handleError(dynamic e, String context) {
    _error = 'Error en $context: ${e.toString()}';
    debugPrint(_error);
    notifyListeners();
  }

  Future<void> fetchAdminOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/ordenes');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _orders = data.map((json) => Order.fromJson(json)).toList();
      } else {
        _error =
            'Error al cargar órdenes (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      _handleError(e, 'cargar órdenes');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchRepartidorOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/ordenes/mis-entregas');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _orders = data.map((json) => Order.fromJson(json)).toList();
      } else {
        _error =
            'Error al cargar mis entregas (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      _handleError(e, 'cargar mis entregas');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createOrder(
      String cliente, String direccion, int repartidorId) async {
    try {
      final response = await apiService.post('/ordenes', {
        'cliente': cliente,
        'direccion': direccion,
        'repartidorId': repartidorId,
      });
      if (response.statusCode == 201) {
        await fetchAdminOrders();
        return true;
      }
      _error = 'Error al crear orden (${response.statusCode})';
    } catch (e) {
      _handleError(e, 'crear orden');
    }
    return false;
  }

  Future<bool> updateOrderStatus(int id, String estado) async {
    try {
      final response = await apiService.put('/ordenes/$id/estado', {
        'estado': estado,
      });
      if (response.statusCode == 200) {
        await fetchRepartidorOrders();
        return true;
      }
      _error = 'Error al actualizar estado (${response.statusCode})';
    } catch (e) {
      _handleError(e, 'actualizar estado');
    }
    return false;
  }
}
