import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/user_model.dart';
import '../../core/models/material_model.dart';
import '../../core/models/assignment_model.dart';
import '../../core/models/violation_model.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_theme.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: const [
          _UsersTab(),
          _ClassesTab(),
          _ContentTab(),
          _ViolationsTab(),
          _StatsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) => setState(() => _selectedTab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Pengguna',
          ),
          NavigationDestination(
            icon: Icon(Icons.class_outlined),
            selectedIcon: Icon(Icons.class_),
            label: 'Kelas',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Konten',
          ),
          NavigationDestination(
            icon: Icon(Icons.gavel_outlined),
            selectedIcon: Icon(Icons.gavel),
            label: 'Pelanggaran',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Statistik',
          ),
        ],
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    return Scaffold(
      body: FutureBuilder<List<UserModel>>(
        future: db.getAllUsers(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snap.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, i) {
              final u = users[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(u.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${AppRoles.displayName(u.role)} • ${u.email}'),
                  trailing: Chip(
                    label: Text(u.role,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white)),
                    backgroundColor: AppTheme.primaryColor,
                    padding: EdgeInsets.zero,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah User'),
      ),
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final classCtrl = TextEditingController();
    final nisnCtrl = TextEditingController();
    String selectedRole = AppRoles.siswa;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Tambah Pengguna'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: AppRoles.all
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(AppRoles.displayName(r)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedRole = v!),
                ),
                if (selectedRole == AppRoles.siswa) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: classCtrl,
                    decoration:
                        const InputDecoration(labelText: 'ID Kelas'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nisnCtrl,
                    decoration: const InputDecoration(labelText: 'NISN'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final authService = AuthService();
                try {
                  await authService.createUser(
                    email: emailCtrl.text,
                    password: passCtrl.text,
                    name: nameCtrl.text,
                    role: selectedRole,
                    classId: classCtrl.text.isNotEmpty
                        ? classCtrl.text
                        : null,
                    nisn: nisnCtrl.text.isNotEmpty
                        ? nisnCtrl.text
                        : null,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pengguna berhasil dibuat'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Buat'),
            ),
          ],
        ),
      ),
    );
  }
}

// Materi & Tugas — Admin (Monitor semua konten)
class _ContentTab extends StatefulWidget {
  const _ContentTab();

  @override
  State<_ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends State<_ContentTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final Stream<List<AssignmentModel>> _assignmentsStream;
  late final Stream<List<MaterialModel>> _materialsStream;

