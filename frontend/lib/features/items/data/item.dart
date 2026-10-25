class Item {
  const Item({
    required this.id,
    required this.sku,
    required this.name,
    required this.unit,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    id: json['id'] as int,
    sku: json['sku'] as String,
    name: json['name'] as String,
    unit: json['unit'] as String,
  );

  final int id;
  final String sku;
  final String name;
  final String unit;
}
