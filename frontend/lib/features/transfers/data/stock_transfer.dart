import '../../stocks/data/stock_item.dart';
import '../../warehouses/data/warehouse.dart';

class StockTransfer {
  const StockTransfer({
    required this.id,
    required this.reference,
    required this.createdAt,
    required this.sourceWarehouse,
    required this.destinationWarehouse,
    this.notes,
    this.items = const [],
  });

  factory StockTransfer.fromJson(Map<String, dynamic> json) => StockTransfer(
    id: json['id'] as int,
    reference: json['reference'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    sourceWarehouse: Warehouse.fromJson(
      json['sourceWarehouse'] as Map<String, dynamic>,
    ),
    destinationWarehouse: Warehouse.fromJson(
      json['destinationWarehouse'] as Map<String, dynamic>,
    ),
    notes: json['notes'] as String?,
    items: (json['items'] as List? ?? [])
        .map((item) => StockItem.fromJson(item as Map<String, dynamic>))
        .toList(),
  );

  final int id;
  final String reference;
  final DateTime createdAt;
  final Warehouse sourceWarehouse;
  final Warehouse destinationWarehouse;
  final String? notes;
  final List<StockItem> items;
}
