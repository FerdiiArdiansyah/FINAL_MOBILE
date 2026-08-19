import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/material_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/file_picker.dart';
import '../../core/utils/cloudinary_uploader.dart';
import '../../core/widgets/class_dropdown.dart';

class UploadMaterialPage extends StatefulWidget {
  const UploadMaterialPage({super.key});

  @override
  State<UploadMaterialPage> createState() => _UploadMaterialPageState();
}

class _UploadMaterialPageState extends State<UploadMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subjectController = TextEditingController();
  final _classController = TextEditingController();
  final _urlController = TextEditingController();

  String _selectedType = 'pdf';
  bool _loading = false;
  // On web: use Cloudinary; on mobile: use Firebase Storage
  bool _useFileUpload = true;
  PickedFile? _pickedFile;
  String? _selectedClassId;
  double _uploadProgress = 0;

  static const _typeAccept = {
    'pdf': 'application/pdf,.pdf',
    'video': 'video/*',
    'link': '*',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subjectController.dispose();
    _classController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final accept = _typeAccept[_selectedType] ?? '*';
    final file = await pickFileFromStorage(accept: accept);
    if (file != null && mounted) {
      setState(() {
        _pickedFile = file;
        _urlController.clear();
      });
    }
  }

  Future<String> _uploadFile(PickedFile file) async {
    if (kIsWeb) {
      return uploadToCloudinary(
        file.bytes,
        file.name,
        file.mimeType,
        cloudName: 'jwphqjie',
        uploadPreset: 'Nugrahn24 Preset',
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );
    } else {
      return _uploadToStorage(file);
    }
  }

  Future<String> _uploadToStorage(PickedFile file) async {
    final path =
        'materials/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final ref = FirebaseStorage.instance.ref(path);
    final task = ref.putData(
      file.bytes,
      SettableMetadata(contentType: file.mimeType),
    );

    task.snapshotEvents.listen((snap) {
      if (!mounted) return;
      setState(() {
        _uploadProgress = snap.bytesTransferred / snap.totalBytes;
      });
    });

    await task;
    return ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_useFileUpload && _pickedFile == null && _selectedType != 'link') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih file terlebih dahulu')),
      );
      return;
    }
    if (!_useFileUpload && _urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL file wajib diisi')),
      );
      return;
    }

    final user = context.read<AuthProvider>().userModel!;
    setState(() {
      _loading = true;
      _uploadProgress = 0;
    });

    try {
      String fileUrl;
      if (_useFileUpload && _pickedFile != null) {
        fileUrl = await _uploadFile(_pickedFile!);
      } else {
        fileUrl = _urlController.text.trim();
      }
      if (_selectedClassId == null || _selectedClassId!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pilih kelas terlebih dahulu')),
          );
        }
        return;
      }
      final db = FirestoreService();
      await db.addMaterial(
        MaterialModel(
          id: '',
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          subject: _subjectController.text.trim(),
          classId: _selectedClassId!,
          teacherId: user.uid,
          teacherName: user.name,
          type: _selectedType,
          fileUrl: fileUrl,
          createdAt: DateTime.now(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Materi berhasil diupload!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal upload: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Materi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul Materi *'),
                validator: (v) =>
                    v?.isEmpty == true ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subjectController,
                decoration:
                    const InputDecoration(labelText: 'Mata Pelajaran *'),
                validator: (v) =>
                    v?.isEmpty == true ? 'Mata pelajaran wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              ClassDropdown(
                value: _selectedClassId,
                onChanged: (v) => setState(() => _selectedClassId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Tipe Materi'),
                items: ['pdf', 'video', 'link']
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedType = v!;
                  _pickedFile = null;
                  _useFileUpload = v != 'link';
                }),
              ),
              const SizedBox(height: 16),

              // Pilih file atau URL
              if (_selectedType != 'link') ...[
                Row(
                  children: [
                    Expanded(
                      child: _ToggleBtn(
                        label: 'Pilih dari Perangkat',
                        icon: Icons.upload_file,
                        selected: _useFileUpload,
                        onTap: () => setState(() => _useFileUpload = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ToggleBtn(
                        label: 'Input URL Manual',
                        icon: Icons.link,
                        selected: !_useFileUpload,
                        onTap: () => setState(() => _useFileUpload = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // File picker
              if (_useFileUpload && _selectedType != 'link') ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.folder_open),
                  label: Text(
                    _pickedFile == null
                        ? 'Pilih File ${_selectedType.toUpperCase()} dari Perangkat'
                        : _pickedFile!.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: _pickedFile != null
                        ? AppTheme.successColor
                        : AppTheme.primaryColor,
                    side: BorderSide(
                      color: _pickedFile != null
                          ? AppTheme.successColor
                          : AppTheme.primaryColor,
                    ),
                  ),
                  onPressed: _loading ? null : _pickFile,
                ),

                // Progress bar saat upload
                if (_loading && _uploadProgress > 0) ...[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: Colors.grey[200],
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mengupload ke Firebase Storage... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],

                // Info file yang dipilih
                if (_pickedFile != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.successColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedType == 'video'
                              ? Icons.video_file
                              : Icons.picture_as_pdf,
                          color: AppTheme.successColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_pickedFile!.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              Text('${_pickedFile!.sizeKb} KB',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.grey, size: 18),
                          onPressed: () => setState(() => _pickedFile = null),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              // URL manual
              if (!_useFileUpload || _selectedType == 'link') ...[
                TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: _selectedType == 'link'
                        ? 'URL Link *'
                        : 'URL File (Firebase Storage / Drive) *',
                    hintText: 'https://...',
                    prefixIcon: const Icon(Icons.link),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Deskripsi singkat materi...',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.upload),
                label: const Text('Upload Materi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16, color: selected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
