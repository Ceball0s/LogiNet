import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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
          title: Text('Nueva Orden'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: clienteCtrl, decoration: InputDecoration(labelText: 'Cliente')),
              TextField(controller: direccionCtrl, decoration: InputDecoration(labelText: 'Dirección')),
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
                    suffixIcon: Icon(Icons.search),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar')),
            ElevatedButton(
              onPressed: selectedRepartidorId == null
                  ? null
                  : () async {
                      bool success = await Provider.of<OrderProvider>(context, listen: false).createOrder(
                        clienteCtrl.text,
                        direccionCtrl.text,
                        selectedRepartidorId!,
                      );
                      Navigator.pop(ctx);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Orden creada')));
                      }
                    },
              child: Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showRepartidorSearchSheet() async {
    final apiService = Provider.of<AuthProvider>(context, listen: false).apiService;

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _RepartidorSearchSheet(apiService: apiService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Panel de Administrador'),
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
              onRefresh: () => orderProvider.fetchAdminOrders(),
              child: ListView.builder(
                itemCount: orderProvider.orders.length,
                itemBuilder: (ctx, i) {
                  final order = orderProvider.orders[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(order.id.toString())),
                    title: Text('${order.cliente} - ${order.estado}'),
                    subtitle: Text(order.direccion),
                    trailing: Text('Repartidor: ${order.repartidor?.name ?? order.repartidorId}'),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateOrderDialog,
        child: Icon(Icons.add),
      ),
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
    try {
      final response = await widget.apiService.get('/repartidores');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _allRepartidores = data.cast<Map<String, dynamic>>();
          _filtered = _allRepartidores;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error al cargar repartidores';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _allRepartidores.where((r) {
        final nombre = (r['nombre'] ?? '').toString().toLowerCase();
        final email = (r['email'] ?? '').toString().toLowerCase();
        return nombre.contains(query) || email.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
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
            Text(
              'Buscar Repartidor',
              style: Theme.of(context).textTheme.titleLarge,
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
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? Center(child: Text(_error, style: TextStyle(color: Colors.red)))
                      : _filtered.isEmpty
                          ? Center(child: Text('No se encontraron repartidores'))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _filtered.length,
                              itemBuilder: (ctx, i) {
                                final rep = _filtered[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      (rep['nombre'] ?? '?')[0].toUpperCase(),
                                    ),
                                  ),
                                  title: Text(rep['nombre'] ?? ''),
                                  subtitle: Text(rep['email'] ?? ''),
                                  trailing: Text('ID: ${rep['id']}',
                                      style: TextStyle(color: Colors.grey)),
                                  onTap: () => Navigator.pop(context, rep),
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
