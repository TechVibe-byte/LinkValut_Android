import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../resources/presentation/providers/resource_provider.dart';
import '../../../resources/data/models/resource_model.dart';
import '../../../learning/presentation/providers/learning_provider.dart';
import '../../../resources/presentation/screens/resource_detail_screen.dart';
import '../../../qr/presentation/screens/qr_scanner_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resourceProvider = Provider.of<ResourceProvider>(context);
    final learningProvider = Provider.of<LearningProvider>(context);

    final allRes = resourceProvider.allResources;
    final activeRes = allRes.where((r) => !r.isArchived).toList();
    final completedCount = activeRes.where((r) => r.learningStatus == 'Completed').length;
    final favoriteCount = activeRes.where((r) => r.isFavorite).length;
    final queueCount = activeRes.where((r) => r.learningStatus != 'Completed').length;

    // Daily Goals
    final completedToday = learningProvider.getCompletedTodayCount(allRes);
    final dailyGoal = learningProvider.dailyGoal;
    final goalProgress = dailyGoal > 0 ? (completedToday / dailyGoal).clamp(0.0, 1.0) : 0.0;

    // Continue Learning
    final lastActiveId = learningProvider.lastActiveResourceId;
    final lastActiveResource = lastActiveId != null
        ? allRes.firstWhere((r) => r.id == lastActiveId, orElse: () => allRes.first)
        : (activeRes.isNotEmpty ? activeRes.first : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LinkVault'),
        actions: [
          IconButton(
            tooltip: 'Scan QR to Import',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QrScannerScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Streak and Goal Banner Card
            _buildStreakGoalCard(theme, learningProvider.streakCount, completedToday, dailyGoal, goalProgress),
            const SizedBox(height: 16),

            // Continue Learning Widget
            if (lastActiveResource != null && !lastActiveResource.isArchived && lastActiveResource.learningStatus != 'Completed') ...[
              _buildResumeLearningCard(context, theme, lastActiveResource),
              const SizedBox(height: 16),
            ],

            // Stats Grid
            _buildStatsGrid(theme, activeRes.length, completedCount, favoriteCount, queueCount),
            const SizedBox(height: 16),

            // Weekly activity chart
            _buildWeeklyActivityCard(theme, learningProvider),
            const SizedBox(height: 16),

            // Platform Distribution breakdown
            _buildPlatformDistributionCard(theme, activeRes),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakGoalCard(
    ThemeData theme,
    int streak,
    int completedToday,
    int dailyGoal,
    double progress,
  ) {
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        '$streak Day Streak!',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Daily Goal: $completedToday / $dailyGoal completed',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    color: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeLearningCard(
    BuildContext context,
    ThemeData theme,
    ResourceModel resource,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resume Learning',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              resource.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              resource.platformType,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: resource.progressPercentage / 100,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ResourceDetailScreen(resourceId: resource.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Continue Learning'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    ThemeData theme,
    int total,
    int completed,
    int favorites,
    int queue,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatTile(theme, 'Total Items', total.toString(), Icons.folder, Colors.indigo),
        _buildStatTile(theme, 'Completed', completed.toString(), Icons.task_alt, Colors.green),
        _buildStatTile(theme, 'Favorites', favorites.toString(), Icons.favorite, Colors.red),
        _buildStatTile(theme, 'In Queue', queue.toString(), Icons.playlist_play, Colors.orange),
      ],
    );
  }

  Widget _buildStatTile(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyActivityCard(ThemeData theme, LearningProvider learningProvider) {
    final activityLog = learningProvider.getActivityLog();
    final List<BarChartGroupData> barGroups = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final activityCount = activityLog[dateStr] ?? 0;
      
      barGroups.add(
        BarChartGroupData(
          x: 6 - i,
          barRods: [
            BarChartRodData(
              toY: activityCount.toDouble(),
              color: theme.colorScheme.primary,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Activity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final date = now.subtract(Duration(days: 6 - val.toInt()));
                          final label = DateFormat('E').format(date).substring(0, 1);
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(label, style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformDistributionCard(ThemeData theme, List<ResourceModel> resources) {
    // Count platform frequency
    final Map<String, int> distribution = {};
    for (var r in resources) {
      distribution[r.platformType] = (distribution[r.platformType] ?? 0) + 1;
    }

    if (distribution.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalCount = resources.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Platform Distribution',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...distribution.entries.map((entry) {
              final pct = entry.value / totalCount;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(entry.key, style: const TextStyle(fontSize: 12)),
                        const Spacer(),
                        Text('${(pct * 100).toStringAsFixed(0)}% (${entry.value})', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: pct,
                      color: _getPlatformColor(entry.key),
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'YouTube Video':
      case 'YouTube Playlist':
        return Colors.red;
      case 'Instagram Reel':
        return Colors.purple;
      case 'Blog':
        return Colors.orange;
      case 'Documentation':
        return Colors.blue;
      case 'PDF':
        return Colors.redAccent;
      case 'Website':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }
}
