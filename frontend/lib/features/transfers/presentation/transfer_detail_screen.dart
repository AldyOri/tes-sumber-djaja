import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback_states.dart';
import '../../../shared/widgets/page_layout.dart';
import '../data/stock_transfer.dart';
import '../data/transfers_repository.dart';

class TransferDetailScreen extends StatefulWidget {
  const TransferDetailScreen({
    super.key,
    required this.repository,
    required this.transferId,
    this.initialTransfer,
    this.justCreated = false,
  });

  final TransfersRepository repository;
  final int transferId;
  final StockTransfer? initialTransfer;
  final bool justCreated;

  @override
  State<TransferDetailScreen> createState() => _TransferDetailScreenState();
}

class _TransferDetailScreenState extends State<TransferDetailScreen> {
  StockTransfer? _transfer;
  ApiException? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _transfer = widget.initialTransfer;

    if (_transfer == null) _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.repository.detail(widget.transferId);
      if (mounted) setState(() => _transfer = result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Detail mutasi'),
      actions: [
        IconButton(
          tooltip: 'Muat ulang detail',
          onPressed: _isLoading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: RequestError(message: _error!.message, onRetry: _load),
          )
        : _transfer == null
        ? const SizedBox.shrink()
        : _buildDetail(_transfer!),
  );

  Widget _buildDetail(StockTransfer transfer) => PageLayout(
    maxWidth: 850,
    children: [
      if (widget.justCreated) ...[
        const Notice(
          message:
              'Mutasi berhasil disimpan. Stok gudang asal dan tujuan telah diperbarui.',
        ),
        const SizedBox(height: 24),
      ],
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                IconBadge(Icons.task_alt),
                SizedBox(width: 14),
                StatusPill('Mutasi selesai'),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'REFERENSI MUTASI',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              transfer.reference,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              formatJakartaTime(transfer.createdAt),
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            _warehouse(
              'GUDANG ASAL',
              transfer.sourceWarehouse.name,
              transfer.sourceWarehouse.code,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Icon(Icons.arrow_downward, color: AppColors.primary),
            ),
            _warehouse(
              'GUDANG TUJUAN',
              transfer.destinationWarehouse.name,
              transfer.destinationWarehouse.code,
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      Text(
        'Barang dipindahkan (${transfer.items.length})',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 16),
      for (final item in transfer.items) ...[
        Panel(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.sku,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${formatQuantity(item.quantity)} ${item.unit}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 18),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Catatan',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              transfer.notes ?? 'Tidak ada catatan.',
              style: const TextStyle(color: AppColors.muted, height: 1.6),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Mutasi yang selesai tidak dapat diubah atau dihapus.',
        style: TextStyle(color: AppColors.muted, fontSize: 12),
      ),
    ],
  );

  Widget _warehouse(String label, String name, String code) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 11,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        name,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 4),
      Text(code, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
    ],
  );
}
