import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  GoogleSignIn? _googleSignIn;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFirebaseAvailable = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isFirebaseAvailable => _isFirebaseAvailable;

  AuthProvider() {
    _initializeFirebase();
  }

  void _initializeFirebase() {
    // Use a microtask to ensure Firebase is initialized first
    // This is called after main() completes Firebase initialization
    Future.microtask(() {
      try {
        // Check if Firebase is initialized
        try {
          Firebase.app(); // This will throw if not initialized
          // Firebase is initialized, proceed with setup
          _auth = FirebaseAuth.instance;
          _firestore = FirebaseFirestore.instance;
          _isFirebaseAvailable = true;
          _errorMessage = null; // Clear any error
          _initAuthListener();
          debugPrint('✅ Firebase initialized successfully in AuthProvider');
          notifyListeners();
        } catch (e) {
          // Firebase not initialized
          debugPrint('Firebase not initialized in AuthProvider: $e');
          _isFirebaseAvailable = false;
          _errorMessage =
              'Firebase chưa được cấu hình. Vui lòng kiểm tra cấu hình Firebase.';
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Firebase error in AuthProvider: $e');
        _isFirebaseAvailable = false;
        _errorMessage =
            'Firebase chưa được cấu hình. Vui lòng kiểm tra cấu hình Firebase.';
        notifyListeners();
      }
    });

    // Initialize GoogleSignIn lazily (only when needed)
    // This avoids errors if Google Sign In is not configured
    // GoogleSignIn will be initialized in signInWithGoogle() if needed
  }

  Future<void> _ensureGoogleSignIn() async {
    if (_googleSignIn != null) return;

    try {
      // Initialize GoogleSignIn - this may throw if clientId is not set on web
      _googleSignIn = GoogleSignIn();
    } catch (e) {
      debugPrint(
        'GoogleSignIn initialization failed (likely missing clientId): $e',
      );
      _googleSignIn = null;
      // Will show error message when user tries to use it
    }
  }

  void _initAuthListener() {
    if (_auth == null) return;
    _auth!.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        await _loadUserData(firebaseUser.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    if (_firestore == null) return;
    try {
      final doc = await _firestore!.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!);
        notifyListeners();
      } else {
        // User document doesn't exist, create it from Firebase Auth user
        debugPrint('User document not found, creating from Firebase Auth user');
        final firebaseUser = _auth?.currentUser;
        if (firebaseUser != null) {
          final newUser = UserModel.fromFirebaseUser(firebaseUser);
          try {
            await _firestore!.collection('users').doc(uid).set(newUser.toMap());
            _currentUser = newUser;
            notifyListeners();
          } catch (e) {
            debugPrint('Error creating user document: $e');
            // Still set current user from Firebase Auth even if Firestore fails
            _currentUser = newUser;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Try to create user from Firebase Auth as fallback
      final firebaseUser = _auth?.currentUser;
      if (firebaseUser != null) {
        _currentUser = UserModel.fromFirebaseUser(firebaseUser);
        notifyListeners();
      } else {
        _errorMessage = 'Lỗi tải thông tin người dùng: ${e.toString()}';
        notifyListeners();
      }
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    if (_auth == null || _firestore == null) {
      _errorMessage = 'Firebase chưa được cấu hình';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Load user data first (this will create user document if it doesn't exist)
      await _loadUserData(userCredential.user!.uid);
      // Then update last login
      await _updateLastLogin(userCredential.user!.uid);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      // Check if it's a network error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('network') ||
          errorString.contains('unreachable') ||
          errorString.contains('timeout') ||
          errorString.contains('no address') ||
          errorString.contains('failed to resolve')) {
        _errorMessage =
            'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối Internet và thử lại';
      } else {
        _errorMessage = 'Lỗi đăng nhập: ${e.toString()}';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    if (_auth == null || _firestore == null) {
      _errorMessage = 'Firebase chưa được cấu hình';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _auth!.createUserWithEmailAndPassword(
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

      await _firestore!
          .collection('users')
          .doc(newUser.id)
          .set(newUser.toMap());
      _currentUser = newUser;

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi đăng ký: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    if (_auth == null || _firestore == null) {
      _errorMessage = 'Firebase chưa được cấu hình';
      notifyListeners();
      return false;
    }

    // Initialize GoogleSignIn if not already done
    await _ensureGoogleSignIn();

    if (_googleSignIn == null) {
      _errorMessage =
          'Google Sign In chưa được cấu hình. Vui lòng thêm Google Client ID vào web/index.html';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
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

      final userCredential = await _auth!.signInWithCredential(credential);

      final userDoc = await _firestore!
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        final newUser = UserModel.fromFirebaseUser(userCredential.user!);
        await _firestore!
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
    if (_auth != null) {
      await _auth!.signOut();
    }
    if (_googleSignIn != null) {
      await _googleSignIn!.signOut();
    }
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _updateLastLogin(String uid) async {
    if (_firestore == null) return;
    try {
      // Check if user document exists first
      final userDoc = await _firestore!.collection('users').doc(uid).get();
      if (userDoc.exists) {
        await _firestore!.collection('users').doc(uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      } else {
        // If user document doesn't exist, create it
        // This can happen if user was created in Firebase Auth but not in Firestore
        debugPrint(
          'User document not found, creating new user document for uid: $uid',
        );
        final firebaseUser = _auth?.currentUser;
        if (firebaseUser != null) {
          final newUser = UserModel.fromFirebaseUser(firebaseUser);
          await _firestore!.collection('users').doc(uid).set(newUser.toMap());
        }
      }
    } catch (e) {
      debugPrint('Error updating last login: $e');
      // Don't throw error, just log it - login should still succeed
    }
  }

  Future<bool> resetPassword(String email) async {
    if (_auth == null) {
      _errorMessage = 'Firebase chưa được cấu hình';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      await _auth!.sendPasswordResetEmail(email: email);

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

  /// Update user profile (display name, phone, photo)
  Future<bool> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    if (_auth == null || _firestore == null) return false;
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uid = _currentUser!.id;
      final updateData = <String, dynamic>{};

      if (displayName != null) {
        updateData['displayName'] = displayName;
        // Also update Firebase Auth profile
        await _auth!.currentUser?.updateDisplayName(displayName);
      }

      if (phoneNumber != null) {
        updateData['phoneNumber'] = phoneNumber;
      }

      if (photoUrl != null) {
        updateData['photoUrl'] = photoUrl;
        // Also update Firebase Auth profile
        await _auth!.currentUser?.updatePhotoURL(photoUrl);
      }

      if (updateData.isNotEmpty) {
        // Update Firestore
        await _firestore!.collection('users').doc(uid).update(updateData);

        // Reload user data
        await _loadUserData(uid);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi cập nhật hồ sơ: ${e.toString()}';
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
      case 'network-request-failed':
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối Internet và thử lại';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được kích hoạt';
      default:
        return 'Đã xảy ra lỗi: $code';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
