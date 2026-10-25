import 'package:flutter/material.dart';

import '../../app/theme.dart';

class SelectorField extends StatelessWidget {
  const SelectorField({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.error,
    this.icon = Icons.warehouse_outlined,
    this.onClear,
  });

  final String label;
  final String? value;
  final String? error;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          errorMaxLines: 3,
          prefixIcon: Icon(icon),
          suffixIcon: onClear != null && value != null
              ? IconButton(
                  tooltip: 'Hapus pilihan',
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                )
              : const Icon(Icons.expand_more),
        ),
        child: Text(
          value ?? 'Pilih gudang',
          style: TextStyle(
            color: value == null ? AppColors.muted : AppColors.ink,
          ),
        ),
      ),
    ),
  );
}
