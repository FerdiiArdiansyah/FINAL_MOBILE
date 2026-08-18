import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/user_model.dart';
import '../../core/models/notification_model.dart';
import '../../core/theme/app_theme.dart';

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;
    final db = FirestoreService();
    final canCreate = ['ADMIN', 'GURU_PIKET', 'WALI_KELAS']
        .contains(user.role);
    return Scaffold(
      appBar: AppBar(title: const Text('Pengumuman')),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => _showCreateDialog(context, user),
              child: const Icon(Icons.add),
            )
          : null,
      body: StreamBuilder<List<AnnouncementModel>>(
        stream: db.getAnnouncements(classId: user.classId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final announcements = snap.data ?? [];
          if (announcements.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.announcement_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada pengumuman',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            itemBuilder: (context, i) {
              return _AnnouncementCard(announcement: announcements[i]);
            },
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, UserModel user) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    bool isUrgent = false;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Buat Pengumuman'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration:
                    const InputDecoration(labelText: 'Judul'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Isi Pengumuman'),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: isUrgent,
                title: const Text('Darurat (Push Notification)'),
                onChanged: (v) =>
                    setState(() => isUrgent = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) {
                  return;
                }
                final db = FirestoreService();
                await db.addAnnouncement(
                  AnnouncementModel(
                    id: '',
                    title: titleCtrl.text,
                    content: contentCtrl.text,
                    authorId: user.uid,
                    authorName: user.name,
                    priority: isUrgent ? 'urgent' : 'normal',
                    createdAt: DateTime.now(),
                  ),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pengumuman berhasil dibuat'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
              child: const Text('Publikasi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final isUrgent = announcement.priority == 'urgent';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isUrgent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.campaign, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('PENGUMUMAN DARURAT',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  announcement.content,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(announcement.authorName,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                    Text(
                      _fmt(announcement.createdAt),
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, "0")}';
}
