import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

/// Dropdown untuk memilih kelas berdasarkan data siswa di Firestore.
class ClassDropdown extends StatefulWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String labelText;

  const ClassDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText = 'ID Kelas *',
  });

  @override
  State<ClassDropdown> createState() => _ClassDropdownState();
}

class _ClassDropdownState extends State<ClassDropdown> {
  List<String> _classes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final classes = await FirestoreService().getClasses();
    if (mounted) setState(() { _classes = classes; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: widget.labelText),
        items: const [],
        onChanged: null,
        hint: const Text('Memuat kelas...'),
      );
    }
    if (_classes.isEmpty) {
      return TextFormField(
        initialValue: widget.value,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: 'Belum ada kelas terdaftar — ketik manual',
        ),
        onChanged: widget.onChanged,
        validator: (v) => (v == null || v.isEmpty) ? 'Kelas wajib diisi' : null,
      );
    }
    return DropdownButtonFormField<String>(
      value: _classes.contains(widget.value) ? widget.value : null,
      decoration: InputDecoration(labelText: widget.labelText),
      hint: const Text('Pilih kelas'),
      items: _classes
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: widget.onChanged,
      validator: (v) => (v == null || v.isEmpty) ? 'Kelas wajib diisi' : null,
    );
  }
}
