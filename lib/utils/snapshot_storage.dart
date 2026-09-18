import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Stores camera snapshots locally and exports them to the device gallery.
class SnapshotStorage {
  static const MethodChannel _galleryChannel =
      MethodChannel('camera_application/gallery');

  static Future<File> save({
    required String cameraId,
    required List<int> jpegBytes,
  }) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final directoryName =
        cameraId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final snapshotDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}snapshots${Platform.pathSeparator}$directoryName',
    );
    await snapshotDirectory.create(recursive: true);

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final snapshot = File(
      '${snapshotDirectory.path}${Platform.pathSeparator}snapshot_$timestamp.jpg',
    );
    await snapshot.writeAsBytes(jpegBytes, flush: true);
    return snapshot;
  }

  /// Saves an image to the platform photo gallery and returns a URI that can
  /// later be opened by the platform's Photos/Gallery app.
  static Future<String?> saveToGallery({
    required List<int> jpegBytes,
    required String fileName,
  }) async {
    return _galleryChannel.invokeMethod<String>('saveImageToGallery', {
      'bytes': Uint8List.fromList(jpegBytes),
      'fileName': fileName,
    });
  }

  static Future<void> openInPhotos(String galleryUri) {
    return _galleryChannel.invokeMethod<void>('openImageInPhotos', {
      'uri': galleryUri,
    });
  }
}
