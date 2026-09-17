import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Stores camera snapshots in the app's Documents directory.
class SnapshotStorage {
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
}
