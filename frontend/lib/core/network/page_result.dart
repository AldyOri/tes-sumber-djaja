class PageResult<T> {
  const PageResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final meta = json['meta'] as Map<String, dynamic>;

    return PageResult(
      items: (json['data'] as List)
          .map((value) => parse(value as Map<String, dynamic>))
          .toList(),
      page: meta['page'] as int,
      limit: meta['limit'] as int,
      total: meta['total'] as int,
    );
  }

  final List<T> items;
  final int page;
  final int limit;
  final int total;

  bool get hasNext => page * limit < total;
  int get pages => total == 0 ? 1 : (total / limit).ceil();
}
