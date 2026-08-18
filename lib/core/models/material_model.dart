import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialModel {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String classId;
  final String teacherId;
  final String teacherName;
  final String type; // 'pdf' | 'video' | 'link'
  final String fileUrl;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MaterialModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.classId,
    required this.teacherId,
    required this.teacherName,
    required this.type,
    required this.fileUrl,
    this.thumbnailUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory MaterialModel.fromMap(Map<String, dynamic> map, String id) {
    return MaterialModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      subject: map['subject'] ?? '',
      classId: map['classId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      type: map['type'] ?? 'pdf',
      fileUrl: map['fileUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'subject': subject,
      'classId': classId,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'type': type,
      'fileUrl': fileUrl,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
