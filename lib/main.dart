import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/hive_helper.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/security/auth_helper.dart';
import 'core/security/pin_lock_screen.dart';
import 'core/notifications/notification_helper.dart';
import 'features/resources/presentation/providers/resource_provider.dart';
import 'features/learning/presentation/providers/learning_provider.dart';
import 'features/dashboard/presentation/screens/home_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Helpers
  await HiveHelper.init();
  await NotificationHelper.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ResourceProvider()),
        ChangeNotifierProvider(create: (_) => LearningProvider()),
      ],
      child: const LinkVaultApp(),
    ),
  );
}

class LinkVaultApp extends StatefulWidget {
  const LinkVaultApp({Key? key}) : super(key: key);

  @override
  State<LinkVaultApp> createState() => _LinkVaultAppState();
}

class _LinkVaultAppState extends State<LinkVaultApp> {
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _isLocked = AuthHelper.isPinEnabled;
    
    // Check if streak needs reset
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LearningProvider>(context, listen: false).checkStreakReset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'LinkVault',
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: _isLocked
          ? PinLockScreen(
              onUnlocked: () {
                setState(() {
                  _isLocked = false;
                });
              },
            )
          : const HomeWrapper(),
    );
  }
}
