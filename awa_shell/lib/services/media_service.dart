import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MediaService {
  static const int _maxBase64Size = 1024 * 1024; // 1MB

  static Future<Map<String, dynamic>> takePhoto(Map<String, dynamic>? params) async {
    final ImagePicker picker = ImagePicker();
    final int imageQuality = (params?['quality'] as int?) ?? 80;
    
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: imageQuality,
    );

    if (photo == null) {
      throw Exception('User cancelled camera');
    }

    return await _processFile(photo.path);
  }

  static Future<Map<String, dynamic>> pickFile(Map<String, dynamic>? params) async {
    FilePickerResult? result = await FilePicker.pickFiles();

    if (result == null || result.files.single.path == null) {
      throw Exception('User cancelled file picker');
    }

    return await _processFile(result.files.single.path!);
  }

  static Future<Map<String, dynamic>> _processFile(String filePath) async {
    final File file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist');
    }

    final int size = await file.length();

    if (size < _maxBase64Size) {
      // Return Base64
      final List<int> bytes = await file.readAsBytes();
      final String base64String = base64Encode(bytes);
      return {
        'base64': base64String,
      };
    } else {
      // Copy to temporary directory and return URI
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = p.basename(filePath);
      final String newPath = p.join(tempDir.path, fileName);
      final File copiedFile = await file.copy(newPath);
      
      return {
        'path': 'file://${copiedFile.path}',
      };
    }
  }
}
