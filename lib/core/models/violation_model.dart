import 'package:cloud_firestore/cloud_firestore.dart';

class ViolationModel {
  final String id;
  final String studentId;
  final String studentName;
  final String classId;
  final String description;
  final int points;
  final String category; // 'ringan' | 'sedang' | 'berat'
  final String reportedBy;
  final String reportedByName;
  final String status; // 'pending' | 'verified' | 'resolved'
  final String? verifiedBy;
  final DateTime date;
  final DateTime createdAt;

  const ViolationModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.description,
    required this.points,
    required this.category,
    required this.reportedBy,
    required this.reportedByName,
    required this.status,
    this.verifiedBy,
    required this.date,
    required this.createdAt,
  });

  factory ViolationModel.fromMap(Map<String, dynamic> map, String id) {
    return ViolationModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      classId: map['classId'] ?? '',
      description: map['description'] ?? '',
      points: map['points'] ?? 0,
      category: map['category'] ?? 'ringan',
      reportedBy: map['reportedBy'] ?? '',
      reportedByName: map['reportedByName'] ?? '',
      status: map['status'] ?? 'pending',
      verifiedBy: map['verifiedBy'],
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'description': description,
      'points': points,
      'category': category,
      'reportedBy': reportedBy,
      'reportedByName': reportedByName,
      'status': status,
      'verifiedBy': verifiedBy,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
