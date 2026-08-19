import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/counseling_model.dart';
import '../../core/theme/app_theme.dart';

class BkDashboardPage extends StatelessWidget {
  const BkDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;
    final db = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Guru BK'),
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
            Card(
              color: AppTheme.primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      child:
                          Icon(Icons.psychology, color: AppTheme.primaryColor),
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
                          const Text('Guru Bimbingan Konseling',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            StreamBuilder<List<CounselingModel>>(
              stream: db.getCounselingCases(bkId: user.uid),
              builder: (context, snap) {
                final cases = snap.data ?? [];
                final pending =
                    cases.where((c) => c.status == 'pending').length;
                final ongoing =
                    cases.where((c) => c.status == 'ongoing').length;
                final resolved =
                    cases.where((c) => c.status == 'resolved').length;
                return Row(
                  children: [
                    Expanded(
                        child: _StatCard(
                            'Pending', pending, AppTheme.warningColor)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _StatCard(
                            'Ongoing', ongoing, AppTheme.secondaryColor)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _StatCard(
                            'Resolved', resolved, AppTheme.successColor)),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.list_alt_outlined,
                    label: 'Semua Kasus',
                    color: Colors.blue,
                    onTap: () => context.push('/bk/cases'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.calendar_today_outlined,
                    label: 'Jadwal Konseling',
                    color: Colors.green,
                    onTap: () => context.push('/bk/schedule'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pending cases
            Text('Permohonan Menunggu',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            StreamBuilder<List<CounselingModel>>(
              stream: db.getCounselingCases(status: 'pending'),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final pending = snap.data!;
                if (pending.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child:
                          Center(child: Text('Tidak ada permohonan pending')),
                    ),
                  );
                }
                return Column(
                  children: pending.take(5).map((c) {
                    return _CounselingCard(
                      counseling: c,
                      bkId: user.uid,
                      bkName: user.name,
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
                    fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CounselingCard extends StatelessWidget {
  final CounselingModel counseling;
  final String bkId;
  final String bkName;

  const _CounselingCard({
    required this.counseling,
    required this.bkId,
    required this.bkName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.psychology_outlined, color: Colors.orange),
        ),
        title: Text(counseling.studentName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle:
            Text('${counseling.category} • ${_fmt(counseling.createdAt)}'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'scheduled') {
              _showScheduleDateDialog(context, counseling, bkName);
            } else {
              final db = FirestoreService();
              await db.updateCounselingStatus(
                counseling.id,
                v,
                notes: v == 'ongoing' ? 'Ditangani oleh $bkName' : null,
              );
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'scheduled', child: Text('Jadwalkan')),
            const PopupMenuItem(value: 'ongoing', child: Text('Tangani')),
            const PopupMenuItem(value: 'resolved', child: Text('Selesai')),
          ],
          child: const Icon(Icons.more_vert),
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void _showScheduleDateDialog(
      BuildContext context, CounselingModel counseling, String bkName) {
    DateTime selected = DateTime.now().add(const Duration(hours: 1));
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Jadwalkan — ${counseling.studentName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today,
                    color: AppTheme.primaryColor),
                title: Text(
                    '${selected.day}/${selected.month}/${selected.year} '
                    '${selected.hour.toString().padLeft(2, "0")}:'
                    '${selected.minute.toString().padLeft(2, "0")}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: selected,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null && ctx.mounted) {
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(selected),
                    );
                    if (time != null) {
                      setState(() => selected = DateTime(date.year, date.month,
                          date.day, time.hour, time.minute));
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final db = FirestoreService();
                await db.updateCounselingStatus(
                  counseling.id,
                  'scheduled',
                  scheduledAt: selected,
                  notes: 'Dijadwalkan oleh $bkName',
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Konfirmasi'),
            ),
          ],
        ),
      ),
    );
  }
}
