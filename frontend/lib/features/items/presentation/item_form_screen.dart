import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';
import '../../../shared/controllers/save_controller.dart';
import '../../../shared/widgets/master_form_layout.dart';
import '../data/item.dart';
import '../data/items_repository.dart';

class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key, required this.repository, this.item});

  final ItemsRepository repository;
  final Item? item;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = SaveController();

  late final _sku = TextEditingController(text: widget.item?.sku);
  late final _name = TextEditingController(text: widget.item?.name);
  late final _unit = TextEditingController(text: widget.item?.unit);

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final saved = await _controller.save(() async {
      await widget.repository.save(
        id: widget.item?.id,
        sku: _sku.text,
        name: _name.text,
        unit: _unit.text,
      );
    });

    if (saved && mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _sku.dispose();
    _name.dispose();
    _unit.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) => MasterFormLayout(
      title: widget.item == null ? 'Tambah barang' : 'Edit barang',
      description: widget.item == null
          ? 'Daftarkan barang baru. Stok awal di semua gudang adalah nol.'
          : 'Perbarui informasi barang tanpa mengubah saldo stok.',
      formKey: _formKey,
      isSaving: _controller.isSaving,
      errorMessage: _controller.error?.message,
      onSave: _save,
      fields: [
        TextFormField(
          controller: _sku,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          maxLength: 50,
          decoration: InputDecoration(
            labelText: 'SKU *',
            hintText: 'BRG-004',
            errorText: _controller.error?.fields['sku'],
          ),
          onChanged: (_) => _controller.clearError(),
          validator: (value) => Validators.requiredText(value, 'SKU', 50),
        ),
        TextFormField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          maxLength: 150,
          decoration: InputDecoration(
            labelText: 'Nama barang *',
            hintText: 'Nama barang',
            errorText: _controller.error?.fields['name'],
          ),
          onChanged: (_) => _controller.clearError(),
          validator: (value) =>
              Validators.requiredText(value, 'Nama barang', 150),
        ),
        TextFormField(
          controller: _unit,
          textInputAction: TextInputAction.done,
          maxLength: 20,
          decoration: InputDecoration(
            labelText: 'Satuan *',
            hintText: 'pcs, kg, atau dus',
            helperText:
                'Satuan tidak dapat diubah setelah ada stok atau riwayat.',
            helperMaxLines: 3,
            errorMaxLines: 3,
            errorText: _controller.error?.fields['unit'],
          ),
          onChanged: (_) => _controller.clearError(),
          validator: (value) => Validators.requiredText(value, 'Satuan', 20),
        ),
      ],
    ),
  );
}
