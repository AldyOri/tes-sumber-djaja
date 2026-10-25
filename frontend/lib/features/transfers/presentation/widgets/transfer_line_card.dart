import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/page_layout.dart';
import '../../controllers/transfer_form_controller.dart';

class TransferLineCard extends StatelessWidget {
  const TransferLineCard({
    super.key,
    required this.line,
    required this.onRemove,
    required this.onQuantityChanged,
    this.error,
  });

  final TransferLine line;
  final VoidCallback onRemove;
  final ValueChanged<String> onQuantityChanged;
  final String? error;

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const IconBadge(Icons.inventory_2_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    line.item.sku,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Hapus ${line.item.name}',
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: line.quantity,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Jumlah mutasi *',
            hintText: '0',
            suffixText: line.item.unit,
            helperText:
                'Tersedia ${formatQuantity(line.item.quantity)} ${line.item.unit} di gudang asal',
            helperMaxLines: 2,
            errorMaxLines: 3,
            errorText: error,
          ),
          onChanged: onQuantityChanged,
        ),
      ],
    ),
  );
}
