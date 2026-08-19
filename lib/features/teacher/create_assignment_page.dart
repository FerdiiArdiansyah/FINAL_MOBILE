import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/notification_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/class_dropdown.dart';

class CreateAssignmentPage extends StatefulWidget {
  const CreateAssignmentPage({super.key});

  @override
  State<CreateAssignmentPage> createState() => _CreateAssignmentPageState();
}

class _CreateAssignmentPageState extends State<CreateAssignmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subjectController = TextEditingController();
  final _classController = TextEditingController();
  final _maxScoreController = TextEditingController(text: '100');
  String _selectedType = 'tugas';
  String? _selectedClassId;
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subjectController.dispose();
    _classController.dispose();
    _maxScoreController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
    );
    if (time == null) return;
    setState(() {
      _deadline =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthProvider>().userModel!;
    setState(() => _loading = true);
    try {
      final db = FirestoreService();
      final assignmentId = await db.addAssignment(
        AssignmentModel(
          id: '',
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          subject: _subjectController.text.trim(),
          classId: _selectedClassId ?? '',
          teacherId: user.uid,
          teacherName: user.name,
          type: _selectedType,
          deadline: _deadline,
          maxScore: int.tryParse(_maxScoreController.text) ?? 100,
          createdAt: DateTime.now(),
        ),
      );
      // Send notification
      await db.addNotification(
        NotificationModel(
          id: '',
          title: 'Tugas Baru: ${_titleController.text}',
          body:
              '${user.name} membuat tugas baru untuk kelas ${_selectedClassId ?? ""}',
          type: 'assignment',
          targetUserId: 'ALL',
          targetClassId: _selectedClassId ?? '',
          relatedId: assignmentId,
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tugas berhasil dibuat'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Tugas / Kuis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type selector
              Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: 'Tugas',
                      icon: Icons.assignment_outlined,
                      selected: _selectedType == 'tugas',
                      onTap: () => setState(() => _selectedType = 'tugas'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeButton(
                      label: 'Kuis',
                      icon: Icons.quiz_outlined,
                      selected: _selectedType == 'kuis',
                      onTap: () => setState(() => _selectedType = 'kuis'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul *'),
                validator: (v) =>
                    v?.isEmpty == true ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subjectController,
                decoration:
                    const InputDecoration(labelText: 'Mata Pelajaran *'),
                validator: (v) => v?.isEmpty == true ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              ClassDropdown(
                value: _selectedClassId,
                onChanged: (v) => setState(() => _selectedClassId = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxScoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nilai Maksimum'),
              ),
              const SizedBox(height: 12),
              // Deadline picker
              InkWell(
                onTap: _pickDeadline,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Deadline *',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(_formatDateTime(_deadline)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi / Instruksi',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('Buat & Publikasi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}';
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
