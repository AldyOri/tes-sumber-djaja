import 'dart:async';

import 'package:flutter/material.dart';

class SearchBox extends StatefulWidget {
  const SearchBox({super.key, required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  final _text = TextEditingController();
  Timer? _debounce;

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => widget.onChanged(value),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _text,
    onChanged: _search,
    maxLength: 150,
    decoration: InputDecoration(
      hintText: widget.hint,
      counterText: '',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: _text.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'Hapus pencarian',
              icon: const Icon(Icons.close),
              onPressed: () {
                _text.clear();
                _search('');
              },
            ),
    ),
  );
}
