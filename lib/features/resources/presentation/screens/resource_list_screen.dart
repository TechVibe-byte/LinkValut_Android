import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/resource_model.dart';
import '../providers/resource_provider.dart';
import 'resource_detail_screen.dart';
import 'add_edit_resource_screen.dart';

class ResourceListScreen extends StatefulWidget {
  const ResourceListScreen({Key? key}) : super(key: key);

  @override
  State<ResourceListScreen> createState() => _ResourceListScreenState();
}

class _ResourceListScreenState extends State<ResourceListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<ResourceProvider>(context);
    final resources = provider.filteredResources;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resources'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            tooltip: 'Clear Filters',
            onPressed: () {
              provider.clearFilters();
              _searchController.clear();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search title, URL, tags, or notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) => provider.setSearchQuery(val),
            ),
          ),

          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                // Platform Filter
                _buildFilterChip(
                  label: provider.selectedPlatform ?? 'All Platforms',
                  icon: Icons.category_outlined,
                  isSelected: provider.selectedPlatform != null,
                  onSelected: () => _showPlatformFilterDialog(context, provider),
                ),
                const SizedBox(width: 8),

                // Favorite Filter
                FilterChip(
                  label: const Text('Favorites Only'),
                  selected: provider.filterFavorite ?? false,
                  onSelected: (val) {
                    provider.setFilterFavorite(val ? true : null);
                  },
                ),
                const SizedBox(width: 8),

                // Learning Status Filter
                _buildFilterChip(
                  label: provider.filterLearningStatus ?? 'All Statuses',
                  icon: Icons.hourglass_empty,
                  isSelected: provider.filterLearningStatus != null,
                  onSelected: () => _showStatusFilterDialog(context, provider),
                ),
              ],
            ),
          ),

          // Tags Filter horizontal list
          if (provider.allTags.isNotEmpty)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: provider.allTags.length,
                itemBuilder: (context, index) {
                  final tag = provider.allTags[index];
                  final isSelected = provider.searchQuery == tag;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InputChip(
                      label: Text('#$tag'),
                      selected: isSelected,
                      onSelected: (val) {
                        provider.setSearchQuery(val ? tag : '');
                        if (val) {
                          _searchController.text = tag;
                        } else {
                          _searchController.clear();
                        }
                      },
                    ),
                  );
                },
              ),
            ),

          // Resource List
          Expanded(
            child: resources.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          'No resources found.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: resources.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      final resource = resources[index];
                      return _buildResourceCard(context, resource, provider, theme);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Resource',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddEditResourceScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onSelected,
      backgroundColor: isSelected ? Colors.indigo.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildResourceCard(
    BuildContext context,
    ResourceModel resource,
    ResourceProvider provider,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Slidable(
        key: ValueKey(resource.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _openUrl(resource.url),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.open_in_new,
              label: 'Open',
            ),
            SlidableAction(
              onPressed: (_) => provider.toggleFavorite(resource.id),
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              icon: resource.isFavorite ? Icons.favorite : Icons.favorite_border,
              label: 'Favorite',
            ),
            SlidableAction(
              onPressed: (_) => provider.toggleArchived(resource.id),
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              icon: Icons.archive,
              label: 'Archive',
            ),
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResourceDetailScreen(resourceId: resource.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _getPlatformIcon(resource.platformType, theme),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          resource.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (resource.isFavorite)
                        const Icon(Icons.favorite, color: Colors.red, size: 16),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    resource.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Progress indicator
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: resource.progressPercentage / 100,
                          borderRadius: BorderRadius.circular(4),
                          backgroundColor: theme.colorScheme.surfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${resource.progressPercentage.toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (resource.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: resource.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#$tag',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
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

    return Icon(icon, color: color, size: 20);
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showPlatformFilterDialog(BuildContext context, ResourceProvider provider) {
    final platforms = [
      'YouTube Video',
      'YouTube Playlist',
      'Instagram Reel',
      'Website',
      'Blog',
      'Documentation',
      'PDF',
      'Custom'
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter by Platform'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All Platforms'),
                onTap: () {
                  provider.setSelectedPlatform(null);
                  Navigator.of(ctx).pop();
                },
              ),
              ...platforms.map((platform) {
                return ListTile(
                  title: Text(platform),
                  onTap: () {
                    provider.setSelectedPlatform(platform);
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusFilterDialog(BuildContext context, ResourceProvider provider) {
    final statuses = ['Not Started', 'In Progress', 'Completed'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter by Learning Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Statuses'),
              onTap: () {
                provider.setFilterLearningStatus(null);
                Navigator.of(ctx).pop();
              },
            ),
            ...statuses.map((status) {
              return ListTile(
                title: Text(status),
                onTap: () {
                  provider.setFilterLearningStatus(status);
                  Navigator.of(ctx).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
