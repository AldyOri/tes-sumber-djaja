import 'package:flutter/material.dart';

import 'feedback_states.dart';
import 'page_layout.dart';

class MasterFormLayout extends StatelessWidget {
  const MasterFormLayout({
    super.key,
    required this.title,
    required this.description,
    required this.formKey,
    required this.fields,
    required this.isSaving,
    required this.onSave,
    this.errorMessage,
  });

  final String title;
  final String description;
  final GlobalKey<FormState> formKey;
  final List<Widget> fields;
  final bool isSaving;
  final VoidCallback onSave;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !isSaving,
    child: Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PageLayout(
        maxWidth: 720,
        children: [
          FeatureHeader(title: title, description: description),
          Panel(
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: AbsorbPointer(
                absorbing: isSaving,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final field in fields) ...[
                      field,
                      const SizedBox(height: 20),
                    ],
                    if (errorMessage != null) ...[
                      Notice(message: errorMessage!, isError: true),
                      const SizedBox(height: 20),
                    ],
                    FilledButton.icon(
                      onPressed: isSaving ? null : onSave,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(isSaving ? 'Menyimpan…' : 'Simpan perubahan'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
