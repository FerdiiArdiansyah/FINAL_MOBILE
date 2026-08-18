import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/assignment_model.dart';
import '../../core/theme/app_theme.dart';

class TeacherStatsPage extends StatelessWidget {
  const TeacherStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;
    final db = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik Mengajar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary stats
            FutureBuilder<Map<String, dynamic>>(
              future: db.getTeacherStats(user.uid),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final stats = snap.data!;
                return Column(
                  children: [
                    Row(
                      children: [
                        _StatBox(
                          label: 'Total Tugas',
                          value: '${stats['totalAssignments']}',
                          color: AppTheme.primaryColor,
                          icon: Icons.assignment,
                        ),
                        const SizedBox(width: 12),
                        _StatBox(
                          label: 'Sudah Dinilai',
                          value: '${stats['totalGraded']}',
                          color: AppTheme.successColor,
                          icon: Icons.grading,
                        ),
                        const SizedBox(width: 12),
                        _StatBox(
                          label: 'Rata-rata',
                          value: (stats['avgScore'] as double)
                              .toStringAsFixed(1),
                          color: AppTheme.secondaryColor,
                          icon: Icons.bar_chart,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Per-assignment grades
            Text('Rekap Nilai Per Tugas',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            StreamBuilder<List<AssignmentModel>>(
              stream: db.getAssignments(teacherId: user.uid),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final assignments = snap.data!;
                if (assignments.isEmpty) {
                  return const _EmptyCard(
                      message: 'Belum ada tugas yang dibuat');
                }
                return Column(
                  children: assignments.map((a) {
                    return _AssignmentStatsCard(assignment: a);
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            // Attendance summary per class
            Text('Rekap Absensi Kelas',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            StreamBuilder<List<AssignmentModel>>(
              stream: db.getAssignments(teacherId: user.uid),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final classIds = snap.data!
                    .map((a) => a.classId)
                    .toSet()
                    .toList();
                if (classIds.isEmpty) {
                  return const _EmptyCard(
                      message: 'Belum ada data kelas');
                }
                return Column(
                  children: classIds.map((classId) {
                    return _ClassAttendanceCard(classId: classId);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _AssignmentStatsCard extends StatelessWidget {
  final AssignmentModel assignment;

  const _AssignmentStatsCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Icon(
          assignment.type == 'kuis'
              ? Icons.quiz_outlined
              : Icons.assignment_outlined,
          color: Colors.orange,
        ),
        title: Text(assignment.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${assignment.subject} • Kelas ${assignment.classId}'),
        children: [
          FutureBuilder<List<SubmissionModel>>(
            future: db
                .getSubmissions(assignment.id)
                .first
                .then((l) => l),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                );
              }
              final subs = snap.data!;
              final graded =
                  subs.where((s) => s.status == 'graded').toList();
              final scores =
                  graded.map((s) => s.score ?? 0).toList();
              final avg = scores.isEmpty
                  ? 0.0
                  : scores.reduce((a, b) => a + b) /
                      scores.length;
              final pass =
                  graded.where((s) => (s.score ?? 0) >= 70).length;

              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                      children: [
                        _MiniStat(
                            'Mengumpulkan',
                            '${subs.length}',
                            AppTheme.secondaryColor),
                        _MiniStat(
                            'Sudah Dinilai',
                            '${graded.length}',
                            AppTheme.successColor),
                        _MiniStat(
                            'Rata-rata',
                            avg.toStringAsFixed(1),
                            AppTheme.primaryColor),
                        _MiniStat(
                            'Lulus (≥70)',
                            '$pass',
                            AppTheme.successColor),
                      ],
                    ),
                    if (graded.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      // Grade distribution bar
                      _GradeBar(scores: scores),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GradeBar extends StatelessWidget {
  final List<int> scores;
  const _GradeBar({required this.scores});

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) return const SizedBox.shrink();
    final a = scores.where((s) => s >= 90).length;
    final b = scores.where((s) => s >= 75 && s < 90).length;
    final c = scores.where((s) => s >= 60 && s < 75).length;
    final d = scores.where((s) => s < 60).length;
    final total = scores.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Distribusi Nilai',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: [
            _BarSegment('A (≥90)', a, total, AppTheme.successColor),
            _BarSegment('B (75-89)', b, total, Colors.green),
            _BarSegment('C (60-74)', c, total, AppTheme.warningColor),
            _BarSegment('<60', d, total, AppTheme.errorColor),
          ],
        ),
      ],
    );
  }
}

class _BarSegment extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _BarSegment(this.label, this.count, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Expanded(
      flex: total > 0 ? (count * 10 + 1) : 1,
      child: Tooltip(
        message: '$label: $count siswa',
        child: Container(
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: count > 0 ? color : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: count > 0
              ? Center(
                  child: Text(
                    '$count',
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _ClassAttendanceCard extends StatelessWidget {
  final String classId;

  const _ClassAttendanceCard({required this.classId});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kelas $classId',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  StreamBuilder<List<dynamic>>(
                    stream: db
                        .getAttendanceByClass(classId, DateTime.now())
                        .map((l) => l),
                    builder: (context, snap) {
                      final list = snap.data ?? [];
                      final hadir =
                          list.where((a) => (a as dynamic).status == 'hadir').length;
                      final total = list.length;
                      final pct = total > 0
                          ? (hadir / total * 100).toStringAsFixed(0)
                          : '0';
                      return Text(
                        'Hari ini: $hadir/$total hadir ($pct%)',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.people_outlined,
                  color: AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(message,
              style: const TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }
}
