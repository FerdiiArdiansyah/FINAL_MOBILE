import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/assignment_model.dart';
import '../../core/theme/app_theme.dart';

class GradesPage extends StatelessWidget {
  const GradesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;
    final db = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Rekap Nilai')),
      body: StreamBuilder<List<AssignmentModel>>(
        stream: db.getAssignments(classId: user.classId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final assignments = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: assignments.length,
            itemBuilder: (context, i) {
              return _GradeCard(
                assignment: assignments[i],
                studentId: user.uid,
              );
            },
          );
        },
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  final AssignmentModel assignment;
  final String studentId;

  const _GradeCard({required this.assignment, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: FutureBuilder<SubmissionModel?>(
        future: db.getSubmission(assignment.id, studentId),
        builder: (context, snap) {
          final submission = snap.data;
          final score = submission?.score;
          Color scoreColor = Colors.grey;
          if (score != null) {
            if (score >= 80) {
              scoreColor = AppTheme.successColor;
            } else if (score >= 60) scoreColor = AppTheme.warningColor;
            else scoreColor = AppTheme.errorColor;
          }
          return ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  score?.toString() ?? '-',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            title: Text(assignment.title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${assignment.subject} • ${assignment.type}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Maks: ${assignment.maxScore}',
                    style: const TextStyle(fontSize: 11)),
                if (submission?.status == 'graded')
                  Text(
                    '${((score ?? 0) / assignment.maxScore * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  )
                else
                  Text(
                    submission == null ? 'Belum dikumpulkan' : 'Menunggu penilaian',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
