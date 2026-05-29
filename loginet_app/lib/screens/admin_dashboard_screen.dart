import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  AdminDashboardScreenState createState() => AdminDashboardScreenState();
}

class AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).fetchAdminOrders();
    });
  }

  void _showCreateOrderDialog() {
    final clienteCtrl = TextEditingController();
    final direccionCtrl = TextEditingController();
    int? selectedRepartidorId;
    String? selectedRepartidorName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_circle_outline, color: Theme.of(ctx).colorScheme.primary),
              SizedBox(width: 8),
              Text('Nueva Orden'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: clienteCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Cliente',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: direccionCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final result = await _showRepartidorSearchSheet();
                  if (result != null) {
                    setDialogState(() {
                      selectedRepartidorId = result['id'];
                      selectedRepartidorName = result['nombre'];
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Repartidor',
                    prefixIcon: Icon(Icons.delivery_dining),
                    suffixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    selectedRepartidorName ?? 'Toca para buscar repartidor',
                    style: TextStyle(
                      color: selectedRepartidorName != null
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar'),
            ),
            FilledButton(
              onPressed: selectedRepartidorId == null
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(ctx);
                      final orderProvider = Provider.of<OrderProvider>(
                              context,
                              listen: false);
                      bool success = await orderProvider.createOrder(
                        clienteCtrl.text,
                        direccionCtrl.text,
                        selectedRepartidorId!,
                      );
                      nav.pop();
                      if (success) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('✅ Orden creada exitosamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Error al crear orden'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
              child: Text('Crear Orden'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showRepartidorSearchSheet() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RepartidorSearchSheet(
        apiService: authProvider.apiService,
      ),
    );
  }

  void _showOrderDetail(Order order) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Orden #${order.id}',
                  style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Spacer(),
                _buildStatusChip(order.estado),
              ],
            ),
            Divider(height: 24),
            _detailRow(Icons.person_outline, 'Cliente', order.cliente),
            SizedBox(height: 12),
            _detailRow(
                Icons.location_on_outlined, 'Dirección', order.direccion),
            SizedBox(height: 12),
            _detailRow(Icons.delivery_dining, 'Repartidor',
                order.repartidor?.name ?? 'Sin asignar'),
            SizedBox(height: 12),
            _detailRow(Icons.calendar_today, 'Fecha',
                '${order.fechaCreacion.day}/${order.fechaCreacion.month}/${order.fechaCreacion.year} ${order.fechaCreacion.hour}:${order.fechaCreacion.minute}'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey[600],
                    fontWeight: FontWeight.w500)),
            Text(value, style: TextStyle(fontSize: 15)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String estado) {
    Color color;
    IconData icon;
    switch (estado) {
      case 'Entregado':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'En Camino':
        color = Colors.orange;
        icon = Icons.local_shipping;
        break;
      default:
        color = Colors.blue;
        icon = Icons.schedule;
    }
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(estado, style: TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: EdgeInsets.symmetric(horizontal: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Panel Admin'),
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
              onRefresh: () => orderProvider.fetchAdminOrders(),
              child: Column(
                children: [
                  _buildStatsRow(orderProvider, colorScheme),
                  _buildFilterChips(orderProvider, colorScheme),
                  Expanded(child: _buildOrdersList(orderProvider)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateOrderDialog,
        icon: Icon(Icons.add),
        label: Text('Nueva Orden'),
      ),
    );
  }

  Widget _buildStatsRow(OrderProvider provider, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _statCard('Pendientes', provider.countPendiente, Colors.blue, Icons.schedule),
          SizedBox(width: 8),
          _statCard('En Camino', provider.countEnCamino, Colors.orange, Icons.local_shipping),
          SizedBox(width: 8),
          _statCard('Entregados', provider.countEntregado, Colors.green, Icons.check_circle),
        ],
      ),
    );
  }

  Widget _statCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(height: 4),
              Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(OrderProvider provider, ColorScheme colorScheme) {
    final estados = ['Todas', 'Pendiente', 'En Camino', 'Entregado'];
    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: estados.map((e) {
          final selected = provider.statusFilter == e;
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(e),
              selected: selected,
              onSelected: (_) => provider.statusFilter = e,
              selectedColor: colorScheme.primaryContainer,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrdersList(OrderProvider provider) {
    if (provider.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 12),
            Text('No hay órdenes', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            Text('Crea una nueva orden con el botón +',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: 80, left: 12, right: 12),
      itemCount: provider.orders.length,
      itemBuilder: (ctx, i) {
        final order = provider.orders[i];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () => _showOrderDetail(order),
            leading: CircleAvatar(
              backgroundColor: order.estado == 'Entregado'
                  ? Colors.green[100]
                  : order.estado == 'En Camino'
                      ? Colors.orange[100]
                      : Colors.blue[100],
              child: Text(
                order.id.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: order.estado == 'Entregado'
                      ? Colors.green[800]
                      : order.estado == 'En Camino'
                          ? Colors.orange[800]
                          : Colors.blue[800],
                ),
              ),
            ),
            title: Text(order.cliente,
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.direccion,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  'Repartidor: ${order.repartidor?.name ?? 'Sin asignar'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: _buildStatusChip(order.estado),
          ),
        );
      },
    );
  }
}

class _RepartidorSearchSheet extends StatefulWidget {
  final ApiService apiService;

  const _RepartidorSearchSheet({required this.apiService});

  @override
  State<_RepartidorSearchSheet> createState() => _RepartidorSearchSheetState();
}

class _RepartidorSearchSheetState extends State<_RepartidorSearchSheet> {
  List<Map<String, dynamic>> _allRepartidores = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _error = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRepartidores();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchRepartidores() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await widget.apiService.get('/repartidores');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> data;
        if (decoded is List) {
          data = decoded;
        } else {
          final map = decoded as Map<String, dynamic>;
          data = map['data'] ?? [];
          debugPrint('Rol del usuario: ${map['userRole']}');
        }
        setState(() {
          _allRepartidores = data.cast<Map<String, dynamic>>();
          _filtered = List.from(_allRepartidores);
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _error = 'Sesión expirada. Inicia sesión nuevamente.';
          _isLoading = false;
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _error = 'No tienes permisos de administrador.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error al cargar repartidores (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: verifica que el servidor esté corriendo';
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filtered = List.from(_allRepartidores);
      } else {
        _filtered = _allRepartidores.where((r) {
          final nombre = (r['nombre'] ?? '').toString().toLowerCase();
          final email = (r['email'] ?? '').toString().toLowerCase();
          return nombre.contains(query) || email.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Icon(Icons.delivery_dining, color: colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Buscar Repartidor',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o email...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Cargando repartidores...'),
                        ],
                      ),
                    )
                  : _error.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: Colors.red[300]),
                              SizedBox(height: 12),
                              Text(_error,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.red[700])),
                              SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _fetchRepartidores,
                                icon: Icon(Icons.refresh),
                                label: Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : _filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_search,
                                      size: 48, color: Colors.grey[400]),
                                  SizedBox(height: 8),
                                  Text('No se encontraron repartidores'),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _filtered.length,
                              itemBuilder: (ctx, i) {
                                final rep = _filtered[i];
                                return Card(
                                  margin: EdgeInsets.only(bottom: 6),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          colorScheme.primaryContainer,
                                      child: Text(
                                        (rep['nombre'] ?? '?')[0]
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                    title: Text(rep['nombre'] ?? ''),
                                    subtitle: Text(rep['email'] ?? ''),
                                    trailing: Chip(
                                      label: Text('ID: ${rep['id']}',
                                          style: TextStyle(fontSize: 11)),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onTap: () =>
                                        Navigator.pop(context, rep),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
