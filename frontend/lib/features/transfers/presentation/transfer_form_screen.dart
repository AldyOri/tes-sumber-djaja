import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/theme.dart';
import '../../../core/network/page_result.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback_states.dart';
import '../../../shared/widgets/page_layout.dart';
import '../../../shared/widgets/record_picker.dart';
import '../../stocks/data/stock_item.dart';
import '../../warehouses/data/warehouse.dart';
import '../controllers/transfer_form_controller.dart';
import 'transfers_screen.dart';
import 'widgets/transfer_form_fields.dart';

class TransferFormScreen extends StatefulWidget {
  const TransferFormScreen({
    super.key,
    required this.dependencies,
    this.initialSource,
  });

  final AppDependencies dependencies;
  final Warehouse? initialSource;

  @override
  State<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends State<TransferFormScreen> {
  late final _controller = TransferFormController(
    transfers: widget.dependencies.transfers,
    stocks: widget.dependencies.stocks,
  );

  bool _outcomeReviewed = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialSource != null) {
      _controller.selectSource(widget.initialSource!);
    }
  }

  Future<void> _selectWarehouse({required bool source}) async {
    final selected = await showRecordPicker<Warehouse>(
      context: context,
      title: source ? 'Pilih gudang asal' : 'Pilih gudang tujuan',
      loader: (search, page) =>
          widget.dependencies.warehouses.list(search: search, page: page),
      label: (warehouse) => warehouse.name,
      subtitle: (warehouse) => warehouse.code,
      isEnabled: (warehouse) =>
          warehouse.id !=
          (source
              ? _controller.destinationWarehouse?.id
              : _controller.sourceWarehouse?.id),
    );

    if (selected == null || !mounted) return;

    if (source) {
      await _controller.selectSource(selected);
    } else {
      _controller.selectDestination(selected);
    }
  }

  Future<void> _addItem() async {
    final selected = await showRecordPicker<StockItem>(
      context: context,
      title: 'Tambah barang mutasi',
      loader: (search, page) async {
        final query = search.toLowerCase();
        final matches = _controller.availability
            .where(
              (item) =>
                  item.sku.toLowerCase().contains(query) ||
                  item.name.toLowerCase().contains(query),
            )
            .toList();

        return PageResult(
          items: matches.skip((page - 1) * 20).take(20).toList(),
          page: page,
          limit: 20,
          total: matches.length,
        );
      },
      label: (item) => '${item.sku} · ${item.name}',
      subtitle: (item) =>
          'Tersedia ${formatQuantity(item.quantity)} ${item.unit}',
      isEnabled: (item) =>
          item.quantity > 0 &&
          !_controller.lines.any((line) => line.item.itemId == item.itemId),
    );

    if (selected != null && mounted) _controller.addItem(selected);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _outcomeReviewed = false;

    final transfer = await _controller.submit();

    if (transfer != null && mounted) Navigator.pop(context, transfer);
  }

  Future<void> _reviewOutcome() async {
    var historyLoaded = false;

    // The draft remains mounted while the operator checks server history.
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Periksa hasil mutasi')),
          body: TransfersScreen(
            dependencies: widget.dependencies,
            onHistoryLoaded: () => historyLoaded = true,
          ),
        ),
      ),
    );

    if (!mounted) return;

    await _controller.refreshAvailability();

    if (mounted) {
      setState(
        () => _outcomeReviewed =
            historyLoaded && _controller.availabilityError == null,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) => PopScope(
      canPop: !_controller.isSubmitting,
      child: Scaffold(
        appBar: AppBar(title: const Text('Mutasi baru')),
        body: PageLayout(
          maxWidth: 850,
          children: [
            const FeatureHeader(
              title: 'Pindahkan stok',
              description:
                  'Tentukan rute gudang, lalu pilih barang dan jumlahnya.',
            ),
            AbsorbPointer(
              absorbing:
                  _controller.isSubmitting || _controller.outcomeUncertain,
              child: TransferFormFields(
                controller: _controller,
                onSourceSelected: () => _selectWarehouse(source: true),
                onDestinationSelected: () => _selectWarehouse(source: false),
                onAddItem: _addItem,
              ),
            ),
            const SizedBox(height: 24),
            if (_controller.error != null) ...[
              Notice(
                message: _controller.outcomeUncertain
                    ? 'Hasil pengiriman belum dapat dipastikan. Mutasi mungkin sudah tersimpan. Periksa riwayat dan stok sebelum mengirim ulang.'
                    : _controller.error!.message,
                isError: true,
              ),
              const SizedBox(height: 16),
            ],
            if (_controller.outcomeUncertain) ...[
              OutlinedButton.icon(
                onPressed: _controller.isLoadingAvailability
                    ? null
                    : _reviewOutcome,
                icon: const Icon(Icons.manage_search),
                label: const Text('Periksa riwayat dan muat ulang stok'),
              ),
              if (_outcomeReviewed)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: false,
                  title: const Text(
                    'Saya sudah memeriksa riwayat dan memastikan mutasi ini belum tercatat.',
                    style: TextStyle(fontSize: 13),
                  ),
                  onChanged: (value) {
                    if (value == true) {
                      _controller.allowManualRetryAfterReview();
                    }
                  },
                ),
              const SizedBox(height: 16),
            ],
            FilledButton.icon(
              onPressed:
                  _controller.isSubmitting ||
                      _controller.outcomeUncertain ||
                      _controller.isLoadingAvailability ||
                      _controller.availabilityError != null
                  ? null
                  : _submit,
              icon: _controller.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.swap_horiz),
              label: Text(
                _controller.isSubmitting
                    ? 'Menyimpan mutasi…'
                    : 'Simpan mutasi',
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Mutasi langsung selesai setelah disimpan dan tidak dapat dibatalkan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}
