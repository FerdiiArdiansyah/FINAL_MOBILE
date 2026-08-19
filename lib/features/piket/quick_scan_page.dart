import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/attendance_model.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';

class QuickScanPage extends StatefulWidget {
  const QuickScanPage({super.key});

  @override
  State<QuickScanPage> createState() => _QuickScanPageState();
}

class _QuickScanPageState extends State<QuickScanPage> {
  final _nisnController = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _recentScans = [];

  @override
  void dispose() {
    _nisnController.dispose();
    super.dispose();
  }

  Future<void> _processCode(String code) async {
    if (code.isEmpty || _loading) return;
    setState(() => _loading = true);

    final db = FirestoreService();
    final users = await db.getAllUsers();
    final student = users.firstWhere(
      (u) => u.nisn == code || u.uid == code,
      orElse: () => UserModel(
        uid: '',
        email: '',
        name: '',
        role: '',
        createdAt: DateTime.now(),
      ),
    );

    if (!mounted) return;

    if (student.uid.isEmpty) {
      _showResult(false, 'Siswa tidak ditemukan: $code');
    } else {
      await _recordAttendance(student);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _recordAttendance(UserModel student) async {
    final user = context.read<AuthProvider>().userModel!;
    final db = FirestoreService();
    await db.addAttendance(
      AttendanceModel(
        id: '',
        studentId: student.uid,
        studentName: student.name,
        classId: student.classId ?? '',
        status: 'hadir',
        date: DateTime.now(),
        recordedBy: user.uid,
        recordType: 'piket',
      ),
    );
    setState(() {
      _recentScans.insert(0, {
        'name': student.name,
        'time': DateTime.now(),
        'success': true,
      });
      if (_recentScans.length > 10) _recentScans.removeLast();
    });
    _showResult(true, '${student.name} â€” Absensi tercatat HADIR');
  }

  void _showResult(bool success, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.error,
                color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submit() async {
    final code = _nisnController.text.trim();
    if (code.isEmpty) return;
    _nisnController.clear();
    await _processCode(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Absensi Gerbang')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.qr_code_scanner,
                      color: AppTheme.primaryColor, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Absensi Gerbang',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor)),
                        Text(
                          'Masukkan NISN siswa untuk mencatat kehadiran.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // NISN Input
            TextField(
              controller: _nisnController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'NISN Siswa',
                hintText: 'Contoh: 0012345678',
                prefixIcon: const Icon(Icons.badge_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _nisnController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _nisnController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.how_to_reg),
              label: const Text('Catat Hadir'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: _loading ? null : _submit,
            ),

            const SizedBox(height: 24),

            // Recent scans
            if (_recentScans.isNotEmpty) ...[
              Text('Absensi Tercatat Hari Ini',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _recentScans.length,
                  itemBuilder: (context, i) {
                    final s = _recentScans[i];
                    final t = s['time'] as DateTime;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.successColor,
                          radius: 16,
                          child:
                              Icon(Icons.check, color: Colors.white, size: 16),
                        ),
                        title: Text(s['name'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        trailing: Text(
                          '${t.hour.toString().padLeft(2, "0")}:'
                          '${t.minute.toString().padLeft(2, "0")}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.how_to_reg_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Belum ada absensi hari ini',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
