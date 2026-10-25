import 'package:flutter/material.dart';

import '../features/items/presentation/items_screen.dart';
import '../features/stocks/presentation/stocks_screen.dart';
import '../features/transfers/presentation/transfers_screen.dart';
import '../features/warehouses/data/warehouse.dart';
import '../features/warehouses/presentation/warehouses_screen.dart';
import 'app_dependencies.dart';
import 'routes.dart';
import 'theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 2;
  int _revision = 0;
  Warehouse? _selectedWarehouse;

  static const _labels = ['Barang', 'Gudang', 'Stok Gudang', 'Mutasi'];
  static const _icons = [
    Icons.inventory_2_outlined,
    Icons.warehouse_outlined,
    Icons.layers_outlined,
    Icons.swap_horiz,
  ];

  Future<void> _newTransfer([Warehouse? source]) async {
    final transfer = await AppRoutes.newTransfer(
      context,
      widget.dependencies,
      source: source,
    );

    if (!mounted) return;

    // Recreate the active list so returning from a mutation fetches fresh data.
    setState(() {
      _revision++;
      if (transfer != null) _selectedIndex = 3;
    });

    if (transfer != null) {
      await AppRoutes.completedTransfer(context, widget.dependencies, transfer);
    }
  }

  void _viewStock(Warehouse warehouse) => setState(() {
    _selectedWarehouse = warehouse;
    _selectedIndex = 2;
    _revision++;
  });

  Widget _screen() => switch (_selectedIndex) {
    0 => ItemsScreen(repository: widget.dependencies.items),
    1 => WarehousesScreen(
      repository: widget.dependencies.warehouses,
      onViewStock: _viewStock,
    ),
    2 => StocksScreen(
      dependencies: widget.dependencies,
      initialWarehouse: _selectedWarehouse,
      onWarehouseSelected: (warehouse) => _selectedWarehouse = warehouse,
      onManageWarehouses: () => setState(() => _selectedIndex = 1),
      onNewTransfer: _newTransfer,
    ),
    _ => TransfersScreen(
      dependencies: widget.dependencies,
      onNewTransfer: () => _newTransfer(),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: wide ? 28 : 20,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warehouse_outlined,
                color: Colors.white,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sumber Djaja',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                ),
                Text(
                  'Manajemen persediaan',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: Row(
        children: [
          if (wide) ...[
            NavigationRail(
              extended: true,
              minExtendedWidth: 220,
              backgroundColor: Colors.white,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              leading: const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Text(
                  'RUANG KERJA',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
              ),
              destinations: [
                for (var index = 0; index < _labels.length; index++)
                  NavigationRailDestination(
                    icon: Icon(_icons[index]),
                    label: Text(_labels[index]),
                  ),
              ],
              trailingAtBottom: true,
              trailing: const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Operasional gudang · v1.0',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
          ],
          Expanded(
            child: KeyedSubtree(
              key: ValueKey('$_selectedIndex-$_revision'),
              child: _screen(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              destinations: [
                for (var index = 0; index < _labels.length; index++)
                  NavigationDestination(
                    icon: Icon(_icons[index]),
                    label: _labels[index],
                  ),
              ],
            ),
    );
  }
}
