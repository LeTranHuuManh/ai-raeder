import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/services/role_service.dart';

/// Middleware to check authentication and authorization
class AuthMiddleware {
  static final AuthMiddleware _instance = AuthMiddleware._internal();
  factory AuthMiddleware() => _instance;
  AuthMiddleware._internal();

  final RoleService _roleService = RoleService();

  /// Check if user is authenticated
  bool isAuthenticated(UserModel? user) {
    return user != null;
  }

  /// Check if user is admin
  bool isAdmin(UserModel? user) {
    return _roleService.isAdminUser(user);
  }

  /// Require authentication - navigate to login if not authenticated
  bool requireAuth(BuildContext context, UserModel? user) {
    if (!isAuthenticated(user)) {
      Navigator.of(context).pushReplacementNamed('/login');
      return false;
    }
    return true;
  }

  /// Require admin role - show error if not admin
  bool requireAdmin(BuildContext context, UserModel? user) {
    if (!isAuthenticated(user)) {
      Navigator.of(context).pushReplacementNamed('/login');
      return false;
    }

    if (!isAdmin(user)) {
      _showUnauthorizedDialog(context);
      return false;
    }

    return true;
  }

  /// Check permission for specific action
  Future<bool> checkPermission(String userId, Permission permission) async {
    return await _roleService.hasPermission(userId, permission);
  }

  /// Show unauthorized dialog
  void _showUnauthorizedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Không có quyền truy cập'),
        content: const Text(
          'Bạn không có quyền truy cập tính năng này. '
          'Vui lòng liên hệ quản trị viên để được cấp quyền.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Show permission denied snackbar
  void showPermissionDenied(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bạn không có quyền thực hiện thao tác này'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
