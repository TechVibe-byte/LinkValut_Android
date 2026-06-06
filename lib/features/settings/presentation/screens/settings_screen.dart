import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/security/auth_helper.dart';
import '../../../../core/notifications/notification_helper.dart';
import '../../../../core/backup/backup_helper.dart';
import '../../../resources/presentation/providers/resource_provider.dart';
import '../../../learning/presentation/providers/learning_provider.dart';
import '../../../../core/database/hive_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pinEnabled = false;
  bool _biometricEnabled = false;
  bool _remindersEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _pinEnabled = AuthHelper.isPinEnabled;
    _biometricEnabled = AuthHelper.isBiometricEnabled;
    
    // Reminders state
    _remindersEnabled = HiveHelper.settingsBox.get('reminders_enabled', defaultValue: false) as bool;
    final savedHour = HiveHelper.settingsBox.get('reminder_hour', defaultValue: 20) as int;
    final savedMinute = HiveHelper.settingsBox.get('reminder_minute', defaultValue: 0) as int;
    _reminderTime = TimeOfDay(hour: savedHour, minute: savedMinute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final resourceProvider = Provider.of<ResourceProvider>(context, listen: false);
    final learningProvider = Provider.of<LearningProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme Management
          _buildSectionHeader(theme, 'Appearance'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('Theme Mode'),
                  subtitle: Text(themeProvider.themeMode.toString().split('.').last.toUpperCase()),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeProvider.themeMode,
                    onChanged: (mode) {
                      if (mode != null) themeProvider.setThemeMode(mode);
                    },
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Security Settings
          _buildSectionHeader(theme, 'Security & Access'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.lock),
                  title: const Text('PIN Lock Screen'),
                  subtitle: const Text('Require a 4-digit PIN on app launch'),
                  value: _pinEnabled,
                  onChanged: (val) => _handlePinToggle(val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('Biometric Authentication'),
                  subtitle: const Text('Use fingerprint/face to unlock'),
                  value: _biometricEnabled,
                  onChanged: _pinEnabled ? (val) => _handleBiometricToggle(val) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Notifications Reminders
          _buildSectionHeader(theme, 'Notifications & Alerts'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: const Text('Daily Learning Reminder'),
                  subtitle: const Text('Get notified daily to continue learning'),
                  value: _remindersEnabled,
                  onChanged: (val) => _handleRemindersToggle(val),
                ),
                if (_remindersEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Reminder Time'),
                    subtitle: Text(_reminderTime.format(context)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _pickReminderTime(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Backup and Restore
          _buildSectionHeader(theme, 'Data Management'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('Export JSON Backup'),
                  subtitle: const Text('Export resources to a JSON file'),
                  onTap: () async {
                    final msg = await BackupHelper.exportBackup();
                    if (!context.mounted) return;
                    if (msg != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Restore JSON Backup'),
                  subtitle: const Text('Import resources from a JSON file'),
                  onTap: () async {
                    final msg = await BackupHelper.importBackup();
                    if (!context.mounted) return;
                    if (msg != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
                      );
                      resourceProvider.refresh();
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Reset All App Data', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Wipe all learning resources, statistics and logs'),
                  onTap: () => _confirmReset(context, resourceProvider, learningProvider),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _handlePinToggle(bool enable) {
    if (enable) {
      _showPinSetupDialog();
    } else {
      AuthHelper.disablePin();
      AuthHelper.setBiometricEnabled(false);
      setState(() {
        _pinEnabled = false;
        _biometricEnabled = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN Lock disabled'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _showPinSetupDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Setup App PIN'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter 4-digit PIN',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = pinController.text;
              if (pin.length == 4 && int.tryParse(pin) != null) {
                await AuthHelper.enablePin(pin);
                if (!context.mounted) return;
                Navigator.of(ctx).pop();
                setState(() {
                  _pinEnabled = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN Lock enabled successfully'), behavior: SnackBarBehavior.floating),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid 4-digit numeric PIN'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _handleBiometricToggle(bool enable) async {
    final canUse = await AuthHelper.canUseBiometrics();
    if (!canUse) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometrics are not supported or configured on this device'), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    await AuthHelper.setBiometricEnabled(enable);
    setState(() {
      _biometricEnabled = enable;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enable ? 'Biometric Authentication enabled' : 'Biometric Authentication disabled'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleRemindersToggle(bool enable) async {
    if (enable) {
      await NotificationHelper.requestPermissions();
      await _scheduleDailyReminder();
    } else {
      await NotificationHelper.cancelAll();
    }

    await HiveHelper.settingsBox.put('reminders_enabled', enable);
    setState(() {
      _remindersEnabled = enable;
    });
  }

  Future<void> _pickReminderTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );

    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
      await HiveHelper.settingsBox.put('reminder_hour', picked.hour);
      await HiveHelper.settingsBox.put('reminder_minute', picked.minute);

      if (_remindersEnabled) {
        await _scheduleDailyReminder();
      }
    }
  }

  Future<void> _scheduleDailyReminder() async {
    await NotificationHelper.scheduleDailyReminder(
      id: 100,
      title: 'Time to learn!',
      body: 'Keep your streak alive! Open LinkVault and study your active resources.',
      hour: _reminderTime.hour,
      minute: _reminderTime.minute,
    );
  }

  void _confirmReset(BuildContext context, ResourceProvider rp, LearningProvider lp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wipe All Data?', style: TextStyle(color: Colors.red)),
        content: const Text('This will delete all saved resources, bookmarks, streaks, charts, and reset the app. This process is permanent.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await HiveHelper.resourceBox.clear();
              await HiveHelper.settingsBox.clear();
              rp.refresh();
              lp.resetProgressData();
              
              if (!context.mounted) return;
              setState(() {
                _pinEnabled = false;
                _biometricEnabled = false;
                _remindersEnabled = false;
              });

              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App data has been completely reset'), behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }
}
