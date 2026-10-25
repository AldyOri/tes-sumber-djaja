import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/page_layout.dart';
import '../../../shared/widgets/paged_results.dart';
import '../../../shared/widgets/record_picker.dart';
import '../../../shared/widgets/selector_field.dart';
import '../../warehouses/data/warehouse.dart';
import '../controllers/transfer_history_controller.dart';
import '../data/stock_transfer.dart';
import 'transfer_detail_screen.dart';

class TransfersScreen extends StatefulWidget {
  const TransfersScreen({
    super.key,
    required this.dependencies,
    this.onNewTransfer,
    this.onHistoryLoaded,
  });

  final AppDependencies dependencies;
  final VoidCallback? onNewTransfer;
  final VoidCallback? onHistoryLoaded;

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  late final _controller = TransferHistoryController(
    widget.dependencies.transfers,
  );

  @override
  void initState() {
    super.initState();
    _controller.rows.addListener(_onChanged);
    _controller.rows.load();
  }

  void _onChanged() {
    if (!_controller.rows.isLoading &&
        _controller.rows.error == null &&
        _controller.rows.result != null) {
      widget.onHistoryLoaded?.call();
    }
  }

  Future<void> _selectFilter({required bool source}) async {
    final selected = await showRecordPicker<Warehouse>(
      context: context,
      title: source ? 'Filter gudang asal' : 'Filter gudang tujuan',
      loader: (search, page) =>
          widget.dependencies.warehouses.list(search: search, page: page),
      label: (warehouse) => warehouse.name,
      subtitle: (warehouse) => warehouse.code,
    );

    if (selected == null || !mounted) return;

    source
        ? _controller.setSource(selected)
        : _controller.setDestination(selected);
  }

  void _openDetail(StockTransfer transfer) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => TransferDetailScreen(
          repository: widget.dependencies.transfers,
          transferId: transfer.id,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.rows.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller.rows,
    builder: (context, _) => PageLayout(
      children: [
        FeatureHeader(
          title: 'Riwayat mutasi',
          description:
              'Telusuri perpindahan barang antar gudang, terbaru lebih dahulu.',
          action: widget.onNewTransfer == null
              ? null
              : FilledButton.icon(
                  onPressed: widget.onNewTransfer,
                  icon: const Icon(Icons.add),
                  label: const Text('Mutasi baru'),
                ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filter gudang',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Muat ulang riwayat',
                    onPressed: _controller.rows.isLoading
                        ? null
                        : () => _controller.rows.load(),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final source = SelectorField(
                    label: 'Gudang asal',
                    value: _controller.sourceWarehouse?.name,
                    onTap: () => _selectFilter(source: true),
                    onClear: () => _controller.setSource(null),
                  );
                  final destination = SelectorField(
                    label: 'Gudang tujuan',
                    value: _controller.destinationWarehouse?.name,
                    onTap: () => _selectFilter(source: false),
                    onClear: () => _controller.setDestination(null),
                  );

                  return constraints.maxWidth > 650
                      ? Row(
                          children: [
                            Expanded(child: source),
                            const SizedBox(width: 16),
                            Expanded(child: destination),
                          ],
                        )
                      : Column(
                          children: [
                            source,
                            const SizedBox(height: 16),
                            destination,
                          ],
                        );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PagedResults<StockTransfer>(
          controller: _controller.rows,
          emptyTitle: 'Belum ada mutasi',
          emptyMessage:
              'Mutasi yang berhasil akan muncul di sini. Periksa juga filter gudang Anda.',
          itemBuilder: (transfer) => Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openDetail(transfer),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const IconBadge(Icons.swap_horiz),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            transfer.reference,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const StatusPill('Selesai'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        Text(
                          transfer.sourceWarehouse.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Icon(
                          Icons.arrow_forward,
                          size: 17,
                          color: AppColors.muted,
                        ),
                        Text(
                          transfer.destinationWarehouse.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatJakartaTime(transfer.createdAt),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.muted,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
