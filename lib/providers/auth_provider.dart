import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        await _loadUserData(firebaseUser.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Lỗi tải thông tin người dùng: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _updateLastLogin(userCredential.user!.uid);
      await _loadUserData(userCredential.user!.uid);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(displayName);

      final newUser = UserModel(
        id: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());
      _currentUser = newUser;

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        final newUser = UserModel.fromFirebaseUser(userCredential.user!);
        await _firestore
            .collection('users')
            .doc(newUser.id)
            .set(newUser.toMap());
        _currentUser = newUser;
      } else {
        await _updateLastLogin(userCredential.user!.uid);
        await _loadUserData(userCredential.user!.uid);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi đăng nhập Google: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _updateLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi gửi email: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email không tồn tại';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'weak-password':
        return 'Mật khẩu quá yếu';
      case 'invalid-email':
        return 'Email không hợp lệ';
      default:
        return 'Đã xảy ra lỗi';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
