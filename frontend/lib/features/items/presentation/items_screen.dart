import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/controllers/paged_controller.dart';
import '../../../shared/widgets/page_layout.dart';
import '../../../shared/widgets/paged_results.dart';
import '../../../shared/widgets/search_box.dart';
import '../data/item.dart';
import '../data/items_repository.dart';
import 'item_form_screen.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key, required this.repository});

  final ItemsRepository repository;

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  late final _controller = PagedController<Item>(
    (search, page) => widget.repository.list(search: search, page: page),
  )..load();

  Future<void> _openForm([Item? item]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ItemFormScreen(repository: widget.repository, item: item),
      ),
    );

    if (saved != true || !mounted) return;

    _controller.load();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data barang berhasil disimpan.')),
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
          title: 'Master barang',
          description: 'Kelola informasi barang untuk seluruh gudang Anda.',
          action: FilledButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: const Text('Tambah barang'),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: SearchBox(
                hint: 'Cari SKU atau nama barang…',
                onChanged: (value) => _controller.load(search: value),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Muat ulang barang',
              onPressed: _controller.isLoading
                  ? null
                  : () => _controller.load(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 24),
        PagedResults<Item>(
          controller: _controller,
          emptyTitle: 'Belum ada barang',
          emptyMessage:
              'Tambahkan barang pertama atau ubah kata kunci pencarian.',
          itemBuilder: (item) => Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              leading: const IconBadge(Icons.inventory_2_outlined),
              title: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${item.sku} · ${item.unit}',
                style: const TextStyle(color: AppColors.muted),
              ),
              trailing: IconButton(
                tooltip: 'Edit ${item.name}',
                onPressed: () => _openForm(item),
                icon: const Icon(Icons.edit_outlined, size: 21),
              ),
              onTap: () => _openForm(item),
            ),
          ),
        ),
      ],
    ),
  );
}
