import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/resources/data/models/resource_model.dart';
import '../database/hive_helper.dart';

class BackupHelper {
  static Future<String?> exportBackup() async {
    try {
      final box = HiveHelper.resourceBox;
      final resources = box.values.toList();
      
      final listJson = resources.map((e) => e.toJson()).toList();
      final backupMap = {
        'app': 'LinkVault',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'resources': listJson,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupMap);
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/linkvault_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      await SharePlus.shareXFiles(
        [XFile(file.path)],
        subject: 'LinkVault Backup',
        text: 'Backup exported from LinkVault on ${DateTime.now()}',
      );

      return "Backup exported and shared successfully.";
    } catch (e) {
      return "Export failed: ${e.toString()}";
    }
  }

  static Future<String?> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return "No file selected.";
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);

      if (data is! Map || data['app'] != 'LinkVault' || data['resources'] is! List) {
        return "Invalid backup file format. Must be a LinkVault backup.";
      }

      final resourcesList = data['resources'] as List;
      final box = HiveHelper.resourceBox;

      int importedCount = 0;
      for (var item in resourcesList) {
        if (item is Map<String, dynamic>) {
          try {
            final resource = ResourceModel.fromJson(item);
            await box.put(resource.id, resource);
            importedCount++;
          } catch (_) {
            // Skip individual corrupt items
          }
        }
      }

      return "Successfully imported $importedCount resources.";
    } catch (e) {
      return "Import failed: ${e.toString()}";
    }
  }
}
