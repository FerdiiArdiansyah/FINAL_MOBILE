import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
  final MobileScannerController _scanController = MobileScannerController();
  bool _scanned = false;
  String _lastScanned = '';
  final _nisnController = TextEditingController();

  @override
  void dispose() {
    _scanController.dispose();
    _nisnController.dispose();
    super.dispose();
  }

  Future<void> _processCode(String code) async {
    if (_scanned || code == _lastScanned) return;
    setState(() {
      _scanned = true;
      _lastScanned = code;
    });

    // Find student by NISN or UID
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

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _scanned = false);
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
    _showResult(true, '${student.name} - Absensi tercatat HADIR');
  }

  void _showResult(bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            success ? AppTheme.successColor : AppTheme.errorColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _manualInput() async {
    if (_nisnController.text.isEmpty) return;
    await _processCode(_nisnController.text.trim());
    _nisnController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Absensi QR / NISN')),
      body: Column(
        children: [
          // Scanner
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scanController,
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final code = barcodes.first.rawValue ?? '';
                      if (code.isNotEmpty) _processCode(code);
                    }
                  },
                ),
                // Overlay
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Arahkan kamera ke QR Code kartu pelajar',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // Manual input
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Atau input NISN manual:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nisnController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'NISN',
                            hintText: '0012345678',
                          ),
                          onSubmitted: (_) => _manualInput(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _manualInput,
                        child: const Text('Catat'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.flash_on),
                          label: const Text('Flash'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey),
                          onPressed: () =>
                              _scanController.toggleTorch(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.flip_camera_ios),
                          label: const Text('Flip'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey),
                          onPressed: () =>
                              _scanController.switchCamera(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
