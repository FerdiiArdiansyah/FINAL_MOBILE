import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String classId;
  final String teacherId;
  final String teacherName;
  final String type; // 'tugas' | 'kuis'
  final DateTime deadline;
  final int maxScore;
  final List<Map<String, dynamic>>? questions; // for quiz
  final DateTime createdAt;

  const AssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.classId,
    required this.teacherId,
    required this.teacherName,
    required this.type,
    required this.deadline,
    required this.maxScore,
    this.questions,
    required this.createdAt,
  });

  factory AssignmentModel.fromMap(Map<String, dynamic> map, String id) {
    return AssignmentModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      subject: map['subject'] ?? '',
      classId: map['classId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      type: map['type'] ?? 'tugas',
      deadline: (map['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxScore: map['maxScore'] ?? 100,
      questions: map['questions'] != null
          ? List<Map<String, dynamic>>.from(map['questions'])
          : null,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
      'deadline': Timestamp.fromDate(deadline),
      'maxScore': maxScore,
      'questions': questions,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isExpired => DateTime.now().isAfter(deadline);
}

class SubmissionModel {
  final String id;
  final String studentId;
  final String studentName;
  final String assignmentId;
  final String? fileUrl;
  final List<Map<String, dynamic>>? answers; // for quiz
  final int? score;
  final String? feedback;
  final String status; // 'submitted' | 'graded' | 'late'
  final DateTime submittedAt;

  const SubmissionModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.assignmentId,
    this.fileUrl,
    this.answers,
    this.score,
    this.feedback,
    required this.status,
    required this.submittedAt,
  });

  factory SubmissionModel.fromMap(Map<String, dynamic> map, String id) {
    return SubmissionModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      assignmentId: map['assignmentId'] ?? '',
      fileUrl: map['fileUrl'],
      answers: map['answers'] != null
          ? List<Map<String, dynamic>>.from(map['answers'])
          : null,
      score: map['score'],
      feedback: map['feedback'],
      status: map['status'] ?? 'submitted',
      submittedAt:
          (map['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'assignmentId': assignmentId,
      'fileUrl': fileUrl,
      'answers': answers,
      'score': score,
      'feedback': feedback,
      'status': status,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }
}
