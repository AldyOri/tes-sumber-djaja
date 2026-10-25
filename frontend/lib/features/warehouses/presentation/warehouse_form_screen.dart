import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';
import '../../../shared/controllers/save_controller.dart';
import '../../../shared/widgets/master_form_layout.dart';
import '../data/warehouse.dart';
import '../data/warehouses_repository.dart';

class WarehouseFormScreen extends StatefulWidget {
  const WarehouseFormScreen({
    super.key,
    required this.repository,
    this.warehouse,
  });

  final WarehousesRepository repository;
  final Warehouse? warehouse;

  @override
  State<WarehouseFormScreen> createState() => _WarehouseFormScreenState();
}

class _WarehouseFormScreenState extends State<WarehouseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = SaveController();

  late final _code = TextEditingController(text: widget.warehouse?.code);
  late final _name = TextEditingController(text: widget.warehouse?.name);
  late final _address = TextEditingController(text: widget.warehouse?.address);

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final saved = await _controller.save(() async {
      await widget.repository.save(
        id: widget.warehouse?.id,
        code: _code.text,
        name: _name.text,
        address: _address.text,
      );
    });

    if (saved && mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _address.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) => MasterFormLayout(
      title: widget.warehouse == null ? 'Tambah gudang' : 'Edit gudang',
      description: widget.warehouse == null
          ? 'Tambahkan lokasi penyimpanan. Gudang baru dimulai dengan stok nol.'
          : 'Perbarui informasi lokasi tanpa mengubah saldo stok.',
      formKey: _formKey,
      isSaving: _controller.isSaving,
      errorMessage: _controller.error?.message,
      onSave: _save,
      fields: [
        TextFormField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          maxLength: 50,
          decoration: InputDecoration(
            labelText: 'Kode gudang *',
            hintText: 'GDG-C',
            errorText: _controller.error?.fields['code'],
          ),
          onChanged: (_) => _controller.clearError(),
          validator: (value) =>
              Validators.requiredText(value, 'Kode gudang', 50),
        ),
        TextFormField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          maxLength: 150,
          decoration: InputDecoration(
            labelText: 'Nama gudang *',
            hintText: 'Gudang C',
            errorText: _controller.error?.fields['name'],
          ),
          onChanged: (_) => _controller.clearError(),
          validator: (value) =>
              Validators.requiredText(value, 'Nama gudang', 150),
        ),
        TextFormField(
          controller: _address,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 255,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Alamat (opsional)',
            alignLabelWithHint: true,
            hintText: 'Alamat lengkap gudang',
            errorText: _controller.error?.fields['address'],
          ),
          onChanged: (_) => _controller.clearError(),
          validator: (value) => (value?.trim().length ?? 0) > 255
              ? 'Alamat maksimal 255 karakter.'
              : null,
        ),
      ],
    ),
  );
}
