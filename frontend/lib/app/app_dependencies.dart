import '../core/network/api_client.dart';
import '../features/items/data/items_repository.dart';
import '../features/stocks/data/stocks_repository.dart';
import '../features/transfers/data/transfers_repository.dart';
import '../features/warehouses/data/warehouses_repository.dart';

class AppDependencies {
  AppDependencies({ApiClient? client}) : api = client ?? ApiClient() {
    items = ItemsRepository(api);
    warehouses = WarehousesRepository(api);
    stocks = StocksRepository(api);
    transfers = TransfersRepository(api);
  }

  final ApiClient api;
  late final ItemsRepository items;
  late final WarehousesRepository warehouses;
  late final StocksRepository stocks;
  late final TransfersRepository transfers;

  void dispose() => api.close();
}
