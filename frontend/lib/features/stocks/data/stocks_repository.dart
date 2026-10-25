import '../../../core/network/api_client.dart';
import '../../../core/network/page_result.dart';
import 'stock_item.dart';

class StocksRepository {
  const StocksRepository(this.api);

  final ApiClient api;

  Future<PageResult<StockItem>> list({
    required int warehouseId,
    String search = '',
    int page = 1,
    int limit = 20,
  }) async {
    final response = await api.get(
      '/warehouses/$warehouseId/stocks',
      query: {'search': search, 'page': '$page', 'limit': '$limit'},
    );

    return PageResult.fromJson(response, StockItem.fromJson);
  }

  Future<List<StockItem>> all(int warehouseId) async {
    final items = <StockItem>[];
    var page = 1;

    while (true) {
      final result = await list(
        warehouseId: warehouseId,
        page: page,
        limit: 100,
      );
      items.addAll(result.items);

      if (!result.hasNext) return items;

      page++;
    }
  }
}
