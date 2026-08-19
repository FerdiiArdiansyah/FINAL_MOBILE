Future<String> uploadToCloudinary(
  List<int> bytes,
  String filename,
  String mimeType, {
  required String cloudName,
  required String uploadPreset,
  void Function(double)? onProgress,
}) async {
  throw UnsupportedError(
      'Cloudinary upload tidak didukung di platform ini. Gunakan URL manual.');
}
