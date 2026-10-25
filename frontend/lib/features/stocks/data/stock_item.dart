class StockItem {
  const StockItem({
    required this.itemId,
    required this.sku,
    required this.name,
    required this.unit,
    required this.quantity,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
    itemId: json['itemId'] as int,
    sku: json['sku'] as String,
    name: json['name'] as String,
    unit: json['unit'] as String,
    quantity: json['quantity'] as int,
  );

  final int itemId;
  final String sku;
  final String name;
  final String unit;
  final int quantity;
}
