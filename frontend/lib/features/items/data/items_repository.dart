import '../../../core/network/api_client.dart';
import '../../../core/network/page_result.dart';
import 'item.dart';

class ItemsRepository {
  const ItemsRepository(this.api);

  final ApiClient api;

  Future<PageResult<Item>> list({String search = '', int page = 1}) async {
    final response = await api.get(
      '/items',
      query: {'search': search, 'page': '$page', 'limit': '20'},
    );

    return PageResult.fromJson(response, Item.fromJson);
  }

  Future<Item> save({
    int? id,
    required String sku,
    required String name,
    required String unit,
  }) async {
    final body = {
      'sku': sku.trim().toUpperCase(),
      'name': name.trim(),
      'unit': unit.trim(),
    };
    final response = id == null
        ? await api.post('/items', body)
        : await api.put('/items/$id', body);

    return Item.fromJson(response['data'] as Map<String, dynamic>);
  }
}
