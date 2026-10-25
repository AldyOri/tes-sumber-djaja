import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback_states.dart';
import '../../../shared/widgets/page_layout.dart';
import '../../../shared/widgets/paged_results.dart';
import '../../../shared/widgets/record_picker.dart';
import '../../../shared/widgets/search_box.dart';
import '../../../shared/widgets/selector_field.dart';
import '../../warehouses/data/warehouse.dart';
import '../controllers/stocks_controller.dart';
import '../data/stock_item.dart';

class StocksScreen extends StatefulWidget {
  const StocksScreen({
    super.key,
    required this.dependencies,
    required this.onNewTransfer,
    required this.onWarehouseSelected,
    required this.onManageWarehouses,
    this.initialWarehouse,
  });

  final AppDependencies dependencies;
  final ValueChanged<Warehouse?> onNewTransfer;
  final ValueChanged<Warehouse> onWarehouseSelected;
  final VoidCallback onManageWarehouses;
  final Warehouse? initialWarehouse;

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  late final _controller = StocksController(
    stocks: widget.dependencies.stocks,
    warehouses: widget.dependencies.warehouses,
    initialWarehouse: widget.initialWarehouse,
  )..initialize();

  Future<void> _selectWarehouse() async {
    final selected = await showRecordPicker<Warehouse>(
      context: context,
      title: 'Pilih gudang',
      loader: (search, page) =>
          widget.dependencies.warehouses.list(search: search, page: page),
      label: (warehouse) => warehouse.name,
      subtitle: (warehouse) => warehouse.code,
    );

    if (selected == null || !mounted) return;

    _controller.selectWarehouse(selected);
    widget.onWarehouseSelected(selected);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      final warehouse = _controller.warehouse;

      return PageLayout(
        children: [
          FeatureHeader(
            title: 'Stok gudang',
            description:
                'Pantau ketersediaan barang di setiap lokasi penyimpanan.',
            action: FilledButton.icon(
              onPressed: () => widget.onNewTransfer(warehouse),
              icon: const Icon(Icons.add),
              label: const Text('Mutasi baru'),
            ),
          ),
          if (_controller.isInitializing)
            const Padding(
              padding: EdgeInsets.all(60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_controller.error != null)
            RequestError(
              message: _controller.error!.message,
              onRetry: _controller.initialize,
            )
          else if (warehouse == null)
            EmptyState(
              title: 'Tambahkan gudang terlebih dahulu',
              message: 'Stok barang akan ditampilkan setelah gudang tersedia.',
              icon: Icons.warehouse_outlined,
              action: FilledButton(
                onPressed: widget.onManageWarehouses,
                child: const Text('Kelola gudang'),
              ),
            )
          else ...[
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LOKASI PENYIMPANAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SelectorField(
                    label: 'Gudang',
                    value: '${warehouse.name} · ${warehouse.code}',
                    onTap: _selectWarehouse,
                  ),
                  if (warehouse.address != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      warehouse.address!,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SearchBox(
                    hint: 'Cari SKU atau nama barang…',
                    onChanged: (value) => _controller.rows.load(search: value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Muat ulang stok',
                  onPressed: _controller.rows.isLoading
                      ? null
                      : () => _controller.rows.load(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ketersediaan barang',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                if (!_controller.rows.isLoading &&
                    _controller.rows.error == null)
                  Text(
                    '${_controller.rows.result?.total ?? 0} barang',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            PagedResults<StockItem>(
              controller: _controller.rows,
              emptyTitle: 'Tidak ada barang',
              emptyMessage:
                  'Tambahkan data barang atau ubah kata kunci pencarian.',
              itemBuilder: (item) => Panel(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const IconBadge(Icons.inventory_2_outlined),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item.sku,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          if (item.quantity == 0) ...[
                            const SizedBox(height: 8),
                            const StatusPill('Stok kosong', warning: true),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatQuantity(item.quantity),
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            item.unit,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Barang tanpa saldo tetap ditampilkan dengan stok nol.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ],
      );
    },
  );
}
