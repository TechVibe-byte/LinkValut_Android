import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';

class MarkdownEditorView extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const MarkdownEditorView({super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<MarkdownEditorView> createState() => _MarkdownEditorViewState();
}

class _MarkdownEditorViewState extends State<MarkdownEditorView> {
  late TextEditingController _controller;
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Material(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.note_alt_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Notes (Markdown)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Toggle Mode Button
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isPreviewMode = !_isPreviewMode;
                      });
                    },
                    icon: Icon(
                      _isPreviewMode ? Icons.edit_note : Icons.remove_red_eye_outlined,
                      size: 18,
                    ),
                    label: Text(_isPreviewMode ? 'Edit' : 'Preview'),
                  ),
                  // Copy Button
                  IconButton(
                    tooltip: 'Copy Notes',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _controller.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notes copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                  ),
                ],
              ),
            ),
          ),
          // Content Editor/Viewer
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            child: _isPreviewMode
                ? Markdown(
                    data: _controller.text.isEmpty ? '*No notes yet. Switch to Edit to add notes.*' : _controller.text,
                    shrinkWrap: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                      code: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.primary,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                    ),
                  )
                : TextFormField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: 'Write rich learning notes using Markdown...\n\nExample:\n# Chapter 1\n- Use **bold**\n- Write `code blocks`\n- [Google](https://google.com)',
                      border: InputBorder.none,
                    ),
                    onChanged: widget.onChanged,
                  ),
          ),
        ],
      ),
    );
  }
}
