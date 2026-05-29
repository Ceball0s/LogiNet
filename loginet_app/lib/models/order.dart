import 'user.dart';

class Order {
  final int id;
  final String cliente;
  final String direccion;
  final String estado;
  final DateTime fechaCreacion;
  final int repartidorId;
  final User? repartidor;

  Order({
    required this.id,
    required this.cliente,
    required this.direccion,
    required this.estado,
    required this.fechaCreacion,
    required this.repartidorId,
    this.repartidor,
  });

  String get estadoIcon {
    switch (estado) {
      case 'Entregado':
        return '✅';
      case 'En Camino':
        return '🚚';
      default:
        return '⏳';
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      cliente: json['cliente'] ?? '',
      direccion: json['direccion'] ?? '',
      estado: json['estado'] ?? '',
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'])
          : DateTime.now(),
      repartidorId: json['repartidorId'] ?? 0,
      repartidor:
          json['repartidor'] != null ? User.fromJson(json['repartidor']) : null,
    );
  }
}
