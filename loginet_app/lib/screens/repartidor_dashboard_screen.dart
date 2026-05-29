import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';

class RepartidorDashboardScreen extends StatefulWidget {
  const RepartidorDashboardScreen({super.key});

  @override
  RepartidorDashboardScreenState createState() => RepartidorDashboardScreenState();
}

class RepartidorDashboardScreenState
    extends State<RepartidorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false)
          .fetchRepartidorOrders();
    });
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'Entregado':
        return Colors.green;
      case 'En Camino':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _estadoIcon(String estado) {
    switch (estado) {
      case 'Entregado':
        return Icons.check_circle;
      case 'En Camino':
        return Icons.local_shipping;
      default:
        return Icons.schedule;
    }
  }

  void _showUpdateStatusDialog(int orderId, String currentStatus) {
    String newStatus = currentStatus;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.update, color: Theme.of(ctx).colorScheme.primary),
            SizedBox(width: 8),
            Text('Actualizar Estado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Selecciona el nuevo estado para la orden #$orderId:'),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: ['Pendiente', 'En Camino', 'Entregado']
                      .contains(newStatus)
                  ? newStatus
                  : 'Pendiente',
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.local_shipping),
                border: OutlineInputBorder(),
              ),
              items: ['Pendiente', 'En Camino', 'Entregado'].map((String v) {
                return DropdownMenuItem<String>(
                  value: v,
                  child: Row(
                    children: [
                      Icon(_estadoIcon(v),
                          size: 20, color: _estadoColor(v)),
                      SizedBox(width: 8),
                      Text(v),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                newStatus = val!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(ctx);
              final orderProvider = Provider.of<OrderProvider>(
                  context, listen: false);
              bool success = await orderProvider.updateOrderStatus(
                  orderId, newStatus);
              nav.pop();
              if (success) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('✅ Estado actualizado a "$newStatus"'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error al actualizar estado'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Entregas'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => authProvider.logout(),
          )
        ],
      ),
      body: orderProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => orderProvider.fetchRepartidorOrders(),
              child: Column(
                children: [
                  _buildStatsRow(orderProvider),
                  Expanded(child: _buildOrdersList(orderProvider, colorScheme)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsRow(OrderProvider provider) {
    final total = provider.allOrders.length;
    final entregados = provider.countEntregado;
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, color: Colors.blue, size: 28),
                    Text('$total',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('Total', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Card(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 28),
                    Text('$entregados',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('Entregados',
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Card(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Icon(Icons.pending_outlined,
                        color: Colors.orange, size: 28),
                    Text('${total - entregados}',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('Pendientes',
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(
      OrderProvider provider, ColorScheme colorScheme) {
    if (provider.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.celebration_outlined,
                size: 64, color: Colors.grey[400]),
            SizedBox(height: 12),
            Text('No tienes entregas asignadas',
                style: TextStyle(fontSize: 16)),
            Text('Cuando te asignen órdenes aparecerán aquí',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12),
      itemCount: provider.orders.length,
      itemBuilder: (ctx, i) {
        final order = provider.orders[i];
        final color = _estadoColor(order.estado);

        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(_estadoIcon(order.estado), color: color),
            ),
            title: Text(order.cliente,
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.direccion,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  '${order.fechaCreacion.day}/${order.fechaCreacion.month}/${order.fechaCreacion.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(order.estado,
                      style: TextStyle(
                          color: Colors.white, fontSize: 11)),
                  backgroundColor: color,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(horizontal: 4),
                ),
                SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Actualizar estado',
                  onPressed: () => _showUpdateStatusDialog(
                      order.id, order.estado),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
