import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../data/models/resource_model.dart';
import '../providers/resource_provider.dart';
import '../../../learning/presentation/providers/learning_provider.dart';
import '../../../qr/presentation/screens/qr_generator_screen.dart';
import 'add_edit_resource_screen.dart';
import '../../../../core/widgets/markdown_editor_view.dart';

class ResourceDetailScreen extends StatefulWidget {
  final String resourceId;

  const ResourceDetailScreen({super.key, required this.resourceId});

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resourceProvider = Provider.of<ResourceProvider>(context);
    final learningProvider = Provider.of<LearningProvider>(context, listen: false);

    // Find the current resource
    final resourceIndex = resourceProvider.allResources.indexWhere((r) => r.id == widget.resourceId);
    if (resourceIndex == -1) {
      return const Scaffold(
        body: Center(
          child: Text('Resource not found.'),
        ),
      );
    }
    final resource = resourceProvider.allResources[resourceIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Details'),
        actions: [
          IconButton(
            icon: Icon(
              resource.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: resource.isFavorite ? Colors.red : null,
            ),
            onPressed: () => resourceProvider.toggleFavorite(resource.id),
          ),
          IconButton(
            icon: Icon(resource.isArchived ? Icons.unarchive : Icons.archive),
            onPressed: () async {
              await resourceProvider.toggleArchived(resource.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(resource.isArchived ? 'Resource unarchived' : 'Resource archived'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.of(context).pop();
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditResourceScreen(resource: resource),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, resourceProvider, resource),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header information card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _getPlatformIcon(resource.platformType, theme),
                        const SizedBox(width: 8),
                        Text(
                          resource.platformType,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        _getStatusBadge(resource.learningStatus, theme),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      resource.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _openUrl(resource.url),
                      child: Text(
                        resource.url,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    if (resource.tags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: resource.tags.map((tag) {
                          return Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 12)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action List Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.open_in_new),
                      title: const Text('Open Resource URL'),
                      onTap: () => _openUrl(resource.url),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.share),
                      title: const Text('Share Resource'),
                      onTap: () => SharePlus.share(
                        'Checkout this resource: ${resource.title}\nURL: ${resource.url}',
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.qr_code),
                      title: const Text('Generate QR Code'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => QrGeneratorScreen(resource: resource),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.copy_all),
                      title: const Text('Copy Entire Resource Info'),
                      onTap: () => _copyEntireResource(resource),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Learning progress card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learning Tracker',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Progress: ${resource.progressPercentage.toStringAsFixed(0)}%'),
                        const Spacer(),
                        Checkbox(
                          value: resource.isRead,
                          onChanged: (val) {
                            final newProgress = (val ?? false) ? 100.0 : 0.0;
                            resourceProvider.updateProgress(resource.id, newProgress);
                            learningProvider.trackActivity(resource.id, newProgress);
                          },
                        ),
                        const Text('Mark as Completed'),
                      ],
                    ),
                    Slider(
                      value: resource.progressPercentage,
                      min: 0.0,
                      max: 100.0,
                      divisions: 10,
                      label: '${resource.progressPercentage.toStringAsFixed(0)}%',
                      onChanged: (val) {
                        resourceProvider.updateProgress(resource.id, val);
                        learningProvider.trackActivity(resource.id, val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes Editor
            MarkdownEditorView(
              initialValue: resource.notes,
              onChanged: (val) {
                resource.notes = val;
                resourceProvider.updateResource(resource);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _getPlatformIcon(String platform, ThemeData theme) {
    IconData icon;
    Color color;

    switch (platform) {
      case 'YouTube Video':
      case 'YouTube Playlist':
        icon = Icons.play_circle_filled;
        color = Colors.red;
        break;
      case 'Instagram Reel':
        icon = Icons.camera_alt;
        color = Colors.purple;
        break;
      case 'Blog':
        icon = Icons.book;
        color = Colors.orange;
        break;
      case 'Documentation':
        icon = Icons.description;
        color = Colors.blue;
        break;
      case 'PDF':
        icon = Icons.picture_as_pdf;
        color = Colors.redAccent;
        break;
      case 'Website':
        icon = Icons.language;
        color = Colors.teal;
        break;
      default:
        icon = Icons.link;
        color = theme.colorScheme.primary;
    }

    return Icon(icon, color: color, size: 24);
  }

  Widget _getStatusBadge(String status, ThemeData theme) {
    Color color;
    switch (status) {
      case 'Completed':
        color = Colors.green;
        break;
      case 'In Progress':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch URL'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyEntireResource(ResourceModel resource) {
    final buffer = StringBuffer();
    buffer.writeln('Title: ${resource.title}');
    buffer.writeln('URL: ${resource.url}');
    buffer.writeln('Platform: ${resource.platformType}');
    if (resource.tags.isNotEmpty) {
      buffer.writeln('Tags: ${resource.tags.join(", ")}');
    }
    buffer.writeln('Status: ${resource.learningStatus}');
    buffer.writeln('Progress: ${resource.progressPercentage.toStringAsFixed(0)}%');
    if (resource.notes.isNotEmpty) {
      buffer.writeln('\nNotes:\n${resource.notes}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resource information copied'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDelete(BuildContext context, ResourceProvider provider, ResourceModel resource) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Resource?'),
        content: Text('Are you sure you want to delete "${resource.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.deleteResource(resource.id);
              if (!context.mounted) return;
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Go back to list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Resource deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
