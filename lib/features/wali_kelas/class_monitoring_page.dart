import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/user_model.dart';
import '../../core/models/attendance_model.dart';
import '../../core/theme/app_theme.dart';

class ClassMonitoringPage extends StatelessWidget {
  const ClassMonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;
    final db = FirestoreService();
    if (user.classId == null) {
      return const Scaffold(
        body: Center(child: Text('Tidak ada kelas perwalian')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Monitoring Kelas ${user.className ?? ""}')),
      body: StreamBuilder<List<UserModel>>(
        stream: db.getStudentsByClass(user.classId!),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final students = snap.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, i) {
              return _StudentMonitorCard(
                student: students[i],
                classId: user.classId!,
              );
            },
          );
        },
      ),
    );
  }
}

class _StudentMonitorCard extends StatelessWidget {
  final UserModel student;
  final String classId;

  const _StudentMonitorCard({
    required this.student,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Text(student.name[0].toUpperCase()),
        ),
        title: Text(student.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('NISN: ${student.nisn ?? "-"}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: StreamBuilder<List<AttendanceModel>>(
              stream: db.getAttendanceByStudent(student.uid),
              builder: (context, snap) {
                final list = snap.data ?? [];
                final hadir =
                    list.where((a) => a.status == 'hadir').length;
                final alpha =
                    list.where((a) => a.status == 'alpha').length;
                final total = list.length;
                final persen = total > 0
                    ? (hadir / total * 100).toStringAsFixed(1)
                    : '0';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _InfoChip(
                            'Hadir', hadir.toString(), AppTheme.successColor),
                        _InfoChip(
                            'Alpha', alpha.toString(), AppTheme.errorColor),
                        _InfoChip('Total Hadir', '$persen%',
                            alpha > 3 ? AppTheme.warningColor : AppTheme.successColor),
                      ],
                    ),
                    if (alpha > 3) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning,
                                color: AppTheme.errorColor, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'ALERT: Alpha $alpha kali melebihi batas!',
                              style: const TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.warning_amber, size: 16),
                          label: const Text('Pelanggaran'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () => context
                              .push('/violations/${student.uid}'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.chat, size: 16),
                          label: const Text('Chat'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            )),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
