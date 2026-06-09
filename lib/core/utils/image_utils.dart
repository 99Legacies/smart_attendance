import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Image utility for compression and optimization.
class ImageUtils {
  static const int maxWidth = 512;
  static const int maxHeight = 512;
  static const int jpegQuality = 80;

  /// Compress and save image from file path.
  /// Returns the local path to the compressed image.
  static Future<String> compressAndSave(String filePath) async {
    try {
      final originalFile = File(filePath);
      if (!await originalFile.exists()) {
        throw Exception('Image file not found: $filePath');
      }

      final bytes = await originalFile.readAsBytes();
      return await _compressBytes(bytes);
    } catch (e) {
      developer.log(
        'Image compression failed: $e',
        name: 'ImageUtils',
        error: e,
      );
      rethrow;
    }
  }

  /// Compress image bytes and save to app cache directory.
  static Future<String> _compressBytes(Uint8List bytes) async {
    try {
      // Decode original image
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if needed
      final resized = img.copyResize(
        image,
        width: image.width > maxWidth ? maxWidth : image.width,
        height: image.height > maxHeight ? maxHeight : image.height,
      );

      // Encode as JPEG with quality setting
      final compressed = img.encodeJpg(resized, quality: jpegQuality);

      // Save to app cache directory
      final dir = await getTemporaryDirectory();
      final profileDir = Directory('${dir.path}/profile_images');
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${profileDir.path}/profile_$timestamp.jpg');
      await file.writeAsBytes(Uint8List.fromList(compressed));

      developer.log(
        'Image compressed: ${bytes.length} → ${compressed.length} bytes',
        name: 'ImageUtils',
      );

      return file.path;
    } catch (e) {
      developer.log(
        'Failed to compress image: $e',
        name: 'ImageUtils',
        error: e,
      );
      rethrow;
    }
  }
}
