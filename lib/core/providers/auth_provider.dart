import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _userModel;
  bool _isLoading = true;
  String? _error;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _userModel != null;
  String? get error => _error;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    _isLoading = true;
    notifyListeners();
    if (user == null) {
      _userModel = null;
    } else {
      _userModel = await _authService.getUserData(user.uid);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      _userModel = await _authService.signIn(email, password);
      _isLoading = false;
      notifyListeners();
      return _userModel != null;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  void refreshUser() async {
    if (_authService.currentUser != null) {
      _userModel =
          await _authService.getUserData(_authService.currentUser!.uid);
      notifyListeners();
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      default:
        return 'Login gagal. Periksa kredensial Anda.';
    }
  }
}
