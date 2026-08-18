import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';
import 'picked_file.dart';

// Web implementation: opens native file picker via dart:html
Future<PickedFile?> pickFileFromStorage({String accept = '*'}) async {
  final completer = Completer<PickedFile?>();

  final input = html.FileUploadInputElement()
    ..accept = accept
    ..style.display = 'none';

  html.document.body!.append(input);

  bool resolved = false;

  input.onChange.listen((_) {
    if (resolved) return;
    resolved = true;
    final file = input.files?.first;
    if (file == null) {
      completer.complete(null);
      input.remove();
      return;
    }
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoadEnd.listen((_) {
      final bytes = reader.result as Uint8List;
      completer.complete(PickedFile(
        bytes: bytes,
        name: file.name,
        mimeType: file.type.isNotEmpty ? file.type : 'application/octet-stream',
      ));
      input.remove();
    });
  });

  // If user cancels without selecting a file
  html.window.addEventListener('focus', (_) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!resolved) {
        resolved = true;
        completer.complete(null);
        input.remove();
      }
    });
  }, true);

  input.click();
  return completer.future;
}
