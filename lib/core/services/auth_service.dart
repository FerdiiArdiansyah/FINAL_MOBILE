import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../constants/firebase_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;
    return getUserData(user.uid);
  }

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Admin creates users
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
    String? classId,
    String? className,
    String? nisn,
    String? nip,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;
    final user = UserModel(
      uid: uid,
      email: email.trim(),
      name: name,
      role: role,
      classId: classId,
      className: className,
      nisn: nisn,
      nip: nip,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .set(user.toMap());
    return user;
  }
}
