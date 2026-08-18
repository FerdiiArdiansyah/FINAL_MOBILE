import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'assignment' | 'alert' | 'violation' | 'announcement' | 'counseling'
  final String targetUserId; // specific uid or 'ALL'
  final String? targetClassId;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.targetUserId,
    this.targetClassId,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'announcement',
      targetUserId: map['targetUserId'] ?? 'ALL',
      targetClassId: map['targetClassId'],
      relatedId: map['relatedId'],
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'targetUserId': targetUserId,
      'targetClassId': targetClassId,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String priority; // 'normal' | 'urgent'
  final String? targetClassId; // null = all
  final DateTime createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.priority,
    this.targetClassId,
    required this.createdAt,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String id) {
    return AnnouncementModel(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      priority: map['priority'] ?? 'normal',
      targetClassId: map['targetClassId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'priority': priority,
      'targetClassId': targetClassId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
