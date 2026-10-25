import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../stocks/data/stock_item.dart';
import '../../stocks/data/stocks_repository.dart';
import '../../warehouses/data/warehouse.dart';
import '../data/stock_transfer.dart';
import '../data/transfers_repository.dart';

class TransferLine {
  TransferLine(this.item);

  StockItem item;
  String quantity = '';
}

class TransferFormController extends ChangeNotifier {
  TransferFormController({required this.transfers, required this.stocks});

  final TransfersRepository transfers;
  final StocksRepository stocks;

  Warehouse? sourceWarehouse;
  Warehouse? destinationWarehouse;
  final List<TransferLine> lines = [];
  List<StockItem> availability = [];
  Map<String, String> fieldErrors = {};
  String notes = '';

  ApiException? error;
  ApiException? availabilityError;
  bool isLoadingAvailability = false;
  bool isSubmitting = false;
  bool outcomeUncertain = false;

  bool _disposed = false;
  int _availabilityRequest = 0;

  void _clearError() {
    error = null;
    fieldErrors = {};
  }

  Future<void> selectSource(Warehouse warehouse) async {
    if (warehouse.id == sourceWarehouse?.id) return;

    sourceWarehouse = warehouse;

    // Existing quantities refer to another warehouse and must not carry over.
    lines.clear();
    availability = [];
    _clearError();

    await refreshAvailability();
  }

  void selectDestination(Warehouse warehouse) {
    destinationWarehouse = warehouse;
    _clearError();
    notifyListeners();
  }

  Future<void> refreshAvailability() async {
    final warehouseId = sourceWarehouse?.id;
    if (warehouseId == null || _disposed) return;

    final requestId = ++_availabilityRequest;
    isLoadingAvailability = true;
    availabilityError = null;
    notifyListeners();

    try {
      final result = await stocks.all(warehouseId);
      if (_disposed || requestId != _availabilityRequest) return;

      availability = result;
      final byId = {for (final item in result) item.itemId: item};

      for (final line in lines) {
        final refreshed = byId[line.item.itemId];
        if (refreshed != null) line.item = refreshed;
      }
    } on ApiException catch (failure) {
      if (!_disposed && requestId == _availabilityRequest) {
        availabilityError = failure;
      }
    } finally {
      if (!_disposed && requestId == _availabilityRequest) {
        isLoadingAvailability = false;
        notifyListeners();
      }
    }
  }

  void addItem(StockItem item) {
    if (lines.length >= 50 ||
        lines.any((line) => line.item.itemId == item.itemId)) {
      return;
    }

    lines.add(TransferLine(item));
    _clearError();
    notifyListeners();
  }

  void removeItem(int itemId) {
    lines.removeWhere((line) => line.item.itemId == itemId);
    _clearError();
    notifyListeners();
  }

  void updateQuantity(TransferLine line, String value) {
    line.quantity = value;
    if (fieldErrors.isEmpty && error == null) return;

    _clearError();
    notifyListeners();
  }

  void allowManualRetryAfterReview() {
    outcomeUncertain = false;
    _clearError();
    notifyListeners();
  }

  bool validate() {
    final errors = <String, String>{};

    if (sourceWarehouse == null) {
      errors['sourceWarehouseId'] = 'Pilih gudang asal.';
    }
    if (destinationWarehouse == null) {
      errors['destinationWarehouseId'] = 'Pilih gudang tujuan.';
    }
    if (sourceWarehouse != null &&
        sourceWarehouse!.id == destinationWarehouse?.id) {
      errors['destinationWarehouseId'] =
          'Gudang tujuan harus berbeda dari gudang asal.';
    }
    if (lines.isEmpty) errors['items'] = 'Tambahkan minimal satu barang.';
    if (notes.trim().length > 500) {
      errors['notes'] = 'Catatan maksimal 500 karakter.';
    }

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final message = Validators.quantity(line.quantity, line.item.quantity);

      if (message != null) errors['items.$index.quantity'] = message;
    }

    fieldErrors = errors;
    notifyListeners();

    return errors.isEmpty;
  }

  Future<StockTransfer?> submit() async {
    if (isSubmitting ||
        outcomeUncertain ||
        isLoadingAvailability ||
        availabilityError != null) {
      return null;
    }
    if (!validate()) return null;

    isSubmitting = true;
    error = null;
    notifyListeners();

    try {
      return await transfers.create({
        'sourceWarehouseId': sourceWarehouse!.id,
        'destinationWarehouseId': destinationWarehouse!.id,
        'notes': notes.trim().isEmpty ? null : notes.trim(),
        'items': [
          for (final line in lines)
            {
              'itemId': line.item.itemId,
              'quantity': int.parse(line.quantity.trim()),
            },
        ],
      });
    } on ApiException catch (failure) {
      error = failure;
      fieldErrors = failure.fields;
      outcomeUncertain = failure.outcomeUncertain;

      if (failure.code == 'INSUFFICIENT_STOCK') await refreshAvailability();

      return null;
    } finally {
      if (!_disposed) {
        isSubmitting = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
