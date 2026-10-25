import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/paged_controller.dart';
import 'feedback_states.dart';
import 'search_box.dart';

Future<T?> showRecordPicker<T>({
  required BuildContext context,
  required String title,
  required PageLoader<T> loader,
  required String Function(T) label,
  required String Function(T) subtitle,
  bool Function(T)? isEnabled,
}) => showDialog<T>(
  context: context,
  builder: (_) => _RecordPicker<T>(
    title: title,
    loader: loader,
    label: label,
    subtitle: subtitle,
    isEnabled: isEnabled,
  ),
);

class _RecordPicker<T> extends StatefulWidget {
  const _RecordPicker({
    required this.title,
    required this.loader,
    required this.label,
    required this.subtitle,
    this.isEnabled,
  });

  final String title;
  final PageLoader<T> loader;
  final String Function(T) label;
  final String Function(T) subtitle;
  final bool Function(T)? isEnabled;

  @override
  State<_RecordPicker<T>> createState() => _RecordPickerState<T>();
}

class _RecordPickerState<T> extends State<_RecordPicker<T>> {
  late final _controller = PagedController<T>(widget.loader)..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(20),
    child: SizedBox(
      width: 520,
      height: math.min(620, MediaQuery.sizeOf(context).height * 0.8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SearchBox(
              hint: 'Cari kode atau nama…',
              onChanged: (value) => _controller.load(search: value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  if (_controller.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_controller.error != null) {
                    return SingleChildScrollView(
                      child: RequestError(
                        message: _controller.error!.message,
                        onRetry: () => _controller.load(),
                      ),
                    );
                  }

                  final result = _controller.result;

                  if (result == null || result.items.isEmpty) {
                    return const SingleChildScrollView(
                      child: EmptyState(
                        title: 'Tidak ada hasil',
                        message:
                            'Coba kata kunci lain atau tambahkan data master.',
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          itemCount: result.items.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = result.items[index];
                            final enabled =
                                widget.isEnabled?.call(item) ?? true;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 6,
                              ),
                              enabled: enabled,
                              title: Text(widget.label(item)),
                              subtitle: Text(widget.subtitle(item)),
                              trailing: Icon(
                                enabled ? Icons.chevron_right : Icons.block,
                                size: 20,
                              ),
                              onTap: enabled
                                  ? () => Navigator.pop(context, item)
                                  : null,
                            );
                          },
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Halaman ${result.page}/${result.pages}',
                            ),
                          ),
                          IconButton(
                            tooltip: 'Halaman sebelumnya',
                            onPressed: result.page > 1
                                ? () => _controller.load(page: result.page - 1)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          IconButton(
                            tooltip: 'Halaman berikutnya',
                            onPressed: result.hasNext
                                ? () => _controller.load(page: result.page + 1)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
