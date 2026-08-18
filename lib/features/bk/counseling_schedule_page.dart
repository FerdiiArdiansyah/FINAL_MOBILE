import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/counseling_model.dart';
import '../../core/theme/app_theme.dart';

class CounselingSchedulePage extends StatelessWidget {
  const CounselingSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;
    final db = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Konseling')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSlotDialog(context, user.uid, user.name),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<CounselingModel>>(
        stream: db.getCounselingCases(bkId: user.uid, status: 'scheduled'),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final scheduled = snap.data ?? [];
          if (scheduled.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada jadwal konseling',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scheduled.length,
            itemBuilder: (context, i) {
              final c = scheduled[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.accentColor,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(c.studentName,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kategori: ${c.category}'),
                      if (c.scheduledAt != null)
                        Text(
                          'Jadwal: ${_fmt(c.scheduledAt!)}',
                          style: const TextStyle(
                              color: AppTheme.secondaryColor,
                              fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      await db.updateCounselingStatus(
                        c.id,
                        v,
                        notes: v == 'ongoing'
                            ? 'Sesi dimulai oleh ${user.name}'
                            : null,
                      );
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'ongoing', child: Text('Mulai Sesi')),
                      const PopupMenuItem(
                          value: 'resolved', child: Text('Tandai Selesai')),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddSlotDialog(
      BuildContext context, String bkId, String bkName) {
    DateTime selectedDate = DateTime.now();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Jadwal Sesi Konseling'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(_fmt(selectedDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
                  }
                },
              ),
              const Text(
                'Catatan: Siswa akan menerima notifikasi jadwal konseling.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}';
}
