import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/controllers/paged_controller.dart';
import '../../../shared/widgets/page_layout.dart';
import '../../../shared/widgets/paged_results.dart';
import '../../../shared/widgets/search_box.dart';
import '../data/warehouse.dart';
import '../data/warehouses_repository.dart';
import 'warehouse_form_screen.dart';

class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({
    super.key,
    required this.repository,
    required this.onViewStock,
  });

  final WarehousesRepository repository;
  final ValueChanged<Warehouse> onViewStock;

  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen> {
  late final _controller = PagedController<Warehouse>(
    (search, page) => widget.repository.list(search: search, page: page),
  )..load();

  Future<void> _openForm([Warehouse? warehouse]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WarehouseFormScreen(
          repository: widget.repository,
          warehouse: warehouse,
        ),
      ),
    );

    if (saved != true || !mounted) return;

    _controller.load();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data gudang berhasil disimpan.')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) => PageLayout(
      children: [
        FeatureHeader(
          title: 'Master gudang',
          description: 'Atur lokasi penyimpanan dan akses stok setiap gudang.',
          action: FilledButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: const Text('Tambah gudang'),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: SearchBox(
                hint: 'Cari kode atau nama gudang…',
                onChanged: (value) => _controller.load(search: value),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Muat ulang gudang',
              onPressed: _controller.isLoading
                  ? null
                  : () => _controller.load(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 24),
        PagedResults<Warehouse>(
          controller: _controller,
          emptyTitle: 'Belum ada gudang',
          emptyMessage:
              'Tambahkan gudang pertama atau ubah kata kunci pencarian.',
          itemBuilder: (warehouse) => Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const IconBadge(Icons.warehouse_outlined),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            warehouse.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            warehouse.code,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit ${warehouse.name}',
                      onPressed: () => _openForm(warehouse),
                      icon: const Icon(Icons.edit_outlined, size: 21),
                    ),
                  ],
                ),
                if (warehouse.address != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    warehouse.address!,
                    style: const TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => widget.onViewStock(warehouse),
                  icon: const Icon(Icons.layers_outlined, size: 18),
                  label: const Text('Lihat stok gudang'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
