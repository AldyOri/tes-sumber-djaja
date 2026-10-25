import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';

class SaveController extends ChangeNotifier {
  bool isSaving = false;
  ApiException? error;

  void clearError() {
    if (error == null) return;

    error = null;
    notifyListeners();
  }

  Future<bool> save(Future<void> Function() action) async {
    if (isSaving) return false;

    isSaving = true;
    error = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on ApiException catch (failure) {
      error = failure;
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
