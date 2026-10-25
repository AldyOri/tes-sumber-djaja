import 'package:flutter/material.dart';

import '../features/transfers/data/stock_transfer.dart';
import '../features/transfers/presentation/transfer_detail_screen.dart';
import '../features/transfers/presentation/transfer_form_screen.dart';
import '../features/warehouses/data/warehouse.dart';
import 'app_dependencies.dart';

abstract final class AppRoutes {
  static Future<StockTransfer?> newTransfer(
    BuildContext context,
    AppDependencies dependencies, {
    Warehouse? source,
  }) => Navigator.push<StockTransfer>(
    context,
    MaterialPageRoute(
      builder: (_) =>
          TransferFormScreen(dependencies: dependencies, initialSource: source),
    ),
  );

  static Future<void> completedTransfer(
    BuildContext context,
    AppDependencies dependencies,
    StockTransfer transfer,
  ) => Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => TransferDetailScreen(
        repository: dependencies.transfers,
        transferId: transfer.id,
        initialTransfer: transfer,
        justCreated: true,
      ),
    ),
  );
}
