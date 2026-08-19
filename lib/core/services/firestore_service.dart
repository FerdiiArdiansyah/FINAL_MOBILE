import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/material_model.dart';
import '../models/assignment_model.dart';
import '../models/attendance_model.dart';
import '../models/violation_model.dart';
import '../models/counseling_model.dart';
import '../models/chat_model.dart';
import '../models/notification_model.dart';
import '../constants/firebase_constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== USERS ====================

  Stream<List<UserModel>> getStudentsByClass(String classId) {
    return _db
        .collection(FirebaseConstants.usersCollection)
        .where('classId', isEqualTo: classId)
        .where('role', isEqualTo: 'SISWA')
        .snapshots()
        .map((s) =>
            s.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot =
        await _db.collection(FirebaseConstants.usersCollection).get();
    return snapshot.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
  }

  Future<UserModel?> getUser(String uid) async {
    final doc =
        await _db.collection(FirebaseConstants.usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .update(data);
  }

  // ==================== MATERIALS ====================

  Stream<List<MaterialModel>> getMaterials({String? classId, String? subject}) {
    Query<Map<String, dynamic>> query =
        _db.collection(FirebaseConstants.materialsCollection);
    if (classId != null) query = query.where('classId', isEqualTo: classId);
    if (subject != null) query = query.where('subject', isEqualTo: subject);
    return query.snapshots().map((s) {
      final list =
          s.docs.map((d) => MaterialModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<String> addMaterial(MaterialModel material) async {
    final doc = await _db
        .collection(FirebaseConstants.materialsCollection)
        .add(material.toMap());
    return doc.id;
  }

  Future<void> deleteMaterial(String id) async {
    await _db
        .collection(FirebaseConstants.materialsCollection)
        .doc(id)
        .delete();
  }

  // ==================== ASSIGNMENTS ====================

  Stream<List<AssignmentModel>> getAssignments({
    String? classId,
    String? teacherId,
  }) {
    Query<Map<String, dynamic>> query =
        _db.collection(FirebaseConstants.assignmentsCollection);
    if (classId != null) query = query.where('classId', isEqualTo: classId);
    if (teacherId != null) {
      query = query.where('teacherId', isEqualTo: teacherId);
    }
    return query.snapshots().map((s) {
      final list =
          s.docs.map((d) => AssignmentModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<String> addAssignment(AssignmentModel assignment) async {
    final doc = await _db
        .collection(FirebaseConstants.assignmentsCollection)
        .add(assignment.toMap());
    return doc.id;
  }

  Future<void> submitAssignment(
      String assignmentId, SubmissionModel submission) async {
    await _db
        .collection(FirebaseConstants.assignmentsCollection)
        .doc(assignmentId)
        .collection(FirebaseConstants.submissionsSubCollection)
        .doc(submission.studentId)
        .set(submission.toMap());
  }

  Future<SubmissionModel?> getSubmission(
      String assignmentId, String studentId) async {
    final doc = await _db
        .collection(FirebaseConstants.assignmentsCollection)
        .doc(assignmentId)
        .collection(FirebaseConstants.submissionsSubCollection)
        .doc(studentId)
        .get();
    if (!doc.exists) return null;
    return SubmissionModel.fromMap(doc.data()!, doc.id);
  }

  Stream<List<SubmissionModel>> getSubmissions(String assignmentId) {
    return _db
        .collection(FirebaseConstants.assignmentsCollection)
        .doc(assignmentId)
        .collection(FirebaseConstants.submissionsSubCollection)
        .snapshots()
        .map((s) => s.docs
            .map((d) => SubmissionModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> gradeSubmission(String assignmentId, String studentId, int score,
      String? feedback) async {
    await _db
        .collection(FirebaseConstants.assignmentsCollection)
        .doc(assignmentId)
        .collection(FirebaseConstants.submissionsSubCollection)
        .doc(studentId)
        .update({
      'score': score,
      'feedback': feedback,
      'status': 'graded',
    });
  }

  // ==================== ATTENDANCE ====================

  Future<void> addAttendance(AttendanceModel attendance) async {
    await _db
        .collection(FirebaseConstants.attendanceCollection)
        .add(attendance.toMap());
  }

  Future<void> addBatchAttendance(List<AttendanceModel> attendances) async {
    final batch = _db.batch();
    for (final a in attendances) {
      final ref = _db.collection(FirebaseConstants.attendanceCollection).doc();
      batch.set(ref, a.toMap());
    }
    await batch.commit();
  }

  Stream<List<AttendanceModel>> getAttendanceByStudent(String studentId,
      {DateTime? from, DateTime? to}) {
    Query<Map<String, dynamic>> query = _db
        .collection(FirebaseConstants.attendanceCollection)
        .where('studentId', isEqualTo: studentId);
    if (from != null) {
      query =
          query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    return query.snapshots().map((s) {
      final list =
          s.docs.map((d) => AttendanceModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<AttendanceModel>> getAttendanceByClass(
      String classId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _db
        .collection(FirebaseConstants.attendanceCollection)
        .where('classId', isEqualTo: classId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((s) => s.docs
            .map((d) => AttendanceModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ==================== VIOLATIONS ====================

  Stream<List<ViolationModel>> getViolationsByStudent(String studentId) {
    return _db
        .collection(FirebaseConstants.pelanggaranCollection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => ViolationModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<ViolationModel>> getViolationsByClass(String classId) {
    return _db
        .collection(FirebaseConstants.pelanggaranCollection)
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => ViolationModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<String> addViolation(ViolationModel violation) async {
    final doc = await _db
        .collection(FirebaseConstants.pelanggaranCollection)
        .add(violation.toMap());
    return doc.id;
  }

  Future<void> updateViolationStatus(
      String id, String status, String verifiedBy) async {
    await _db
        .collection(FirebaseConstants.pelanggaranCollection)
        .doc(id)
        .update({'status': status, 'verifiedBy': verifiedBy});
  }

  // Admin: lihat semua pelanggaran lintas kelas
  Stream<List<ViolationModel>> getAllViolations({String? status}) {
    Query<Map<String, dynamic>> query =
        _db.collection(FirebaseConstants.pelanggaranCollection);
    if (status != null) query = query.where('status', isEqualTo: status);
    return query.snapshots().map((s) {
      final list =
          s.docs.map((d) => ViolationModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<void> deleteViolation(String id) async {
    await _db
        .collection(FirebaseConstants.pelanggaranCollection)
        .doc(id)
        .delete();
  }

  // ==================== COUNSELING ====================

  Stream<List<CounselingModel>> getCounselingCases({
    String? studentId,
    String? bkId,
    String? status,
  }) {
    Query<Map<String, dynamic>> query =
        _db.collection(FirebaseConstants.konselingCollection);
    if (studentId != null) {
      query = query.where('student_id', isEqualTo: studentId);
    }
    if (bkId != null) query = query.where('bkId', isEqualTo: bkId);
    if (status != null) query = query.where('status', isEqualTo: status);
    return query.snapshots().map((s) {
      final list =
          s.docs.map((d) => CounselingModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<String> addCounseling(CounselingModel counseling) async {
    final doc = await _db
        .collection(FirebaseConstants.konselingCollection)
        .add(counseling.toMap());
    return doc.id;
  }

  Future<void> updateCounselingStatus(String id, String status,
      {String? notes, String? resolution, DateTime? scheduledAt}) async {
    final data = <String, dynamic>{'status': status};
    if (notes != null) data['notes'] = notes;
    if (resolution != null) data['resolution'] = resolution;
    if (scheduledAt != null)
      data['scheduledAt'] = Timestamp.fromDate(scheduledAt);
    await _db
        .collection(FirebaseConstants.konselingCollection)
        .doc(id)
        .update(data);
  }

  // ==================== CHAT ====================

  Stream<List<ChatRoomModel>> getChatRooms(String userId) {
    return _db
        .collection(FirebaseConstants.chatRoomsCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => ChatRoomModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime(2000);
        final bTime = b.lastMessageAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Future<ChatRoomModel> getOrCreateChatRoom(
      String userId1, String userId2, Map<String, String> names,
      {String type = 'private'}) async {
    final participants = [userId1, userId2]..sort();
    final snapshot = await _db
        .collection(FirebaseConstants.chatRoomsCollection)
        .where('participants', isEqualTo: participants)
        .where('type', isEqualTo: type)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return ChatRoomModel.fromMap(
          snapshot.docs.first.data(), snapshot.docs.first.id);
    }
    final room = ChatRoomModel(
      id: '',
      participants: participants,
      participantNames: names,
      type: type,
    );
    final doc = await _db
        .collection(FirebaseConstants.chatRoomsCollection)
        .add(room.toMap());
    return ChatRoomModel.fromMap(room.toMap(), doc.id);
  }

  Stream<List<ChatMessageModel>> getMessages(String roomId) {
    return _db
        .collection(FirebaseConstants.chatRoomsCollection)
        .doc(roomId)
        .collection(FirebaseConstants.messagesSubCollection)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ChatMessageModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> sendMessage(String roomId, ChatMessageModel message) async {
    final batch = _db.batch();
    final msgRef = _db
        .collection(FirebaseConstants.chatRoomsCollection)
        .doc(roomId)
        .collection(FirebaseConstants.messagesSubCollection)
        .doc();
    batch.set(msgRef, message.toMap());
    final roomRef =
        _db.collection(FirebaseConstants.chatRoomsCollection).doc(roomId);
    batch.update(roomRef, {
      'lastMessage': message.content,
      'lastMessageAt': Timestamp.fromDate(message.sentAt),
    });
    await batch.commit();
  }

  // ==================== ANNOUNCEMENTS ====================

  Stream<List<AnnouncementModel>> getAnnouncements({String? classId}) {
    Query<Map<String, dynamic>> query = _db
        .collection(FirebaseConstants.announcementsCollection)
        .orderBy('createdAt', descending: true);
    return query.snapshots().map((s) => s.docs
        .where((d) {
          final target = d.data()['targetClassId'];
          return target == null || target == classId;
        })
        .map((d) => AnnouncementModel.fromMap(d.data(), d.id))
        .toList());
  }

  Future<String> addAnnouncement(AnnouncementModel announcement) async {
    final doc = await _db
        .collection(FirebaseConstants.announcementsCollection)
        .add(announcement.toMap());
    return doc.id;
  }

  // ==================== PIKET LOG ====================

  Future<void> addPiketLog(Map<String, dynamic> log) async {
    await _db.collection(FirebaseConstants.piketLogCollection).add(log);
  }

  Stream<List<Map<String, dynamic>>> getPiketLogs(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _db
        .collection(FirebaseConstants.piketLogCollection)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ==================== NOTIFICATIONS ====================

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _db
        .collection(FirebaseConstants.notificationsCollection)
        .where('targetUserId', whereIn: [userId, 'ALL'])
        .limit(50)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => NotificationModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> addNotification(NotificationModel notification) async {
    await _db
        .collection(FirebaseConstants.notificationsCollection)
        .add(notification.toMap());
  }

  Future<void> markNotificationRead(String id) async {
    await _db
        .collection(FirebaseConstants.notificationsCollection)
        .doc(id)
        .update({'isRead': true});
  }

  // ==================== FORUM DISKUSI ====================

  Stream<List<Map<String, dynamic>>> getForumPosts({String? subjectId}) {
    Query<Map<String, dynamic>> q = _db.collection('forumPosts');
    if (subjectId != null) q = q.where('subjectId', isEqualTo: subjectId);
    return q.snapshots().map((s) {
      final list = s.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      list.sort((a, b) {
        final aT = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final bT = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return bT.compareTo(aT);
      });
      return list;
    });
  }

  Future<String> addForumPost(Map<String, dynamic> post) async {
    final doc = await _db.collection('forumPosts').add(post);
    return doc.id;
  }

  Stream<List<Map<String, dynamic>>> getForumReplies(String postId) {
    return _db
        .collection('forumPosts')
        .doc(postId)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> addForumReply(String postId, Map<String, dynamic> reply) async {
    final batch = _db.batch();
    final replyRef =
        _db.collection('forumPosts').doc(postId).collection('replies').doc();
    batch.set(replyRef, reply);
    batch.update(_db.collection('forumPosts').doc(postId),
        {'replyCount': FieldValue.increment(1)});
    await batch.commit();
  }

  // ==================== STATISTIK GURU ====================

  Future<Map<String, dynamic>> getTeacherStats(String teacherId) async {
    final assignments = await _db
        .collection(FirebaseConstants.assignmentsCollection)
        .where('teacherId', isEqualTo: teacherId)
        .get();

    int totalAssignments = assignments.docs.length;
    int totalGraded = 0;
    double totalAvg = 0;
    final classIds = <String>{};

    for (final aDoc in assignments.docs) {
      classIds.add(aDoc.data()['classId'] ?? '');
      final subs = await _db
          .collection(FirebaseConstants.assignmentsCollection)
          .doc(aDoc.id)
          .collection(FirebaseConstants.submissionsSubCollection)
          .where('status', isEqualTo: 'graded')
          .get();

      if (subs.docs.isNotEmpty) {
        totalGraded += subs.docs.length;
        final avg = subs.docs
                .map((s) => (s.data()['score'] as num?)?.toDouble() ?? 0)
                .fold(0.0, (a, b) => a + b) /
            subs.docs.length;
        totalAvg += avg;
      }
    }

    return {
      'totalAssignments': totalAssignments,
      'totalGraded': totalGraded,
      'avgScore': totalAssignments > 0 ? totalAvg / totalAssignments : 0,
      'classCount': classIds.length,
      'classIds': classIds.toList(),
    };
  }
}
