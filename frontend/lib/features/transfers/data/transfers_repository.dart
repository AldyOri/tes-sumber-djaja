import '../../../core/network/api_client.dart';
import '../../../core/network/page_result.dart';
import 'stock_transfer.dart';

class TransfersRepository {
  const TransfersRepository(this.api);

  final ApiClient api;

  Future<PageResult<StockTransfer>> list({
    int page = 1,
    int? sourceWarehouseId,
    int? destinationWarehouseId,
  }) async {
    final response = await api.get(
      '/transfers',
      query: {
        'page': '$page',
        'limit': '20',
        if (sourceWarehouseId != null)
          'sourceWarehouseId': '$sourceWarehouseId',
        if (destinationWarehouseId != null)
          'destinationWarehouseId': '$destinationWarehouseId',
      },
    );

    return PageResult.fromJson(response, StockTransfer.fromJson);
  }

  Future<StockTransfer> detail(int id) async {
    final response = await api.get('/transfers/$id');

    return StockTransfer.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<StockTransfer> create(Map<String, dynamic> input) async {
    final response = await api.post('/transfers', input);

    return StockTransfer.fromJson(response['data'] as Map<String, dynamic>);
  }
}
