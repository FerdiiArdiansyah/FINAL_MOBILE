import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/user_model.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/material_model.dart';
import '../../core/theme/app_theme.dart';
import 'alert_system_widget.dart';

class WaliDashboardPage extends StatelessWidget {
  const WaliDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;
    final db = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Wali Kelas'),
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
                      child:
                          Icon(Icons.person, color: AppTheme.primaryColor),
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
                          Text(
                            'Wali Kelas: ${user.className ?? "-"}',
                            style: const TextStyle(
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

            // Alert System
            Text('Alert Sistem',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (user.classId != null)
              AlertSystemWidget(classId: user.classId!)
            else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Belum ada kelas perwalian'),
                ),
              ),
            const SizedBox(height: 16),

            // Quick Actions
            Text('Menu',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.people_outlined,
                    label: 'Monitoring Kelas',
                    color: Colors.blue,
                    onTap: () => context.push('/wali-kelas/monitoring'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.warning_amber_outlined,
                    label: 'Pelanggaran',
                    color: Colors.red,
                    onTap: () => context
                        .push('/violations/${user.classId ?? ""}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.announcement_outlined,
                    label: 'Pengumuman',
                    color: Colors.orange,
                    onTap: () => context.push('/announcements'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'Export Laporan',
                    color: Colors.green,
                    onTap: () => _showExportDialog(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Materi & Tugas Monitor — Wali Kelas (Monitor)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tugas Kelas ${user.className ?? ""}',
                    style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () {},
                  child: const Text('Semua'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (user.classId != null)
              StreamBuilder<List<AssignmentModel>>(
                stream: db.getAssignments(classId: user.classId),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final assignments = snap.data!.take(3).toList();
                  if (assignments.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Belum ada tugas untuk kelas ini',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }
                  return Column(
                    children: assignments.map((a) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            a.type == 'kuis' ? Icons.quiz_outlined : Icons.assignment_outlined,
                            color: a.isExpired ? Colors.red : Colors.orange,
                            size: 20,
                          ),
                          title: Text(a.title,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('${a.subject} • ${a.teacherName}'),
                          trailing: Chip(
                            label: Text(
                              a.isExpired ? 'Tutup' : 'Aktif',
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                            backgroundColor: a.isExpired ? Colors.red : Colors.green,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            const SizedBox(height: 16),

            // Materi Terbaru Monitor
            Text('Materi Terbaru Kelas ${user.className ?? ""}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (user.classId != null)
              StreamBuilder<List<MaterialModel>>(
                stream: db.getMaterials(classId: user.classId),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  final materials = snap.data!.take(3).toList();
                  if (materials.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Belum ada materi',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }
                  return Column(
                    children: materials.map((m) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            m.type == 'video' ? Icons.play_circle_outline : Icons.picture_as_pdf,
                            color: Colors.blue,
                            size: 20,
                          ),
                          title: Text(m.title,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('${m.subject} • ${m.teacherName}'),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            const SizedBox(height: 20),

            // Class students summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Daftar Siswa Kelas ${user.className ?? ""}',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            if (user.classId != null)
              StreamBuilder<List<UserModel>>(
                stream: db.getStudentsByClass(user.classId!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final students = snapshot.data!;
                  if (students.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Tidak ada siswa di kelas ini'),
                      ),
                    );
                  }
                  return Column(
                    children: students.take(10).map((s) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(s.name[0].toUpperCase()),
                          ),
                          title: Text(s.name),
                          subtitle: Text('NISN: ${s.nisn ?? "-"}'),
                          trailing: IconButton(
                            icon: const Icon(
                                Icons.warning_amber_outlined,
                                color: Colors.orange),
                            onPressed: () => context
                                .push('/violations/${s.uid}'),
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

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export Laporan'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.picture_as_pdf),
              title: Text('Rekap Absensi Bulanan'),
            ),
            ListTile(
              leading: Icon(Icons.picture_as_pdf),
              title: Text('Rekap Nilai Semester'),
            ),
            ListTile(
              leading: Icon(Icons.picture_as_pdf),
              title: Text('Catatan Pelanggaran'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Export PDF membutuhkan integrasi printer/pdf package'),
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
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
