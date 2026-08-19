import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];
  int _selectedDay = DateTime.now().weekday - 1;

  // Demo schedule — in production from Firestore
  final List<Map<String, String>> _schedule = [
    {'jam': '07:00 - 08:30', 'mapel': 'Matematika', 'guru': 'Bu Siti', 'ruang': 'R.101'},
    {'jam': '08:30 - 10:00', 'mapel': 'Bahasa Indonesia', 'guru': 'Pak Budi', 'ruang': 'R.101'},
    {'jam': '10:15 - 11:45', 'mapel': 'Bahasa Inggris', 'guru': 'Bu Rini', 'ruang': 'R.101'},
    {'jam': '11:45 - 12:30', 'mapel': 'ISOMA', 'guru': '-', 'ruang': '-'},
    {'jam': '12:30 - 14:00', 'mapel': 'Fisika', 'guru': 'Pak Heri', 'ruang': 'Lab.Fisika'},
    {'jam': '14:00 - 15:30', 'mapel': 'Pemrograman Web', 'guru': 'Bu Dewi', 'ruang': 'Lab.Komputer'},
  ];

  // Demo piket schedule — in production from Firestore
  final List<Map<String, String>> _piketSchedule = [
    {'minggu': 'Minggu 1', 'hari': 'Senin', 'tugas': 'Bersihkan papan tulis, menyiapkan absen kelas'},
    {'minggu': 'Minggu 2', 'hari': 'Rabu', 'tugas': 'Menyapu kelas, membuang sampah'},
    {'minggu': 'Minggu 3', 'hari': 'Jumat', 'tugas': 'Bersihkan meja guru, jaga kebersihan kelas'},
    {'minggu': 'Minggu 4', 'hari': 'Selasa', 'tugas': 'Menyiapkan spidol & penghapus, absensi'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Jadwal Pelajaran'),
            Tab(text: 'Jadwal Piket'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPelajaranTab(),
          _buildPiketTab(user.name),
        ],
      ),
    );
  }

  Widget _buildPelajaranTab() {
    return Column(
      children: [
          // Day selector
          Container(
            color: AppTheme.primaryColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Row(
                children: List.generate(
                  _days.length,
                  (i) => GestureDetector(
                    onTap: () => setState(() => _selectedDay = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedDay == i
                            ? Colors.white
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _days[i],
                        style: TextStyle(
                          color: _selectedDay == i
                              ? AppTheme.primaryColor
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Schedule list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _schedule.length,
              itemBuilder: (context, i) {
                final s = _schedule[i];
                final isBreak = s['mapel'] == 'ISOMA';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          s['jam']!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 70,
                        color: isBreak
                            ? Colors.grey[300]
                            : AppTheme.primaryColor,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      Expanded(
                        child: Card(
                          color: isBreak ? Colors.grey[100] : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['mapel']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isBreak
                                        ? Colors.grey
                                        : AppTheme.primaryColor,
                                  ),
                                ),
                                if (!isBreak) ...[
                                  Text(s['guru']!,
                                      style: const TextStyle(
                                          fontSize: 13)),
                                  Text(
                                    s['ruang']!,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
    );
  }

  Widget _buildPiketTab(String studentName) {
    final today = _days[DateTime.now().weekday <= 5
        ? DateTime.now().weekday - 1
        : 0];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Card(
            color: AppTheme.primaryColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.cleaning_services, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jadwal Piket Kelas',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          studentName,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Jadwal Piket Bulan Ini',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryColor)),
          const SizedBox(height: 12),
          ..._piketSchedule.map((p) {
            final isToday = p['hari'] == today;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: isToday
                  ? AppTheme.primaryColor.withValues(alpha: 0.05)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isToday
                    ? const BorderSide(
                        color: AppTheme.primaryColor, width: 1.5)
                    : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppTheme.primaryColor
                            : Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          p['hari']!.substring(0, 3),
                          style: TextStyle(
                            color: isToday ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${p['minggu']} — ${p['hari']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: 6),
                                const Chip(
                                  label: Text('Hari ini',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 10)),
                                  backgroundColor: AppTheme.primaryColor,
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p['tugas']!,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hadir tepat waktu dan laksanakan piket sebelum jam pelajaran dimulai (06:45 - 07:00 WIB).',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
