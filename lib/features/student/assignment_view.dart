import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/assignment_model.dart';
import '../../core/theme/app_theme.dart';

class AssignmentView extends StatelessWidget {
  const AssignmentView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;
    final db = FirestoreService();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tugas & Kuis'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tugas'),
              Tab(text: 'Kuis'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _AssignmentList(
              stream: db.getAssignments(classId: user.classId),
              type: 'tugas',
              studentId: user.uid,
            ),
            _AssignmentList(
              stream: db.getAssignments(classId: user.classId),
              type: 'kuis',
              studentId: user.uid,
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentList extends StatelessWidget {
  final Stream<List<AssignmentModel>> stream;
  final String type;
  final String studentId;

  const _AssignmentList({
    required this.stream,
    required this.type,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AssignmentModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final assignments = (snapshot.data ?? [])
            .where((a) => a.type == type)
            .toList();
        if (assignments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type == 'kuis'
                      ? Icons.quiz_outlined
                      : Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 12),
                Text(
                  'Belum ada ${type == "kuis" ? "kuis" : "tugas"}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, i) {
            return _AssignmentCard(
              assignment: assignments[i],
              studentId: studentId,
            );
          },
        );
      },
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final String studentId;

  const _AssignmentCard({
    required this.assignment,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: assignment.isExpired
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            assignment.type == 'kuis'
                ? Icons.quiz_outlined
                : Icons.assignment_outlined,
            color: assignment.isExpired ? Colors.red : Colors.orange,
          ),
        ),
        title: Text(
          assignment.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${assignment.subject} • '
          'Deadline: ${_formatDate(assignment.deadline)}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(assignment.description),
                const SizedBox(height: 8),
                Text('Guru: ${assignment.teacherName}'),
                Text('Nilai Maks: ${assignment.maxScore}'),
                const SizedBox(height: 12),
                FutureBuilder<SubmissionModel?>(
                  future: db.getSubmission(assignment.id, studentId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const LinearProgressIndicator();
                    }
                    final submission = snap.data;
                    if (submission != null) {
                      return _SubmissionStatus(submission: submission);
                    }
                    if (assignment.isExpired) {
                      return const Chip(
                        label: Text(
                          'Terlambat mengumpulkan',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      );
                    }
                    return ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Kumpulkan'),
                      onPressed: () =>
                          _showSubmitDialog(context, assignment),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmitDialog(BuildContext context, AssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (_) =>
          _SubmitDialog(assignment: assignment, studentId: studentId),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}

class _SubmissionStatus extends StatelessWidget {
  final SubmissionModel submission;
  const _SubmissionStatus({required this.submission});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Chip(
          label: Text(
            submission.status == 'graded'
                ? 'Dinilai: ${submission.score}'
                : 'Sudah dikumpulkan',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          backgroundColor: submission.status == 'graded'
              ? AppTheme.successColor
              : AppTheme.secondaryColor,
        ),
        if (submission.feedback != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Feedback: ${submission.feedback}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ],
    );
  }
}

class _SubmitDialog extends StatefulWidget {
  final AssignmentModel assignment;
  final String studentId;

  const _SubmitDialog({
    required this.assignment,
    required this.studentId,
  });

  @override
  State<_SubmitDialog> createState() => _SubmitDialogState();
}

class _SubmitDialogState extends State<_SubmitDialog> {
  final _noteController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().userModel!;
    return AlertDialog(
      title: Text('Kumpulkan: ${widget.assignment.title}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Catatan: Upload file melalui fitur ini '
            'akan disimpan ke Firebase Storage.',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            decoration:
                const InputDecoration(labelText: 'Catatan (opsional)'),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  try {
                    final db = FirestoreService();
                    await db.submitAssignment(
                      widget.assignment.id,
                      SubmissionModel(
                        id: user.uid,
                        studentId: user.uid,
                        studentName: user.name,
                        assignmentId: widget.assignment.id,
                        status: 'submitted',
                        submittedAt: DateTime.now(),
                      ),
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tugas berhasil dikumpulkan'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: _loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Kumpulkan'),
        ),
      ],
    );
  }
}
