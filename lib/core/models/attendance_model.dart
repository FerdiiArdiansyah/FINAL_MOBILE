import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String studentId;
  final String studentName;
  final String classId;
  final String? subject;
  final String? teacherId;
  final String status; // 'hadir' | 'izin' | 'sakit' | 'alpha'
  final String? note;
  final DateTime date;
  final String? session; // jam pelajaran ke-
  final String recordedBy; // uid of teacher/piket
  final String recordType; // 'mapel' | 'piket'

  const AttendanceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.classId,
    this.subject,
    this.teacherId,
    required this.status,
    this.note,
    required this.date,
    this.session,
    required this.recordedBy,
    required this.recordType,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      classId: map['classId'] ?? '',
      subject: map['subject'],
      teacherId: map['teacherId'],
      status: map['status'] ?? 'hadir',
      note: map['note'],
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      session: map['session'],
      recordedBy: map['recordedBy'] ?? '',
      recordType: map['recordType'] ?? 'mapel',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'subject': subject,
      'teacherId': teacherId,
      'status': status,
      'note': note,
      'date': Timestamp.fromDate(date),
      'session': session,
      'recordedBy': recordedBy,
      'recordType': recordType,
    };
  }

  bool get isAlpha => status == 'alpha';
}
