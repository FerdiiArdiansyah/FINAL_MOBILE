import 'dart:typed_data';

class PickedFile {
  final Uint8List bytes;
  final String name;
  final String mimeType;

  const PickedFile({
    required this.bytes,
    required this.name,
    required this.mimeType,
  });

  int get sizeKb => bytes.length ~/ 1024;

  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }
}
