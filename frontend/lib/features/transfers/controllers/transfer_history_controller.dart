import '../../../shared/controllers/paged_controller.dart';
import '../../warehouses/data/warehouse.dart';
import '../data/stock_transfer.dart';
import '../data/transfers_repository.dart';

class TransferHistoryController {
  TransferHistoryController(TransfersRepository repository) {
    rows = PagedController<StockTransfer>(
      (_, page) => repository.list(
        page: page,
        sourceWarehouseId: sourceWarehouse?.id,
        destinationWarehouseId: destinationWarehouse?.id,
      ),
    );
  }

  late final PagedController<StockTransfer> rows;
  Warehouse? sourceWarehouse;
  Warehouse? destinationWarehouse;

  void setSource(Warehouse? warehouse) {
    sourceWarehouse = warehouse;
    rows.load(page: 1);
  }

  void setDestination(Warehouse? warehouse) {
    destinationWarehouse = warehouse;
    rows.load(page: 1);
  }

  void dispose() => rows.dispose();
}
