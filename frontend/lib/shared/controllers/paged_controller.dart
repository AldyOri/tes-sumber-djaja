import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/page_result.dart';

typedef PageLoader<T> = Future<PageResult<T>> Function(String search, int page);

class PagedController<T> extends ChangeNotifier {
  PagedController(this.loader);

  final PageLoader<T> loader;

  PageResult<T>? result;
  ApiException? error;
  String search = '';
  int page = 1;
  bool isLoading = false;

  int _requestId = 0;
  bool _disposed = false;

  Future<void> load({String? search, int? page}) async {
    if (_disposed) return;

    if (search != null) {
      this.search = search.trim();
      this.page = 1;
    }

    if (page != null) this.page = page;

    final requestId = ++_requestId;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await loader(this.search, this.page);

      // A newer search or filter may finish before an older request.
      if (_disposed || requestId != _requestId) return;

      result = response;
    } on ApiException catch (failure) {
      if (_disposed || requestId != _requestId) return;

      error = failure;
    } finally {
      if (!_disposed && requestId == _requestId) {
        isLoading = false;
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
