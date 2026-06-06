import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/resource_model.dart';
import '../providers/resource_provider.dart';
import '../../../../core/widgets/markdown_editor_view.dart';

class AddEditResourceScreen extends StatefulWidget {
  final ResourceModel? resource;

  const AddEditResourceScreen({Key? key, this.resource}) : super(key: key);

  @override
  State<AddEditResourceScreen> createState() => _AddEditResourceScreenState();
}

class _AddEditResourceScreenState extends State<AddEditResourceScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _url;
  late String _platformType;
  late List<String> _tags;
  late String _notes;
  late bool _isFavorite;

  final List<String> _platforms = [
    'YouTube Video',
    'YouTube Playlist',
    'Instagram Reel',
    'Website',
    'Blog',
    'Documentation',
    'PDF',
    'Custom'
  ];

  @override
  void initState() {
    super.initState();
    final res = widget.resource;
    _title = res?.title ?? '';
    _url = res?.url ?? '';
    _platformType = res?.platformType ?? 'Website';
    _tags = res?.tags != null ? List<String>.from(res!.tags) : [];
    _notes = res?.notes ?? '';
    _isFavorite = res?.isFavorite ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.resource != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Resource' : 'Add Resource'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveForm,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Title Input
            TextFormField(
              initialValue: _title,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
              onSaved: (val) => _title = val?.trim() ?? '',
            ),
            const SizedBox(height: 16),

            // URL Input
            TextFormField(
              initialValue: _url,
              decoration: const InputDecoration(
                labelText: 'URL *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter a URL';
                if (!val.startsWith('http://') && !val.startsWith('https://')) {
                  return 'Please enter a valid URL starting with http:// or https://';
                }
                return null;
              },
              onSaved: (val) => _url = val?.trim() ?? '',
            ),
            const SizedBox(height: 16),

            // Platform Dropdown
            DropdownButtonFormField<String>(
              value: _platformType,
              decoration: const InputDecoration(
                labelText: 'Platform Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _platforms.map((platform) {
                return DropdownMenuItem(
                  value: platform,
                  child: Text(platform),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _platformType = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Tags Input
            TextFormField(
              initialValue: _tags.join(', '),
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                hintText: 'e.g. flutter, state-management, tutorial',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_offer),
              ),
              onSaved: (val) {
                if (val != null && val.trim().isNotEmpty) {
                  _tags = val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                } else {
                  _tags = [];
                }
              },
            ),
            const SizedBox(height: 16),

            // Favorite Status
            SwitchListTile(
              title: const Text('Add to Favorites'),
              subtitle: const Text('Mark this resource for quick access'),
              value: _isFavorite,
              onChanged: (val) {
                setState(() {
                  _isFavorite = val;
                });
              },
              secondary: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null,
              ),
            ),
            const SizedBox(height: 16),

            // Notes Editor (Markdown)
            MarkdownEditorView(
              initialValue: _notes,
              onChanged: (val) {
                _notes = val;
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final provider = Provider.of<ResourceProvider>(context, listen: false);

    if (widget.resource != null) {
      // Editing
      final updated = widget.resource!.copyWith(
        title: _title,
        url: _url,
        platformType: _platformType,
        tags: _tags,
        notes: _notes,
        isFavorite: _isFavorite,
      );
      await provider.updateResource(updated);
    } else {
      // Adding
      await provider.addResource(
        title: _title,
        url: _url,
        platformType: _platformType,
        tags: _tags,
        notes: _notes,
        isFavorite: _isFavorite,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.resource != null ? 'Resource updated' : 'Resource added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }
}
