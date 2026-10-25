import '../../../core/network/api_client.dart';
import '../../../core/network/page_result.dart';
import 'warehouse.dart';

class WarehousesRepository {
  const WarehousesRepository(this.api);

  final ApiClient api;

  Future<PageResult<Warehouse>> list({String search = '', int page = 1}) async {
    final response = await api.get(
      '/warehouses',
      query: {'search': search, 'page': '$page', 'limit': '20'},
    );

    return PageResult.fromJson(response, Warehouse.fromJson);
  }

  Future<Warehouse> save({
    int? id,
    required String code,
    required String name,
    required String address,
  }) async {
    final body = {
      'code': code.trim().toUpperCase(),
      'name': name.trim(),
      'address': address.trim().isEmpty ? null : address.trim(),
    };
    final response = id == null
        ? await api.post('/warehouses', body)
        : await api.put('/warehouses/$id', body);

    return Warehouse.fromJson(response['data'] as Map<String, dynamic>);
  }
}
