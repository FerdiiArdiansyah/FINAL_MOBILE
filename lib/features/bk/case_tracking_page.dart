import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/counseling_model.dart';
import '../../core/theme/app_theme.dart';

class CaseTrackingPage extends StatefulWidget {
  const CaseTrackingPage({super.key});

  @override
  State<CaseTrackingPage> createState() => _CaseTrackingPageState();
}

class _CaseTrackingPageState extends State<CaseTrackingPage> {
  String _selectedStatus = 'all';
  String _selectedCategory = 'all';

  final _statuses = ['all', 'pending', 'scheduled', 'ongoing', 'resolved'];
  final _categories = [
    'all',
    'Akademik',
    'Sosial',
    'Pribadi',
    'Karir',
    'Pelanggaran'
  ];

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    final bk = context.watch<AuthProvider>().userModel!;
    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Kasus')),
      body: Column(
        children: [
          // Status filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                const Text('Status: ',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ..._statuses.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: FilterChip(
                        label: Text(s == 'all' ? 'Semua' : _statusLabel(s),
                            style: const TextStyle(fontSize: 12)),
                        selected: _selectedStatus == s,
                        selectedColor: _statusColor(s).withOpacity(0.2),
                        onSelected: (_) => setState(() => _selectedStatus = s),
                      ),
                    )),
              ],
            ),
          ),
          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                const Text('Kategori: ',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ..._categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: FilterChip(
                        label: Text(c == 'all' ? 'Semua' : c,
                            style: const TextStyle(fontSize: 12)),
                        selected: _selectedCategory == c,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = c),
                      ),
                    )),
              ],
            ),
          ),
          // Cases list
          Expanded(
            child: StreamBuilder<List<CounselingModel>>(
              stream: db.getCounselingCases(
                status: _selectedStatus == 'all' ? null : _selectedStatus,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final cases = snap.data ?? [];
                final filtered = _selectedCategory == 'all'
                    ? cases
                    : cases
                        .where((c) => c.category == _selectedCategory)
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada kasus',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    return _CaseCard(counseling: filtered[i]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String s) {
    const map = {
      'pending': 'Menunggu',
      'scheduled': 'Terjadwal',
      'ongoing': 'Berlangsung',
      'resolved': 'Selesai',
    };
    return map[s] ?? s;
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return AppTheme.warningColor;
      case 'scheduled':
        return AppTheme.secondaryColor;
      case 'ongoing':
        return Colors.purple;
      case 'resolved':
        return AppTheme.successColor;
      default:
        return Colors.grey;
    }
  }
}

class _CaseCard extends StatelessWidget {
  final CounselingModel counseling;
  const _CaseCard({required this.counseling});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    final bk = context.read<AuthProvider>().userModel!;
    final statusColor = _statusColor(counseling.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    counseling.studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    counseling.status,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  backgroundColor: statusColor,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                Chip(
                  label: Text(counseling.category,
                      style: const TextStyle(fontSize: 11)),
                  backgroundColor: AppTheme.accentColor.withValues(alpha: 0.2),
                  padding: EdgeInsets.zero,
                ),
                if (counseling.scheduledAt != null)
                  Chip(
                    label: Text(
                      'Jadwal: ${_fmt(counseling.scheduledAt!)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.green.withValues(alpha: 0.2),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              counseling.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            if (counseling.notes != null) ...[
              const SizedBox(height: 4),
              Text(
                'Catatan: ${counseling.notes}',
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
            ],
            if (counseling.resolution != null) ...[
              const SizedBox(height: 4),
              Text(
                'Resolusi: ${counseling.resolution}',
                style:
                    const TextStyle(fontSize: 12, color: AppTheme.successColor),
              ),
            ],
            if (counseling.status != 'resolved') ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (counseling.status == 'pending')
                    _ActionBtn('Jadwalkan', Colors.blue, () async {
                      await db.updateCounselingStatus(
                          counseling.id, 'scheduled',
                          notes: 'Dijadwalkan oleh ${bk.name}');
                    }),
                  if (counseling.status == 'scheduled')
                    _ActionBtn('Mulai Sesi', Colors.purple, () async {
                      await db.updateCounselingStatus(counseling.id, 'ongoing',
                          notes: 'Sesi dimulai oleh ${bk.name}');
                    }),
                  if (counseling.status == 'ongoing')
                    _ActionBtn('Selesai', AppTheme.successColor, () async {
                      await db.updateCounselingStatus(counseling.id, 'resolved',
                          resolution: 'Diselesaikan oleh ${bk.name}');
                    }),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warningColor;
      case 'scheduled':
        return AppTheme.secondaryColor;
      case 'ongoing':
        return Colors.purple;
      case 'resolved':
        return AppTheme.successColor;
      default:
        return Colors.grey;
    }
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        textStyle: const TextStyle(fontSize: 12),
        minimumSize: Size.zero,
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
