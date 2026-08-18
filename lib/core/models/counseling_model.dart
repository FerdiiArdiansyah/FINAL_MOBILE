import 'package:cloud_firestore/cloud_firestore.dart';

class CounselingModel {
  final String id;
  final String studentId;
  final String studentName;
  final String bkId;
  final String bkName;
  final String category; // 'Akademik' | 'Sosial' | 'Pribadi' | 'Karir' | 'Pelanggaran'
  final String description;
  final String status; // 'pending' | 'scheduled' | 'ongoing' | 'resolved'
  final DateTime? scheduledAt;
  final String? notes;
  final String? resolution;
  final DateTime createdAt;

  const CounselingModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.bkId,
    required this.bkName,
    required this.category,
    required this.description,
    required this.status,
    this.scheduledAt,
    this.notes,
    this.resolution,
    required this.createdAt,
  });

  factory CounselingModel.fromMap(Map<String, dynamic> map, String id) {
    return CounselingModel(
      id: id,
      studentId: map['student_id'] ?? map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      bkId: map['bkId'] ?? '',
      bkName: map['bkName'] ?? '',
      category: map['category'] ?? 'Pribadi',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      scheduledAt: (map['scheduledAt'] as Timestamp?)?.toDate(),
      notes: map['notes'],
      resolution: map['resolution'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'studentId': studentId,
      'studentName': studentName,
      'bkId': bkId,
      'bkName': bkName,
      'category': category,
      'description': description,
      'status': status,
      'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'notes': notes,
      'resolution': resolution,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
