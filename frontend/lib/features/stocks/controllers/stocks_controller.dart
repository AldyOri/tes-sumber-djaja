import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/controllers/paged_controller.dart';
import '../../warehouses/data/warehouse.dart';
import '../../warehouses/data/warehouses_repository.dart';
import '../data/stock_item.dart';
import '../data/stocks_repository.dart';

class StocksController extends ChangeNotifier {
  StocksController({
    required StocksRepository stocks,
    required this.warehouses,
    Warehouse? initialWarehouse,
  }) : warehouse = initialWarehouse {
    rows = PagedController<StockItem>(
      (search, page) =>
          stocks.list(warehouseId: warehouse!.id, search: search, page: page),
    );
    rows.addListener(notifyListeners);
  }

  final WarehousesRepository warehouses;
  late final PagedController<StockItem> rows;

  Warehouse? warehouse;
  ApiException? error;
  bool isInitializing = true;
  bool _disposed = false;

  Future<void> initialize() async {
    isInitializing = true;
    error = null;
    notifyListeners();

    try {
      if (warehouse == null) {
        final result = await warehouses.list();
        if (_disposed) return;

        warehouse = result.items.firstOrNull;
      }

      if (warehouse != null) await rows.load();
    } on ApiException catch (failure) {
      if (!_disposed) error = failure;
    } finally {
      if (!_disposed) {
        isInitializing = false;
        notifyListeners();
      }
    }
  }

  void selectWarehouse(Warehouse selected) {
    warehouse = selected;
    rows.load(page: 1);
  }

  @override
  void dispose() {
    _disposed = true;
    rows.removeListener(notifyListeners);
    rows.dispose();
    super.dispose();
  }
}
