import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

/// Dropdown kelas real-time dari koleksi `classes` di Firestore.
class ClassDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String labelText;
  final bool isRequired;

  const ClassDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText = 'Kelas *',
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getClassesStream(),
      builder: (context, snap) {
        final classes = snap.data ?? [];
        final isLoading = snap.connectionState == ConnectionState.waiting;

        if (isLoading) {
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: labelText),
            items: const [],
            onChanged: null,
            hint: const Row(children: [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('Memuat kelas...'),
            ]),
          );
        }

        if (classes.isEmpty) {
          return InputDecorator(
            decoration: InputDecoration(
              labelText: labelText,
              border: const OutlineInputBorder(),
            ),
            child: const Text(
              'Belum ada kelas — minta Admin tambahkan kelas',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          );
        }

        final ids = classes.map((c) => c['classId'] as String).toList();
        final currentValue = ids.contains(value) ? value : null;

        return DropdownButtonFormField<String>(
          value: currentValue,
          decoration: InputDecoration(labelText: labelText),
          hint: const Text('Pilih kelas'),
          isExpanded: true,
          items: classes
              .map((c) => DropdownMenuItem<String>(
                    value: c['classId'] as String,
                    child: Text(
                        '${c['classId']}  —  ${c['className'] ?? c['classId']}'),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: isRequired
              ? (v) => (v == null || v.isEmpty) ? 'Pilih kelas' : null
              : null,
        );
      },
    );
  }
}
