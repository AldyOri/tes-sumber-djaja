import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../controllers/paged_controller.dart';
import 'feedback_states.dart';

class PagedResults<T> extends StatelessWidget {
  const PagedResults({
    super.key,
    required this.controller,
    required this.itemBuilder,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final PagedController<T> controller;
  final Widget Function(T) itemBuilder;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.error != null) {
      return RequestError(
        message: controller.error!.message,
        onRetry: () => controller.load(),
      );
    }

    final result = controller.result;

    if (result == null || result.items.isEmpty) {
      return EmptyState(title: emptyTitle, message: emptyMessage);
    }

    return Column(
      children: [
        for (final item in result.items) ...[
          itemBuilder(item),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '${result.total} data · Halaman ${result.page}/${result.pages}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
            IconButton.outlined(
              tooltip: 'Halaman sebelumnya',
              onPressed: result.page > 1
                  ? () => controller.load(page: result.page - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Halaman berikutnya',
              onPressed: result.hasNext
                  ? () => controller.load(page: result.page + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}
