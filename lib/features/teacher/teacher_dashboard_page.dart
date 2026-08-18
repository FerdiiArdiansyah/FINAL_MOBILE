import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/material_model.dart';
import '../../core/models/user_model.dart';
import '../../core/models/violation_model.dart';
import '../../core/theme/app_theme.dart';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;
    final db = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Guru Mapel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Card(
              color: AppTheme.primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${user.name}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Guru Mata Pelajaran',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Actions
            Text('Aksi Cepat',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.upload_file,
                    label: 'Upload Materi',
                    color: Colors.blue,
                    onTap: () => context.push('/teacher/upload-material'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.assignment_add,
                    label: 'Buat Tugas',
                    color: Colors.orange,
                    onTap: () =>
                        context.push('/teacher/create-assignment'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.how_to_reg,
                    label: 'Input Absensi',
                    color: Colors.green,
                    onTap: () => context.push('/teacher/attendance'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.grade,
                    label: 'Penilaian',
                    color: Colors.purple,
                    onTap: () => context.push('/notifications'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.bar_chart,
                    label: 'Statistik',
                    color: Colors.teal,
                    onTap: () => context.push('/teacher/stats'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.forum_outlined,
                    label: 'Forum Diskusi',
                    color: Colors.deepPurple,
                    onTap: () => context.push('/forum'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Lapor Pelanggaran — Guru Mapel (Lapor)
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.gavel_outlined,
                    label: 'Lapor Pelanggaran',
                    color: Colors.deepOrange,
                    onTap: () => _showViolationReportDialog(context, user),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.announcement_outlined,
                    label: 'Pengumuman',
                    color: Colors.indigo,
                    onTap: () => context.push('/announcements'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recent Assignments
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tugas Saya',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<AssignmentModel>>(
              stream: db.getAssignments(teacherId: user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final assignments = snapshot.data!;
                if (assignments.isEmpty) {
                  return const _EmptyCard(
                      message: 'Belum ada tugas dibuat');
                }
                return Column(
                  children: assignments.take(5).map((a) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          a.type == 'kuis'
                              ? Icons.quiz_outlined
                              : Icons.assignment_outlined,
                          color: Colors.orange,
                        ),
                        title: Text(a.title),
                        subtitle: Text(
                            '${a.subject} • Deadline: ${_fmt(a.deadline)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.people_outlined),
                          onPressed: () => context
                              .push('/teacher/grading/${a.id}'),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            // Materials
            Text('Materi Saya',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            StreamBuilder<List<MaterialModel>>(
              stream: db.getMaterials(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final materials = snapshot.data!
                    .where((m) => m.teacherId == user.uid)
                    .take(3)
                    .toList();
                if (materials.isEmpty) {
                  return const _EmptyCard(
                      message: 'Belum ada materi diupload');
                }
                return Column(
                  children: materials.map((m) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          m.type == 'video'
                              ? Icons.play_circle_outline
                              : Icons.picture_as_pdf,
                          color: Colors.blue,
                        ),
                        title: Text(m.title),
                        subtitle:
                            Text('${m.subject} • ${m.classId}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () =>
                              _confirmDelete(context, db, m.id),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, FirestoreService db, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Materi'),
        content:
            const Text('Apakah Anda yakin ingin menghapus materi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await db.deleteMaterial(id);
    }
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void _showViolationReportDialog(BuildContext context, UserModel user) {
    final nisnCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: '5');
    String category = 'ringan';
    UserModel? foundStudent;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.gavel_outlined, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text('Lapor Pelanggaran Siswa'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nisnCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'NISN Siswa'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final db = FirestoreService();
                        final users = await db.getAllUsers();
                        final match = users.where((u) =>
                            u.nisn == nisnCtrl.text.trim() ||
                            u.name.toLowerCase().contains(nisnCtrl.text.toLowerCase())).toList();
                        if (match.isNotEmpty) {
                          setState(() {
                            foundStudent = match.first;
                            nameCtrl.text = match.first.name;
                          });
                        } else {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Siswa tidak ditemukan')),
                            );
                          }
                        }
                      },
                      child: const Text('Cari'),
                    ),
                  ],
                ),
                if (foundStudent != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Ditemukan: ${foundStudent!.name} — Kelas ${foundStudent!.className ?? "-"}',
                      style: const TextStyle(color: AppTheme.successColor, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: ['ringan', 'sedang', 'berat']
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c[0].toUpperCase() + c.substring(1)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      category = v!;
                      if (v == 'ringan') pointsCtrl.text = '5';
                      else if (v == 'sedang') pointsCtrl.text = '15';
                      else pointsCtrl.text = '30';
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pointsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Poin'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Deskripsi Pelanggaran *'),
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
                if (descCtrl.text.isEmpty || foundStudent == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cari siswa dan isi deskripsi terlebih dahulu')),
                  );
                  return;
                }
                final db = FirestoreService();
                await db.addViolation(
                  ViolationModel(
                    id: '',
                    studentId: foundStudent!.uid,
                    studentName: foundStudent!.name,
                    classId: foundStudent!.classId ?? '',
                    description: descCtrl.text,
                    points: int.tryParse(pointsCtrl.text) ?? 5,
                    category: category,
                    reportedBy: user.uid,
                    reportedByName: user.name,
                    status: 'pending',
                    date: DateTime.now(),
                    createdAt: DateTime.now(),
                  ),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pelanggaran berhasil dilaporkan'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
              child: const Text('Lapor'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(message,
              style: const TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }
}
