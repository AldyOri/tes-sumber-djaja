import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/feedback_states.dart';
import '../../../../shared/widgets/page_layout.dart';
import '../../../../shared/widgets/selector_field.dart';
import '../../controllers/transfer_form_controller.dart';
import 'transfer_line_card.dart';

class TransferFormFields extends StatelessWidget {
  const TransferFormFields({
    super.key,
    required this.controller,
    required this.onSourceSelected,
    required this.onDestinationSelected,
    required this.onAddItem,
  });

  final TransferFormController controller;
  final VoidCallback onSourceSelected;
  final VoidCallback onDestinationSelected;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _warehouseRoute(),
      const SizedBox(height: 28),
      _itemLines(),
      const SizedBox(height: 28),
      _notes(),
    ],
  );

  Widget _warehouseRoute() => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. Rute mutasi',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        SelectorField(
          label: 'Gudang asal *',
          value: controller.sourceWarehouse?.name,
          error: controller.fieldErrors['sourceWarehouseId'],
          onTap: onSourceSelected,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Icon(
              Icons.arrow_downward,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ),
        SelectorField(
          label: 'Gudang tujuan *',
          value: controller.destinationWarehouse?.name,
          error: controller.fieldErrors['destinationWarehouseId'],
          onTap: onDestinationSelected,
        ),
        const SizedBox(height: 16),
        const Text(
          'Mengganti gudang asal akan menghapus daftar barang.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _itemLines() {
    final canAddItem =
        controller.sourceWarehouse != null &&
        !controller.isLoadingAvailability &&
        controller.availabilityError == null &&
        controller.lines.length < 50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '2. Barang mutasi',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${controller.lines.length}/50',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (controller.isLoadingAvailability)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (controller.availabilityError != null)
          RequestError(
            message: controller.availabilityError!.message,
            onRetry: controller.refreshAvailability,
          ),
        if (controller.lines.isEmpty && !controller.isLoadingAvailability)
          const Panel(
            child: EmptyState(
              title: 'Pilih barang yang akan dipindahkan',
              message:
                  'Pilih gudang asal untuk melihat barang dan stok yang tersedia.',
              icon: Icons.playlist_add,
            ),
          ),
        for (var index = 0; index < controller.lines.length; index++) ...[
          TransferLineCard(
            key: ValueKey(controller.lines[index].item.itemId),
            line: controller.lines[index],
            error:
                controller.fieldErrors['items.$index.quantity'] ??
                controller.fieldErrors['items.$index.itemId'],
            onRemove: () =>
                controller.removeItem(controller.lines[index].item.itemId),
            onQuantityChanged: (value) =>
                controller.updateQuantity(controller.lines[index], value),
          ),
          const SizedBox(height: 12),
        ],
        if (controller.fieldErrors['items'] != null) ...[
          Notice(message: controller.fieldErrors['items']!, isError: true),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: canAddItem ? onAddItem : null,
          icon: const Icon(Icons.add),
          label: const Text('Tambah barang'),
        ),
        const SizedBox(height: 12),
        if (controller.sourceWarehouse != null &&
            !controller.isLoadingAvailability)
          const Text(
            'Jumlah tersedia adalah data terakhir yang dimuat. Stok diperiksa kembali saat disimpan.',
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
          ),
      ],
    );
  }

  Widget _notes() => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3. Catatan',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextField(
          maxLength: 500,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Tujuan pemindahan atau informasi tambahan (opsional)',
            errorText: controller.fieldErrors['notes'],
          ),
          onChanged: (value) => controller.notes = value,
        ),
      ],
    ),
  );
}
