import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../resources/presentation/providers/resource_provider.dart';
import '../../../resources/presentation/screens/resource_detail_screen.dart';

class LearningQueueScreen extends StatelessWidget {
  const LearningQueueScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<ResourceProvider>(context);

    // Filter resources that are not completed and not archived
    final queueItems = provider.allResources
        .where((r) => !r.isArchived && r.learningStatus != 'Completed')
        .toList()
      ..sort((a, b) => a.queueIndex.compareTo(b.queueIndex));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Queue'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Tooltip(
              message: 'Drag and drop items using the handles on the right to reorder your learning priorities.',
              child: Icon(Icons.info_outline),
            ),
          )
        ],
      ),
      body: queueItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_add_check, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Your learning queue is empty!',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add active resources to get started.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              itemCount: queueItems.length,
              onReorder: (oldIndex, newIndex) {
                provider.reorderQueue(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final resource = queueItems[index];
                return Card(
                  key: ValueKey(resource.id),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      resource.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${resource.platformType} • ${resource.progressPercentage.toStringAsFixed(0)}% completed',
                    ),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ResourceDetailScreen(resourceId: resource.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
