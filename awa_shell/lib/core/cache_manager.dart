import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CacheManager {
  static Future<void> clearTemporaryCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        final List<FileSystemEntity> contents = cacheDir.listSync();
        for (var entity in contents) {
          if (entity is File) {
            try {
              await entity.delete();
            } catch (e) {
              print('Failed to delete file: ${entity.path}, error: $e');
            }
          } else if (entity is Directory) {
            try {
              await entity.delete(recursive: true);
            } catch (e) {
              print('Failed to delete directory: ${entity.path}, error: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Failed to clear temporary cache: $e');
    }
  }
}
