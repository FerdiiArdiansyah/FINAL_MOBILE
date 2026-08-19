import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/material_model.dart';
import '../../core/theme/app_theme.dart';

class MaterialViewPage extends StatelessWidget {
  const MaterialViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;
    final db = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Materi Pembelajaran')),
      body: StreamBuilder<List<MaterialModel>>(
        stream: db.getMaterials(classId: user.classId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final materials = snapshot.data ?? [];
          if (materials.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada materi',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: materials.length,
            itemBuilder: (context, i) {
              final m = materials[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      m.type == 'video'
                          ? Icons.play_circle_outline
                          : m.type == 'link'
                              ? Icons.link
                              : Icons.picture_as_pdf,
                      color: Colors.blue,
                    ),
                  ),
                  title: Text(m.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${m.subject} • ${m.teacherName}\n'
                    '${_formatDate(m.createdAt)}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _openMaterial(context, m),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openMaterial(BuildContext context, MaterialModel m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(m.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mata Pelajaran: ${m.subject}'),
            Text('Guru: ${m.teacherName}'),
            Text('Tipe: ${m.type.toUpperCase()}'),
            const SizedBox(height: 8),
            Text(m.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Buka File'),
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri.tryParse(m.fileUrl);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tidak dapat membuka file'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
