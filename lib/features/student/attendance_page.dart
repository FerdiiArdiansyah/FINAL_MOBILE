import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/attendance_model.dart';
import '../../core/theme/app_theme.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;
    final db = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Rekap Absensi')),
      body: StreamBuilder<List<AttendanceModel>>(
        stream: db.getAttendanceByStudent(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          final hadir = list.where((a) => a.status == 'hadir').length;
          final izin = list.where((a) => a.status == 'izin').length;
          final sakit = list.where((a) => a.status == 'sakit').length;
          final alpha = list.where((a) => a.status == 'alpha').length;
          final total = list.length;

          return Column(
            children: [
              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.primaryColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatChip('Hadir', hadir, Colors.green),
                    _StatChip('Izin', izin, Colors.blue),
                    _StatChip('Sakit', sakit, Colors.orange),
                    _StatChip('Alpha', alpha, Colors.red),
                  ],
                ),
              ),
              if (total > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Text('Persentase Kehadiran: '),
                      Text(
                        '${(hadir / total * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (hadir / total) >= 0.75
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                ),
              // List
              Expanded(
                child: list.isEmpty
                    ? const Center(
                        child: Text('Belum ada data absensi',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final a = list[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _statusColor(a.status)
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _statusIcon(a.status),
                                  color: _statusColor(a.status),
                                ),
                              ),
                              title: Text(
                                a.subject ?? 'Piket',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${_formatDate(a.date)} • ${a.recordType == "piket" ? "Piket" : "Jam ke-${a.session ?? "-"}"}',
                              ),
                              trailing: Chip(
                                label: Text(
                                  _statusLabel(a.status),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11),
                                ),
                                backgroundColor:
                                    _statusColor(a.status),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'hadir': return AppTheme.successColor;
      case 'izin': return AppTheme.secondaryColor;
      case 'sakit': return AppTheme.warningColor;
      case 'alpha': return AppTheme.errorColor;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'hadir': return Icons.check_circle_outline;
      case 'izin': return Icons.description_outlined;
      case 'sakit': return Icons.local_hospital_outlined;
      case 'alpha': return Icons.cancel_outlined;
      default: return Icons.help_outline;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'hadir': return 'Hadir';
      case 'izin': return 'Izin';
      case 'sakit': return 'Sakit';
      case 'alpha': return 'Alpha';
      default: return status;
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
