import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  final ApiService apiService;
  List<Order> _orders = [];
  bool _isLoading = false;

  OrderProvider(this.apiService);

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> fetchAdminOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.get('/ordenes');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _orders = data.map((json) => Order.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error fetching admin orders: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchRepartidorOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.get('/ordenes/mis-entregas');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _orders = data.map((json) => Order.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error fetching repartidor orders: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createOrder(String cliente, String direccion, int repartidorId) async {
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
    } catch (e) {
      print("Error creating order: $e");
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
    } catch (e) {
      print("Error updating status: $e");
    }
    return false;
  }
}
