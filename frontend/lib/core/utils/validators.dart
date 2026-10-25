abstract final class Validators {
  static const maxQuantity = 2147483647;

  static String? requiredText(String? value, String label, int maxLength) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) return '$label wajib diisi.';
    if (trimmed.length > maxLength) {
      return '$label maksimal $maxLength karakter.';
    }

    return null;
  }

  static String? quantity(String? value, int available) {
    final text = value?.trim() ?? '';
    final parsed = int.tryParse(text);

    if (!RegExp(r'^\d+$').hasMatch(text) || parsed == null || parsed <= 0) {
      return 'Masukkan bilangan bulat lebih dari nol.';
    }

    if (parsed > maxQuantity) return 'Jumlah melebihi batas maksimum.';
    if (parsed > available) return 'Stok tersedia hanya $available.';

    return null;
  }
}
