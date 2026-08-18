import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/user_model.dart';
import '../../core/models/attendance_model.dart';
import '../../core/theme/app_theme.dart';

class AttendanceInputPage extends StatefulWidget {
  const AttendanceInputPage({super.key});

  @override
  State<AttendanceInputPage> createState() =>
      _AttendanceInputPageState();
}

class _AttendanceInputPageState extends State<AttendanceInputPage> {
  final _classController = TextEditingController();
  final _subjectController = TextEditingController();
  final _sessionController = TextEditingController(text: '1');
  final Map<String, String> _statusMap = {};
  List<UserModel> _students = [];
  bool _loaded = false;
  bool _saving = false;

  Future<void> _loadStudents() async {
    final db = FirestoreService();
    final students = await db
        .getAllUsers()
        .then((list) => list
            .where((u) =>
                u.role == 'SISWA' &&
                u.classId == _classController.text.trim())
            .toList());
    setState(() {
      _students = students;
      _loaded = true;
      for (final s in students) {
        _statusMap[s.uid] = 'hadir';
      }
    });
  }

  Future<void> _saveAttendance() async {
    if (_students.isEmpty) return;
    setState(() => _saving = true);
    try {
      final user = context.read<AuthProvider>().userModel!;
      final db = FirestoreService();
      final attendances = _students.map((s) {
        return AttendanceModel(
          id: '',
          studentId: s.uid,
          studentName: s.name,
          classId: _classController.text.trim(),
          subject: _subjectController.text.trim(),
          teacherId: user.uid,
          status: _statusMap[s.uid] ?? 'hadir',
          date: DateTime.now(),
          session: _sessionController.text.trim(),
          recordedBy: user.uid,
          recordType: 'mapel',
        );
      }).toList();
      await db.addBatchAttendance(attendances);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Absensi berhasil disimpan'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'),
              backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Absensi'),
        actions: [
          if (_loaded && _students.isNotEmpty)
            TextButton(
              onPressed: _saving ? null : _saveAttendance,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Simpan',
                      style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Input fields
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _classController,
                        decoration: const InputDecoration(
                          labelText: 'ID Kelas',
                          hintText: 'X-TKJ-1',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _sessionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jam Ke-',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Mata Pelajaran',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _loadStudents,
                      child: const Text('Muat Siswa'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          // Student list
          Expanded(
            child: !_loaded
                ? const Center(
                    child: Text(
                      'Masukkan kelas dan tekan "Muat Siswa"',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : _students.isEmpty
                    ? const Center(
                        child: Text('Tidak ada siswa di kelas ini',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _students.length,
                        itemBuilder: (context, i) {
                          final s = _students[i];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text('${i + 1}'),
                            ),
                            title: Text(s.name),
                            subtitle: Text('NISN: ${s.nisn ?? "-"}'),
                            trailing: _StatusSelector(
                              value: _statusMap[s.uid] ?? 'hadir',
                              onChanged: (v) => setState(
                                  () => _statusMap[s.uid] = v),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StatusSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = ['hadir', 'izin', 'sakit', 'alpha'];
    final colors = {
      'hadir': Colors.green,
      'izin': Colors.blue,
      'sakit': Colors.orange,
      'alpha': Colors.red,
    };
    return DropdownButton<String>(
      value: value,
      underline: const SizedBox(),
      items: statuses
          .map((s) => DropdownMenuItem(
                value: s,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors[s]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s[0].toUpperCase() + s.substring(1),
                    style: TextStyle(
                      color: colors[s],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ))
          .toList(),
      onChanged: (v) => onChanged(v!),
    );
  }
}
