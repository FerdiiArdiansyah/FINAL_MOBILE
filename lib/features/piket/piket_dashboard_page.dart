import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/user_model.dart';
import '../../core/models/attendance_model.dart';
import '../../core/models/violation_model.dart';
import '../../core/models/notification_model.dart';
import '../../core/theme/app_theme.dart';

class PiketDashboardPage extends StatelessWidget {
  const PiketDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;
    final db = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Guru Piket'),
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
            // Greeting + Date
            Card(
              color: AppTheme.primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.school, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Halo, ${user.name}!',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(
                            'Guru Piket • ${_formatDate(DateTime.now())}',
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

            // Quick Actions
            Text('Aksi Cepat',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan QR Absensi',
                    color: Colors.blue,
                    onTap: () => context.push('/piket/scan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.book_outlined,
                    label: 'Buku Piket',
                    color: Colors.orange,
                    onTap: () => context.push('/piket/log'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Catat Pelanggaran — Guru Piket (Input)
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.gavel_outlined,
                    label: 'Catat Pelanggaran',
                    color: Colors.deepOrange,
                    onTap: () => _showViolationInputDialog(context, user),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.notifications_outlined,
                    label: 'Notifikasi',
                    color: Colors.purple,
                    onTap: () => context.push('/notifications'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Broadcast Urgency
            InkWell(
              onTap: () => _showBroadcastDialog(context, user),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.campaign, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Broadcast Pengumuman Darurat',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Today's attendance at gate
            Text("Absensi Gerbang Hari Ini",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            StreamBuilder<List<AttendanceModel>>(
              stream: db.getAttendanceByClass('ALL', DateTime.now()),
              builder: (context, snap) {
                final list = (snap.data ?? [])
                    .where((a) => a.recordType == 'piket')
                    .toList();
                final hadir =
                    list.where((a) => a.status == 'hadir').length;
                final terlambat =
                    list.where((a) => a.status == 'izin').length;
                final alpha =
                    list.where((a) => a.status == 'alpha').length;
                return Row(
                  children: [
                    Expanded(
                        child: _StatCard(
                            'Hadir', hadir, AppTheme.successColor)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _StatCard(
                            'Terlambat', terlambat, AppTheme.warningColor)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _StatCard(
                            'Alpha', alpha, AppTheme.errorColor)),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Piket log today
            Text('Log Piket Hari Ini',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: db.getPiketLogs(DateTime.now()),
              builder: (context, snap) {
                final logs = snap.data ?? [];
                if (logs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Belum ada catatan hari ini',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }
                return Column(
                  children: logs.take(5).map((log) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          _logIcon(log['type'] as String? ?? ''),
                          color: AppTheme.secondaryColor,
                        ),
                        title: Text(log['studentName'] as String? ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        subtitle:
                            Text(log['note'] as String? ?? ''),
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

  IconData _logIcon(String type) {
    switch (type) {
      case 'terlambat': return Icons.access_time;
      case 'izin_pulang': return Icons.exit_to_app;
      case 'kejadian': return Icons.report_outlined;
      default: return Icons.note_outlined;
    }
  }

  String _formatDate(DateTime d) {
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return '${days[d.weekday - 1]}, ${d.day}/${d.month}/${d.year}';
  }

  void _showViolationInputDialog(BuildContext context, UserModel user) {
    final nisnCtrl = TextEditingController();
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
              Text('Catat Pelanggaran'),
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
                        decoration: const InputDecoration(labelText: 'Cari Nama / NISN'),
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
                          setState(() => foundStudent = match.first);
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
                      content: Text('Pelanggaran berhasil dicatat'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context, UserModel user) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.campaign, color: Colors.red),
            SizedBox(width: 8),
            Text('Broadcast Darurat'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pengumuman ini akan dikirim ke semua warga sekolah via Push Notification.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Isi Pengumuman Darurat',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () async {
              if (ctrl.text.isEmpty) return;
              final db = FirestoreService();
              await db.addAnnouncement(
                AnnouncementModel(
                  id: '',
                  title: 'PENGUMUMAN DARURAT',
                  content: ctrl.text,
                  authorId: user.uid,
                  authorName: user.name,
                  priority: 'urgent',
                  createdAt: DateTime.now(),
                ),
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Broadcast berhasil dikirim!'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Kirim Sekarang'),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatCard(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(count.toString(),
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
