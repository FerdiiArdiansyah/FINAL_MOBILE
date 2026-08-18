import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  String _selectedSubject = 'Semua';
  final List<String> _subjects = [
    'Semua', 'Pemrograman Web', 'Jaringan Komputer',
    'Matematika', 'Bahasa Indonesia', 'Bahasa Inggris',
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;
    final db = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Forum Diskusi')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewPostDialog(context, user),
        child: const Icon(Icons.edit),
      ),
      body: Column(
        children: [
          // Subject filter
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _subjects.length,
              itemBuilder: (context, i) {
                final s = _subjects[i];
                final selected = s == _selectedSubject;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedSubject = s),
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          // Posts list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: db.getForumPosts(
                subjectId:
                    _selectedSubject == 'Semua' ? null : _selectedSubject,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final posts = snap.data ?? [];
                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.forum_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('Belum ada diskusi',
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Mulai Diskusi'),
                          onPressed: () => _showNewPostDialog(context, user),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, i) {
                    final p = posts[i];
                    return _ForumCard(
                      post: p,
                      onTap: () => context.push(
                        '/forum/${p['id']}',
                        extra: p,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showNewPostDialog(BuildContext context, user) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String subject = _selectedSubject == 'Semua'
        ? 'Pemrograman Web'
        : _selectedSubject;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Buat Diskusi Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: subject,
                  decoration:
                      const InputDecoration(labelText: 'Mata Pelajaran'),
                  items: _subjects
                      .where((s) => s != 'Semua')
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => subject = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Judul Pertanyaan *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contentCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Isi Pertanyaan / Diskusi *',
                    hintText: 'Jelaskan pertanyaan atau topik diskusi...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) return;
                final db = FirestoreService();
                await db.addForumPost({
                  'subjectId': subject,
                  'subjectName': subject,
                  'authorId': (user as dynamic).uid,
                  'authorName': (user as dynamic).name,
                  'authorRole': (user as dynamic).role,
                  'title': titleCtrl.text.trim(),
                  'content': contentCtrl.text.trim(),
                  'replyCount': 0,
                  'createdAt': DateTime.now(),
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Diskusi berhasil dibuat'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
              child: const Text('Posting'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForumCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;

  const _ForumCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final role = post['authorRole'] as String? ?? '';
    final isTeacher = role.contains('GURU');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(
                      post['subjectName'] as String? ?? '',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    backgroundColor: AppTheme.secondaryColor,
                    padding: EdgeInsets.zero,
                  ),
                  const Spacer(),
                  if (isTeacher)
                    Chip(
                      label: Text(
                        'Guru',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white),
                      ),
                      backgroundColor: AppTheme.successColor,
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                post['title'] as String? ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                post['content'] as String? ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppTheme.accentColor,
                    child: Text(
                      (post['authorName'] as String? ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    post['authorName'] as String? ?? '',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const Icon(Icons.chat_bubble_outline,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${post['replyCount'] ?? 0} balasan',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
