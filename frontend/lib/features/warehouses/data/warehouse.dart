class Warehouse {
  const Warehouse({
    required this.id,
    required this.code,
    required this.name,
    this.address,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) => Warehouse(
    id: json['id'] as int,
    code: json['code'] as String,
    name: json['name'] as String,
    address: json['address'] as String?,
  );

  final int id;
  final String code;
  final String name;
  final String? address;
}
