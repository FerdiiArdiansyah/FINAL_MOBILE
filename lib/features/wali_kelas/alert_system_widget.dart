import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/user_model.dart';
import '../../core/models/violation_model.dart';
import '../../core/theme/app_theme.dart';

class AlertSystemWidget extends StatelessWidget {
  final String classId;
  const AlertSystemWidget({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    return StreamBuilder<List<UserModel>>(
      stream: db.getStudentsByClass(classId),
      builder: (context, studentSnap) {
        if (!studentSnap.hasData || studentSnap.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final students = studentSnap.data!;
        return StreamBuilder<List<ViolationModel>>(
          stream: db.getViolationsByClass(classId),
          builder: (context, violationSnap) {
            final violations = violationSnap.data ?? [];
            final alerts = <_AlertItem>[];

            // Check alpha > 3 in current month
            // We'll check violations for high point students
            final pointsByStudent = <String, int>{};
            for (final v in violations) {
              pointsByStudent[v.studentId] =
                  (pointsByStudent[v.studentId] ?? 0) + v.points;
            }

            for (final s in students) {
              final points = pointsByStudent[s.uid] ?? 0;
              if (points >= 80) {
                alerts.add(_AlertItem(
                  studentName: s.name,
                  type: 'violation',
                  message: 'Poin pelanggaran mendekati batas ($points/100)',
                  color: AppTheme.errorColor,
                ));
              } else if (points >= 60) {
                alerts.add(_AlertItem(
                  studentName: s.name,
                  type: 'violation',
                  message: 'Poin pelanggaran tinggi ($points poin)',
                  color: AppTheme.warningColor,
                ));
              }
            }

            if (alerts.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: AppTheme.successColor),
                      SizedBox(width: 8),
                      Text('Tidak ada alert saat ini',
                          style: TextStyle(color: AppTheme.successColor)),
                    ],
                  ),
                ),
              );
            }

            return Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            color: AppTheme.warningColor),
                        const SizedBox(width: 8),
                        Text(
                          '${alerts.length} Alert Aktif',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...alerts.take(5).map(
                    (a) => ListTile(
                      dense: true,
                      leading: Icon(
                        a.type == 'alpha'
                            ? Icons.cancel_outlined
                            : Icons.warning_amber_outlined,
                        color: a.color,
                        size: 20,
                      ),
                      title: Text(a.studentName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      subtitle:
                          Text(a.message, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AlertItem {
  final String studentName;
  final String type;
  final String message;
  final Color color;

  const _AlertItem({
    required this.studentName,
    required this.type,
    required this.message,
    required this.color,
  });
}
