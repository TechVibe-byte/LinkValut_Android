import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../../features/resources/data/models/resource_model.dart';

class HiveHelper {
  static const String resourceBoxName = "resources_box";
  static const String settingsBoxName = "settings_box";

  static Future<void> init() async {
    final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    
    // Register Adapter
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ResourceModelAdapter());
    }

    // Open boxes
    await Hive.openBox<ResourceModel>(resourceBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static Box<ResourceModel> get resourceBox => Hive.box<ResourceModel>(resourceBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
}
