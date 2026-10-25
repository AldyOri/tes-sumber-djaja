String formatQuantity(int quantity) {
  return quantity.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );
}

String formatJakartaTime(DateTime timestamp) {
  // Asia/Jakarta remains UTC+7 and does not observe daylight saving time.
  final date = timestamp.toUtc().add(const Duration(hours: 7));
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute WIB';
}
