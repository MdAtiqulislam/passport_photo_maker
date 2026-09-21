import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileUtils {
  FileUtils._();

  /// Get app storage directory for saving permanent projects
  static Future<Directory> getProjectsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'passport_photos'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Get temporary directory for processing
  static Future<Directory> getProcessingTempDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final dir = Directory(p.join(tempDir.path, 'passport_temp'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Generate a unique temp file path with given extension
  static Future<String> createTempFilePath({String extension = 'jpg'}) async {
    final tempDir = await getProcessingTempDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return p.join(tempDir.path, 'temp_$timestamp.$extension');
  }

  /// Generate a project save file path
  static Future<String> createProjectFilePath({String prefix = 'passport', String extension = 'jpg'}) async {
    final dir = await getProjectsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return p.join(dir.path, '${prefix}_$timestamp.$extension');
  }

  /// Clear all temporary files
  static Future<int> clearTemporaryFiles() async {
    try {
      final tempDir = await getProcessingTempDirectory();
      int deletedCount = 0;
      if (await tempDir.exists()) {
        final list = tempDir.listSync();
        for (var entity in list) {
          try {
            await entity.delete(recursive: true);
            deletedCount++;
          } catch (_) {}
        }
      }
      return deletedCount;
    } catch (_) {
      return 0;
    }
  }

  /// Calculate total size of saved projects and temp files in MB
  static Future<double> getStorageUsageMb() async {
    double totalBytes = 0;
    try {
      final projDir = await getProjectsDirectory();
      if (await projDir.exists()) {
        await for (var entity in projDir.list(recursive: true)) {
          if (entity is File) {
            totalBytes += await entity.length();
          }
        }
      }
      final tempDir = await getProcessingTempDirectory();
      if (await tempDir.exists()) {
        await for (var entity in tempDir.list(recursive: true)) {
          if (entity is File) {
            totalBytes += await entity.length();
          }
        }
      }
    } catch (_) {}
    return totalBytes / (1024 * 1024);
  }
}
