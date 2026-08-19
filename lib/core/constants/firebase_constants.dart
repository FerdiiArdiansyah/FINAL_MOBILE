class FirebaseConstants {
  FirebaseConstants._();

  // Collections
  static const String usersCollection = 'users';
  static const String materialsCollection = 'materials';
  static const String assignmentsCollection = 'assignments';
  static const String submissionsSubCollection = 'submissions';
  static const String attendanceCollection = 'attendance';
  static const String pelanggaranCollection = 'pelanggaran';
  static const String konselingCollection = 'konseling';
  static const String chatRoomsCollection = 'chatRooms';
  static const String messagesSubCollection = 'messages';
  static const String announcementsCollection = 'announcements';
  static const String piketLogCollection = 'piketLog';
  static const String schedulesCollection = 'schedules';
  static const String notificationsCollection = 'notifications';
  static const String classesCollection = 'classes';

  // Storage paths
  static const String materialsStoragePath = 'materials';
  static const String assignmentsStoragePath = 'assignments';
  static const String profilesStoragePath = 'profiles';
  static const String piketStoragePath = 'piket';

  // FCM topics
  static const String allUsersTopic = 'all_users';
  static const String siswaTopicPrefix = 'class_';
}
