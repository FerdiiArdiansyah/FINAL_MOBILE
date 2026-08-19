import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

class DailyLogPage extends StatefulWidget {
  const DailyLogPage({super.key});

  @override
  State<DailyLogPage> createState() => _DailyLogPageState();
}

class _DailyLogPageState extends State<DailyLogPage> {
  final _studentNameController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedType = 'terlambat';

  final _types = {
    'terlambat': 'Keterlambatan',
    'izin_pulang': 'Izin Pulang',
    'kejadian': 'Kejadian Khusus',
  };

  @override
  void dispose() {
    _studentNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addLog() async {
    if (_studentNameController.text.isEmpty || _noteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi semua field yang diperlukan')),
      );
      return;
    }
    final user = context.read<AuthProvider>().userModel!;
    final db = FirestoreService();
    await db.addPiketLog({
      'studentName': _studentNameController.text.trim(),
      'type': _selectedType,
      'note': _noteController.text.trim(),
      'recordedBy': user.uid,
      'recordedByName': user.name,
      'date': DateTime.now(),
    });
    _studentNameController.clear();
    _noteController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan berhasil disimpan'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Buku Piket Digital')),
      body: Column(
        children: [
          // Add log form
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Tambah Catatan',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _studentNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Siswa',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedType,
                      items: _types.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedType = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addLog,
                      child: const Text('Catat'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Log list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: db.getPiketLogs(DateTime.now()),
              builder: (context, snap) {
                final logs = snap.data ?? [];
                if (logs.isEmpty) {
                  return const Center(
                    child: Text('Belum ada catatan hari ini',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, i) {
                    final log = logs[i];
                    final type = log['type'] as String? ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _typeColor(type).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_typeIcon(type),
                              color: _typeColor(type)),
                        ),
                        title: Text(
                          log['studentName'] as String? ?? '-',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_types[type] ?? type),
                            Text(
                              log['note'] as String? ?? '',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          _timeStr(log['date']),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
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

  Color _typeColor(String type) {
    switch (type) {
      case 'terlambat': return AppTheme.warningColor;
      case 'izin_pulang': return AppTheme.secondaryColor;
      case 'kejadian': return AppTheme.errorColor;
      default: return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'terlambat': return Icons.access_time;
      case 'izin_pulang': return Icons.exit_to_app;
      case 'kejadian': return Icons.report_outlined;
      default: return Icons.note_outlined;
    }
  }

  String _timeStr(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else {
      date = timestamp.toDate() as DateTime;
    }
    return '${date.hour.toString().padLeft(2, "0")}:${date.minute.toString().padLeft(2, "0")}';
  }
}
