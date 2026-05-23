import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';

class RepartidorDashboardScreen extends StatefulWidget {
  @override
  _RepartidorDashboardScreenState createState() => _RepartidorDashboardScreenState();
}

class _RepartidorDashboardScreenState extends State<RepartidorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).fetchRepartidorOrders();
    });
  }

  void _showUpdateStatusDialog(int orderId, String currentStatus) {
    String newStatus = currentStatus;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Actualizar Estado'),
        content: DropdownButtonFormField<String>(
          value: ['Pendiente', 'En Camino', 'Entregado'].contains(newStatus) ? newStatus : 'Pendiente',
          items: ['Pendiente', 'En Camino', 'Entregado'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (val) {
            newStatus = val!;
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              bool success = await Provider.of<OrderProvider>(context, listen: false).updateOrderStatus(orderId, newStatus);
              Navigator.pop(ctx);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Estado actualizado')));
              }
            },
            child: Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Entregas'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          )
        ],
      ),
      body: orderProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => orderProvider.fetchRepartidorOrders(),
              child: ListView.builder(
                itemCount: orderProvider.orders.length,
                itemBuilder: (ctx, i) {
                  final order = orderProvider.orders[i];
                  return ListTile(
                    leading: Icon(Icons.local_shipping, color: order.estado == 'Entregado' ? Colors.green : Colors.orange),
                    title: Text('${order.cliente} - ${order.estado}'),
                    subtitle: Text(order.direccion),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _showUpdateStatusDialog(order.id, order.estado),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
