import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service to manage user roles and permissions
class RoleService {
  static final RoleService _instance = RoleService._internal();
  factory RoleService() => _instance;
  RoleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if a user is admin
  Future<bool> isAdmin(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      return userData?['isAdmin'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Check if current user is admin (from UserModel)
  bool isAdminUser(UserModel? user) {
    return user?.isAdmin ?? false;
  }

  /// Grant admin role to a user
  Future<bool> grantAdminRole(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': true,
        'roleUpdatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Revoke admin role from a user
  Future<bool> revokeAdminRole(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': false,
        'roleUpdatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all admin users
  Future<List<UserModel>> getAllAdmins() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all regular users (non-admin)
  Future<List<UserModel>> getAllUsers({bool includeAdmins = false}) async {
    try {
      Query query = _firestore.collection('users');

      if (!includeAdmins) {
        query = query.where('isAdmin', isEqualTo: false);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map(
            (doc) => UserModel.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if user has permission to perform an action
  Future<bool> hasPermission(String userId, Permission permission) async {
    final isAdminUser = await isAdmin(userId);

    switch (permission) {
      case Permission.manageBooks:
      case Permission.manageUsers:
      case Permission.viewAnalytics:
      case Permission.manageComments:
        return isAdminUser;

      case Permission.readBooks:
      case Permission.writeComments:
      case Permission.editOwnProfile:
        return true; // All authenticated users can do these
    }
  }

  /// Validate that current user can access admin routes
  Future<bool> canAccessAdminPanel(String userId) async {
    return await isAdmin(userId);
  }

  /// Get user role name
  Future<String> getUserRole(String userId) async {
    final isAdminUser = await isAdmin(userId);
    return isAdminUser ? 'Admin' : 'User';
  }
}

/// Enum for user permissions
enum Permission {
  // Admin permissions
  manageBooks,
  manageUsers,
  viewAnalytics,
  manageComments,

  // User permissions
  readBooks,
  writeComments,
  editOwnProfile,
}

/// Role constants
class UserRole {
  static const String admin = 'admin';
  static const String user = 'user';

  static List<String> get allRoles => [admin, user];

  static bool isValidRole(String role) {
    return allRoles.contains(role.toLowerCase());
  }
}
