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
                      style: const TextStyle(fontWeight: FontWeight.bold)),
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

  void _showAddSlotDialog(BuildContext context, String bkId, String bkName) {
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    CounselingModel? selectedCase;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          final db = FirestoreService();
          return AlertDialog(
            title: const Text('Jadwalkan Sesi Konseling'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder<List<CounselingModel>>(
                      stream: db.getCounselingCases(status: 'pending'),
                      builder: (context, snap) {
                        final cases = snap.data ?? [];
                        if (cases.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Tidak ada permohonan pending saat ini.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                        return DropdownButtonFormField<CounselingModel>(
                          initialValue: selectedCase,
                          hint: const Text('Pilih siswa'),
                          decoration: const InputDecoration(
                              labelText: 'Permohonan Konseling *'),
                          isExpanded: true,
                          items: cases
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      '${c.studentName} — ${c.category}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => selectedCase = v),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Tanggal & Waktu Sesi',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today,
                          color: AppTheme.primaryColor),
                      title: Text(_fmt(selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 90)),
                        );
                        if (date != null && ctx.mounted) {
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(selectedDate),
                          );
                          if (time != null) {
                            setState(() => selectedDate = DateTime(date.year,
                                date.month, date.day, time.hour, time.minute));
                          }
                        }
                      },
                    ),
                    const Text(
                      'Siswa akan menerima notifikasi jadwal konseling.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: selectedCase == null
                    ? null
                    : () async {
                        await db.updateCounselingStatus(
                          selectedCase!.id,
                          'scheduled',
                          scheduledAt: selectedDate,
                          notes: 'Dijadwalkan oleh $bkName',
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Jadwal konseling berhasil dibuat'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        }
                      },
                child: const Text('Konfirmasi'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}';
}
