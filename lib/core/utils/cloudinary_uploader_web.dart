// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

Future<String> uploadToCloudinary(
  List<int> bytes,
  String filename,
  String mimeType, {
  required String cloudName,
  required String uploadPreset,
  void Function(double)? onProgress,
}) async {
  final completer = Completer<String>();
  final formData = html.FormData();

  formData.appendBlob(
    'file',
    html.Blob([Uint8List.fromList(bytes)], mimeType),
    filename,
  );
  formData.append('upload_preset', uploadPreset);
  formData.append('folder', 'edutech_smk_materials');

  final xhr = html.HttpRequest();
  xhr.open('POST', 'https://api.cloudinary.com/v1_1/$cloudName/auto/upload');

  if (onProgress != null) {
    xhr.upload.onProgress.listen((event) {
      if (event.lengthComputable && event.total! > 0) {
        onProgress(event.loaded! / event.total!);
      }
    });
  }

  xhr.onLoad.listen((_) {
    if (xhr.status == 200) {
      try {
        final response = jsonDecode(xhr.responseText!) as Map;
        completer.complete(response['secure_url'] as String);
      } catch (e) {
        completer.completeError(Exception('Gagal parse response Cloudinary'));
      }
    } else {
      completer.completeError(
          Exception('Upload gagal (${xhr.status}): ${xhr.responseText}'));
    }
  });

  xhr.onError.listen((_) {
    completer.completeError(Exception('Koneksi gagal saat upload'));
  });

  xhr.send(formData);
  return completer.future;
}
