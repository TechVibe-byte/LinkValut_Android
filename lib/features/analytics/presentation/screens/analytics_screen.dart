import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../resources/presentation/providers/resource_provider.dart';
import '../../../resources/data/models/resource_model.dart';
import '../../../learning/presentation/providers/learning_provider.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resourceProvider = Provider.of<ResourceProvider>(context);
    final learningProvider = Provider.of<LearningProvider>(context);

    final allRes = resourceProvider.allResources;
    final activeRes = allRes.where((r) => !r.isArchived).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Trends'),
      ),
      body: activeRes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No learning data to analyze.',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildCompletionTrendsCard(theme, activeRes),
                const SizedBox(height: 16),
                _buildPlatformUsageCard(theme, activeRes),
                const SizedBox(height: 16),
                _buildMonthlyActivityCard(theme, learningProvider),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildCompletionTrendsCard(ThemeData theme, List<ResourceModel> resources) {
    final notStarted = resources.where((r) => r.learningStatus == 'Not Started').length;
    final inProgress = resources.where((r) => r.learningStatus == 'In Progress').length;
    final completed = resources.where((r) => r.learningStatus == 'Completed').length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completion Status',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: [
                    if (notStarted > 0)
                      PieChartSectionData(
                        value: notStarted.toDouble(),
                        color: Colors.grey,
                        title: 'Not Started ($notStarted)',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    if (inProgress > 0)
                      PieChartSectionData(
                        value: inProgress.toDouble(),
                        color: Colors.orange,
                        title: 'In Progress ($inProgress)',
                        radius: 55,
                        titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    if (completed > 0)
                      PieChartSectionData(
                        value: completed.toDouble(),
                        color: Colors.green,
                        title: 'Completed ($completed)',
                        radius: 60,
                        titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformUsageCard(ThemeData theme, List<ResourceModel> resources) {
    final Map<String, int> distribution = {};
    for (var r in resources) {
      distribution[r.platformType] = (distribution[r.platformType] ?? 0) + 1;
    }

    final sections = distribution.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.toDouble(),
        color: _getPlatformColor(entry.key),
        title: '${entry.key.split(" ").first} (${entry.value})',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Platform Usage Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyActivityCard(ThemeData theme, LearningProvider learningProvider) {
    final activityLog = learningProvider.getActivityLog();
    final List<FlSpot> spots = [];
    final now = DateTime.now();

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final activityCount = activityLog[dateStr] ?? 0;
      spots.add(FlSpot((29 - i).toDouble(), activityCount.toDouble()));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '30-Day Learning Trend',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withOpacity(0.15),
                      ),
                    ),
                  ],
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
                        reservedSize: 22,
                        interval: 5,
                        getTitlesWidget: (val, meta) {
                          final date = now.subtract(Duration(days: 29 - val.toInt()));
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              DateFormat('dd/MM').format(date),
                              style: const TextStyle(fontSize: 8),
                            ),
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
