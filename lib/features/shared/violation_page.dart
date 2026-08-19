import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/user_model.dart';
import '../../core/models/violation_model.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_theme.dart';

class ViolationPage extends StatelessWidget {
  final String studentId;
  const ViolationPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;
    final db = FirestoreService();
    final canAdd = [
      AppRoles.guruMapel,
      AppRoles.waliKelas,
      AppRoles.guruBk,
      AppRoles.guruPiket,
      AppRoles.admin,
    ].contains(user.role);
    return Scaffold(
      appBar: AppBar(title: const Text('Catatan Pelanggaran')),
      floatingActionButton: canAdd
          ? FloatingActionButton(
              onPressed: () =>
                  _showAddViolationDialog(context, user),
              child: const Icon(Icons.add),
            )
          : null,
      body: StreamBuilder<List<ViolationModel>>(
        stream: db.getViolationsByStudent(studentId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final violations = snap.data ?? [];
          final totalPoints =
              violations.fold<int>(0, (sum, v) => sum + v.points);

          return Column(
            children: [
              // Summary header
              Container(
                padding: const EdgeInsets.all(16),
                color: totalPoints >= 80
                    ? AppTheme.errorColor
                    : totalPoints >= 50
                        ? AppTheme.warningColor
                        : AppTheme.primaryColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Poin Pelanggaran',
                      style: TextStyle(
                          color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      '$totalPoints / 100',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (totalPoints >= 80)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: AppTheme.errorColor),
                      SizedBox(width: 8),
                      Text(
                        'PERHATIAN: Poin mendekati batas maksimum!',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: violations.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 64, color: Colors.green),
                            SizedBox(height: 12),
                            Text('Tidak ada catatan pelanggaran',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: violations.length,
                        itemBuilder: (context, i) {
                          return _ViolationCard(
                            violation: violations[i],
                            canVerify:
                                user.role == AppRoles.guruBk ||
                                    user.role == AppRoles.admin,
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

  void _showAddViolationDialog(BuildContext context, UserModel user) {
    final descCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: '5');
    String selectedCategory = 'ringan';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Catat Pelanggaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration:
                    const InputDecoration(labelText: 'Kategori'),
                items: ['ringan', 'sedang', 'berat']
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c[0].toUpperCase() +
                              c.substring(1)),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    selectedCategory = v!;
                    if (v == 'ringan') {
                      pointsCtrl.text = '5';
                    } else if (v == 'sedang') pointsCtrl.text = '15';
                    else pointsCtrl.text = '30';
                  });
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: pointsCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Poin'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Deskripsi Pelanggaran'),
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
                if (descCtrl.text.isEmpty) return;
                final db = FirestoreService();
                await db.addViolation(
                  ViolationModel(
                    id: '',
                    studentId: studentId,
                    studentName: '',
                    classId: '',
                    description: descCtrl.text,
                    points: int.tryParse(pointsCtrl.text) ?? 5,
                    category: selectedCategory,
                    reportedBy: user.uid,
                    reportedByName: user.name,
                    status: 'pending',
                    date: DateTime.now(),
                    createdAt: DateTime.now(),
                  ),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pelanggaran berhasil dicatat'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViolationCard extends StatelessWidget {
  final ViolationModel violation;
  final bool canVerify;

  const _ViolationCard({
    required this.violation,
    required this.canVerify,
  });

  @override
  Widget build(BuildContext context) {
    Color categoryColor;
    switch (violation.category) {
      case 'berat': categoryColor = AppTheme.errorColor; break;
      case 'sedang': categoryColor = AppTheme.warningColor; break;
      default: categoryColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${violation.category[0].toUpperCase()}${violation.category.substring(1)} • ${violation.points} poin',
                    style: TextStyle(
                        color: categoryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    violation.status,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10),
                  ),
                  backgroundColor:
                      violation.status == 'verified'
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(violation.description),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dilaporkan: ${violation.reportedByName}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
                Text(_fmt(violation.date),
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
            if (canVerify && violation.status == 'pending') ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.verified, size: 16),
                label: const Text('Verifikasi'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () async {
                  final userProvider = context.read<AuthProvider>();
                  final db = FirestoreService();
                  await db.updateViolationStatus(
                    violation.id,
                    'verified',
                    userProvider.userModel!.uid,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
