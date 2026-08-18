import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? photoUrl;
  final String? classId;
  final String? className;
  final String? nisn;
  final String? nip;
  final String? phone;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.photoUrl,
    this.classId,
    this.className,
    this.nisn,
    this.nip,
    this.phone,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      photoUrl: map['photoUrl'],
      classId: map['classId'],
      className: map['className'],
      nisn: map['nisn'],
      nip: map['nip'],
      phone: map['phone'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'photoUrl': photoUrl,
      'classId': classId,
      'className': className,
      'nisn': nisn,
      'nip': nip,
      'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? photoUrl,
    String? phone,
    String? classId,
    String? className,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      name: name ?? this.name,
      role: role,
      photoUrl: photoUrl ?? this.photoUrl,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      nisn: nisn,
      nip: nip,
      phone: phone ?? this.phone,
      createdAt: createdAt,
    );
  }
}