  @override
  void initState() {
    super.initState();
    // Stream dibuat sekali di initState agar tidak reset saat build ulang
    final db = FirestoreService();
    _assignmentsStream = db.getAssignments();
    _materialsStream = db.getMaterials();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    final isMaterialTab = _tabController.index == 1;

    return Scaffold(
      appBar: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Tugas & Kuis'),
          Tab(text: 'Materi'),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab Tugas & Kuis ──
          StreamBuilder<List<AssignmentModel>>(
            stream: _assignmentsStream,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snap.data!;
              if (list.isEmpty) {
                return const Center(
                  child: Text('Belum ada tugas',
                      style: TextStyle(color: Colors.grey)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final a = list[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        a.type == 'kuis'
                            ? Icons.quiz_outlined
                            : Icons.assignment_outlined,
                        color: a.isExpired ? Colors.red : Colors.orange,
                      ),
                      title: Text(a.title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${a.subject} • ${a.teacherName} • Kelas ${a.classId}'),
                      trailing: Chip(
                        label: Text(
                          a.isExpired ? 'Tutup' : 'Aktif',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                        backgroundColor:
                            a.isExpired ? Colors.red : Colors.green,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // ── Tab Materi ──
          StreamBuilder<List<MaterialModel>>(
            stream: _materialsStream,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snap.data!;
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.library_books_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('Belum ada materi',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Materi Pertama'),
                        onPressed: () => _showAddMaterialDialog(context),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final m = list[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          m.type == 'video'
                              ? Icons.play_circle_outline
                              : m.type == 'link'
                                  ? Icons.link
                                  : Icons.picture_as_pdf,
                          color: Colors.blue,
                        ),
                      ),
                      title: Text(m.title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${m.subject} • ${m.teacherName}\nKelas ${m.classId}'),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        tooltip: 'Hapus materi',
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Hapus Materi'),
                              content: Text('Hapus materi "${m.title}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await db.deleteMaterial(m.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Materi dihapus'),
                                  backgroundColor: AppTheme.successColor,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddMaterialDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final classCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'pdf';
    final user = context.read<AuthProvider>().userModel!;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Tambah Materi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Judul Materi *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: subjectCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Mata Pelajaran *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: classCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ID Kelas *',
                    hintText: 'Contoh: X-TKJ-1',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Tipe'),
                  items: ['pdf', 'video', 'link']
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => type = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL File / Link *',
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text('Tambah'),
              onPressed: () async {
                if (titleCtrl.text.isEmpty ||
                    subjectCtrl.text.isEmpty ||
                    classCtrl.text.isEmpty ||
                    urlCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Lengkapi semua field bertanda *')),
                  );
                  return;
                }
                final db = FirestoreService();
                await db.addMaterial(
                  MaterialModel(
                    id: '',
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    subject: subjectCtrl.text.trim(),
                    classId: classCtrl.text.trim(),
                    teacherId: user.uid,
                    teacherName: user.name,
                    type: type,
                    fileUrl: urlCtrl.text.trim(),
                    createdAt: DateTime.now(),
                  ),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Materi berhasil ditambahkan'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Pelanggaran — Admin (full access: lihat semua, verifikasi, hapus)
class _ViolationsTab extends StatefulWidget {
  const _ViolationsTab();

  @override
  State<_ViolationsTab> createState() => _ViolationsTabState();
}

class _ViolationsTabState extends State<_ViolationsTab> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    final adminUser = context.read<AuthProvider>().userModel!;

    return Scaffold(
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['all', 'pending', 'verified', 'resolved']
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(s == 'all' ? 'Semua' : s),
                          selected: _filterStatus == s,
                          onSelected: (_) =>
                              setState(() => _filterStatus = s),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ViolationModel>>(
              // Admin melihat semua pelanggaran (tidak difilter classId)
              stream: db.getAllViolations(
                  status: _filterStatus == 'all' ? null : _filterStatus),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final violations = snap.data ?? [];
                if (violations.isEmpty) {
                  return const Center(
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
                  );
                }
                // Summary stats
                final totalPending =
                    violations.where((v) => v.status == 'pending').length;
                return Column(
                  children: [
                    if (totalPending > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        color: AppTheme.warningColor.withValues(alpha: 0.1),
                        child: Row(
                          children: [
                            const Icon(Icons.pending_actions,
                                color: AppTheme.warningColor, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '$totalPending pelanggaran menunggu verifikasi',
                              style: const TextStyle(
                                  color: AppTheme.warningColor,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: violations.length,
                        itemBuilder: (context, i) {
                          final v = violations[i];
                          return _ViolationAdminCard(
                            violation: v,
                            adminUid: adminUser.uid,
                          );
                        },
                      ),
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

class _ViolationAdminCard extends StatelessWidget {
  final ViolationModel violation;
  final String adminUid;

  const _ViolationAdminCard({
    required this.violation,
    required this.adminUid,
  });

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    final statusColor = _statusColor(violation.status);
    final catColor = violation.category == 'berat'
        ? AppTheme.errorColor
        : violation.category == 'sedang'
            ? AppTheme.warningColor
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(violation.studentName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Kelas: ${violation.classId.isNotEmpty ? violation.classId : "-"}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    '${violation.category} • ${violation.points} poin',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11),
                  ),
                  backgroundColor: catColor,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(violation.description,
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dilaporkan: ${violation.reportedByName}  •  ${_fmt(violation.date)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Chip(
                  label: Text(
                    violation.status,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10),
                  ),
                  backgroundColor: statusColor,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (violation.status == 'pending') ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.verified, size: 14),
                    label: const Text('Verifikasi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () async {
                      await db.updateViolationStatus(
                          violation.id, 'verified', adminUid);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                if (violation.status == 'verified')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle, size: 14),
                    label: const Text('Selesai'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () async {
                      await db.updateViolationStatus(
                          violation.id, 'resolved', adminUid);
                    },
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Hapus',
                  onPressed: () => _confirmDelete(context, db),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, FirestoreService db) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pelanggaran'),
        content: const Text('Hapus catatan pelanggaran ini secara permanen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await db.deleteViolation(violation.id);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'verified': return AppTheme.successColor;
      case 'resolved': return AppTheme.secondaryColor;
      default: return AppTheme.warningColor;
    }
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _ClassesTab extends StatelessWidget {
  const _ClassesTab();

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: db.getClassesStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final classes = snap.data!;
          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.class_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Belum ada kelas terdaftar',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Kelas Pertama'),
                    onPressed: () => _showAddClassDialog(context, db),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: classes.length,
            itemBuilder: (context, i) {
              final c = classes[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      c['classId'].toString().substring(0, 1),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(c['classId'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(c['className'] as String? ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Hapus Kelas'),
                          content: Text(
                              'Hapus kelas "${c['classId']}"?\nData materi/tugas yang sudah dibuat untuk kelas ini tidak akan terhapus.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Batal')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) await db.deleteClass(c['classId'] as String);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClassDialog(context, db),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kelas'),
      ),
    );
  }

  void _showAddClassDialog(BuildContext context, FirestoreService db) {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Kelas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idCtrl,
              decoration: const InputDecoration(
                labelText: 'ID Kelas *',
                hintText: 'X-TKJ-1',
                helperText: 'Gunakan format: Tingkat-Jurusan-No (tanpa spasi)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Kelas *',
                hintText: 'X TKJ 1',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (idCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;
              await db.addClass(idCtrl.text.trim(), nameCtrl.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kelas "${idCtrl.text}" berhasil ditambahkan'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    return FutureBuilder<List<UserModel>>(
      future: db.getAllUsers(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snap.data!;
        final roleCount = <String, int>{};
        for (final r in AppRoles.all) {
          roleCount[r] = users.where((u) => u.role == r).length;
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Statistik Pengguna',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ...AppRoles.all.map((r) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        roleCount[r].toString(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(AppRoles.displayName(r)),
                    subtitle: Text(r),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Card(
                color: AppTheme.primaryColor,
                child: ListTile(
                  title: const Text('Total Pengguna',
                      style: TextStyle(color: Colors.white)),
                  trailing: Text(
                    users.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
