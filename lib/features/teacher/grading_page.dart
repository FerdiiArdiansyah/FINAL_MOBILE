import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/assignment_model.dart';
import '../../core/theme/app_theme.dart';

class GradingPage extends StatelessWidget {
  final String assignmentId;
  const GradingPage({super.key, required this.assignmentId});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Penilaian Tugas')),
      body: StreamBuilder<List<SubmissionModel>>(
        stream: db.getSubmissions(assignmentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final submissions = snapshot.data ?? [];
          if (submissions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada yang mengumpulkan',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: submissions.length,
            itemBuilder: (context, i) {
              return _SubmissionCard(
                submission: submissions[i],
                assignmentId: assignmentId,
              );
            },
          );
        },
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final SubmissionModel submission;
  final String assignmentId;

  const _SubmissionCard({
    required this.submission,
    required this.assignmentId,
  });

  @override
  Widget build(BuildContext context) {
    final isGraded = submission.status == 'graded';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(submission.studentName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      Text(
                        'Dikumpulkan: ${_fmt(submission.submittedAt)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    isGraded
                        ? 'Nilai: ${submission.score}'
                        : 'Belum dinilai',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11),
                  ),
                  backgroundColor: isGraded
                      ? AppTheme.successColor
                      : AppTheme.warningColor,
                ),
              ],
            ),
            if (submission.feedback != null) ...[
              const SizedBox(height: 8),
              Text('Feedback: ${submission.feedback}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit, size: 16),
              label: Text(isGraded ? 'Ubah Nilai' : 'Beri Nilai'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                textStyle: const TextStyle(fontSize: 13),
              ),
              onPressed: () => _showGradeDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showGradeDialog(BuildContext context) {
    final scoreController = TextEditingController(
      text: submission.score?.toString() ?? '',
    );
    final feedbackController = TextEditingController(
      text: submission.feedback ?? '',
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Nilai: ${submission.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: scoreController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nilai (0-100)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Feedback (opsional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final score =
                  int.tryParse(scoreController.text) ?? 0;
              final db = FirestoreService();
              await db.gradeSubmission(
                assignmentId,
                submission.studentId,
                score,
                feedbackController.text.isEmpty
                    ? null
                    : feedbackController.text,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nilai berhasil disimpan'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, "0")}';
}
