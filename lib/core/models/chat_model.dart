import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String type; // 'private' | 'bk_confidential'
  final String? subjectId;

  const ChatRoomModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.lastMessage,
    this.lastMessageAt,
    required this.type,
    this.subjectId,
  });

  factory ChatRoomModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatRoomModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      lastMessage: map['lastMessage'],
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
      type: map['type'] ?? 'private',
      subjectId: map['subjectId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageAt':
          lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'type': type,
      'subjectId': subjectId,
    };
  }
}

class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final String type; // 'text' | 'image' | 'file'
  final String? fileUrl;
  final DateTime sentAt;
  final bool isRead;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    this.fileUrl,
    required this.sentAt,
    this.isRead = false,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      type: map['type'] ?? 'text',
      fileUrl: map['fileUrl'],
      sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type,
      'fileUrl': fileUrl,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
    };
  }
}
