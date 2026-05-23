import 'user.dart';

class Order {
  final int id;
  final String cliente;
  final String direccion;
  final String estado;
  final int repartidorId;
  final User? repartidor;

  Order({
    required this.id,
    required this.cliente,
    required this.direccion,
    required this.estado,
    required this.repartidorId,
    this.repartidor,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      cliente: json['cliente'] ?? '',
      direccion: json['direccion'] ?? '',
      estado: json['estado'] ?? '',
      repartidorId: json['repartidorId'] ?? 0,
      repartidor: json['repartidor'] != null ? User.fromJson(json['repartidor']) : null,
    );
  }
}
