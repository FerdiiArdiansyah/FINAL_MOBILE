import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  StorageService._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> uploadFile({
    required File file,
    required String storagePath,
    void Function(double)? onProgress,
  }) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
    final ref = _storage.ref('$storagePath/$fileName');
    final task = ref.putFile(file);

    if (onProgress != null) {
      task.snapshotEvents.listen((snapshot) {
        final progress =
            snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    await task;
    return ref.getDownloadURL();
  }

  static Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // File may not exist
    }
  }
}
