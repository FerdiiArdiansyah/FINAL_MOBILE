import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/material_model.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/counseling_model.dart';
import '../../core/theme/app_theme.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;
    final db = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Siswa'),
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
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D1B6E), AppTheme.primaryColor],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 26,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
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
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.class_outlined,
                                  size: 13, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                user.className ?? 'Belum ada kelas',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.badge_outlined,
                                  size: 13, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                'NISN: ${user.nisn ?? "-"}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick Menu
              Text('Menu Utama',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _MenuCard(
                    icon: Icons.book_outlined,
                    label: 'Materi',
                    color: Colors.blue,
                    onTap: () => context.push('/student/materials'),
                  ),
                  _MenuCard(
                    icon: Icons.assignment_outlined,
                    label: 'Tugas & Kuis',
                    color: Colors.orange,
                    onTap: () => context.push('/student/assignments'),
                  ),
                  _MenuCard(
                    icon: Icons.grade_outlined,
                    label: 'Nilai',
                    color: Colors.green,
                    onTap: () => context.push('/student/grades'),
                  ),
                  _MenuCard(
                    icon: Icons.calendar_today_outlined,
                    label: 'Jadwal',
                    color: Colors.purple,
                    onTap: () => context.push('/student/schedule'),
                  ),
                  _MenuCard(
                    icon: Icons.how_to_reg_outlined,
                    label: 'Absensi',
                    color: Colors.teal,
                    onTap: () => context.push('/student/attendance'),
                  ),
                  _MenuCard(
                    icon: Icons.announcement_outlined,
                    label: 'Pengumuman',
                    color: Colors.red,
                    onTap: () => context.push('/announcements'),
                  ),
                  _MenuCard(
                    icon: Icons.chat_outlined,
                    label: 'Chat Guru',
                    color: Colors.indigo,
                    onTap: () => context.push('/chat-list'),
                  ),
                  _MenuCard(
                    icon: Icons.forum_outlined,
                    label: 'Forum Diskusi',
                    color: Colors.teal,
                    onTap: () => context.push('/forum'),
                  ),
                  _MenuCard(
                    icon: Icons.psychology_outlined,
                    label: 'Konseling BK',
                    color: Colors.brown,
                    onTap: () => _showBookingBK(context, user.uid),
                  ),
                  _MenuCard(
                    icon: Icons.warning_amber_outlined,
                    label: 'Pelanggaran',
                    color: Colors.deepOrange,
                    onTap: () => context.push('/violations/${user.uid}'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Recent Assignments
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tugas Terbaru',
                      style: Theme.of(context).textTheme.titleMedium),
                  TextButton(
                    onPressed: () => context.push('/student/assignments'),
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              StreamBuilder<List<AssignmentModel>>(
                stream: db.getAssignments(classId: user.classId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final assignments = snapshot.data!.take(3).toList();
                  if (assignments.isEmpty) {
                    return const _EmptyState(
                      message: 'Belum ada tugas',
                    );
                  }
                  return Column(
                    children: assignments
                        .map((a) => _AssignmentCard(assignment: a))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Recent Materials
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Materi Terbaru',
                      style: Theme.of(context).textTheme.titleMedium),
                  TextButton(
                    onPressed: () => context.push('/student/materials'),
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              StreamBuilder<List<MaterialModel>>(
                stream: db.getMaterials(classId: user.classId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final materials = snapshot.data!.take(3).toList();
                  if (materials.isEmpty) {
                    return const _EmptyState(message: 'Belum ada materi');
                  }
                  return Column(
                    children: materials
                        .map((m) => _MaterialCard(material: m))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingBK(BuildContext context, String studentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BookBKSheet(studentId: studentId),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final isExpired = assignment.isExpired;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isExpired
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            assignment.type == 'kuis'
                ? Icons.quiz_outlined
                : Icons.assignment_outlined,
            color: isExpired ? Colors.red : Colors.orange,
          ),
        ),
        title: Text(assignment.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${assignment.subject} • Deadline: '
            '${_formatDate(assignment.deadline)}'),
        trailing: Chip(
          label: Text(isExpired ? 'Terlambat' : 'Aktif',
              style: const TextStyle(fontSize: 11, color: Colors.white)),
          backgroundColor: isExpired ? Colors.red : Colors.green,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _MaterialCard extends StatelessWidget {
  final MaterialModel material;
  const _MaterialCard({required this.material});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            material.type == 'video'
                ? Icons.play_circle_outline
                : Icons.picture_as_pdf_outlined,
            color: Colors.blue,
          ),
        ),
        title: Text(material.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${material.subject} • ${material.teacherName}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}

class _BookBKSheet extends StatefulWidget {
  final String studentId;
  const _BookBKSheet({required this.studentId});

  @override
  State<_BookBKSheet> createState() => _BookBKSheetState();
}

class _BookBKSheetState extends State<_BookBKSheet> {
  final _descController = TextEditingController();
  String _selectedCategory = 'Pribadi';
  bool _loading = false;

  final _categories = ['Akademik', 'Sosial', 'Pribadi', 'Karir', 'Pelanggaran'];

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().userModel!;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Booking Sesi Konseling BK',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Kategori Masalah'),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Deskripsi Singkat',
              hintText: 'Ceritakan masalah Anda secara singkat...',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading
                ? null
                : () async {
                    setState(() => _loading = true);
                    try {
                      final db = FirestoreService();
                      await db.addCounseling(
                        CounselingModel(
                          id: '',
                          studentId: widget.studentId,
                          studentName: user.name,
                          bkId: '',
                          bkName: '',
                          category: _selectedCategory,
                          description: _descController.text,
                          status: 'pending',
                          createdAt: DateTime.now(),
                        ),
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Permohonan konseling berhasil dikirim'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  },
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Kirim Permohonan'),
          ),
        ],
      ),
    );
  }
}
