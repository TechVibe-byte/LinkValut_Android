import 'package:flutter/material.dart';
import '../../../../core/database/hive_helper.dart';
import '../../../resources/data/models/resource_model.dart';
import 'package:intl/intl.dart';

class LearningProvider extends ChangeNotifier {
  static const String _lastActiveKey = "last_active_resource_id";
  static const String _streakKey = "streak_count";
  static const String _lastLearnDateKey = "last_learn_date";
  static const String _dailyGoalKey = "daily_goal";
  static const String _activityLogKey = "activity_log";

  String? get lastActiveResourceId => HiveHelper.settingsBox.get(_lastActiveKey) as String?;
  int get streakCount => HiveHelper.settingsBox.get(_streakKey, defaultValue: 0) as int;
  int get dailyGoal => HiveHelper.settingsBox.get(_dailyGoalKey, defaultValue: 1) as int;

  Map<String, int> getActivityLog() {
    final log = HiveHelper.settingsBox.get(_activityLogKey);
    if (log is Map) {
      return Map<String, int>.from(log);
    }
    return {};
  }

  void updateLastActiveResource(String id) {
    HiveHelper.settingsBox.put(_lastActiveKey, id);
    notifyListeners();
  }

  void setDailyGoal(int goal) {
    HiveHelper.settingsBox.put(_dailyGoalKey, goal);
    notifyListeners();
  }

  int getCompletedTodayCount(List<ResourceModel> resources) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return resources.where((r) {
      if (r.learningStatus != 'Completed') return false;
      final completionDateStr = DateFormat('yyyy-MM-dd').format(r.lastUpdated);
      return completionDateStr == todayStr;
    }).length;
  }

  void trackActivity(String resourceId, double progress) {
    updateLastActiveResource(resourceId);

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Log activity
    final log = getActivityLog();
    log[todayStr] = (log[todayStr] ?? 0) + 1;
    HiveHelper.settingsBox.put(_activityLogKey, log);

    // Update streak
    _updateStreak();
    
    notifyListeners();
  }

  void _updateStreak() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
    
    final lastLearnDate = HiveHelper.settingsBox.get(_lastLearnDateKey) as String?;
    int currentStreak = streakCount;

    if (lastLearnDate == todayStr) {
      // Already learned today, streak remains same
      return;
    } else if (lastLearnDate == yesterdayStr) {
      // Learned yesterday, increment streak
      currentStreak += 1;
    } else {
      // Streak broken, reset to 1
      currentStreak = 1;
    }

    HiveHelper.settingsBox.put(_streakKey, currentStreak);
    HiveHelper.settingsBox.put(_lastLearnDateKey, todayStr);
  }

  void checkStreakReset() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
    final lastLearnDate = HiveHelper.settingsBox.get(_lastLearnDateKey) as String?;

    if (lastLearnDate != null && lastLearnDate != todayStr && lastLearnDate != yesterdayStr) {
      // Streak broken, reset to 0
      HiveHelper.settingsBox.put(_streakKey, 0);
      notifyListeners();
    }
  }

  void resetProgressData() {
    HiveHelper.settingsBox.delete(_lastActiveKey);
    HiveHelper.settingsBox.put(_streakKey, 0);
    HiveHelper.settingsBox.delete(_lastLearnDateKey);
    HiveHelper.settingsBox.delete(_activityLogKey);
    notifyListeners();
  }
}
