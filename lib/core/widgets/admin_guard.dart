import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../middleware/auth_middleware.dart';

/// Widget wrapper to protect admin-only routes
class AdminGuard extends StatelessWidget {
  final Widget child;
  final String? redirectRoute;

  const AdminGuard({super.key, required this.child, this.redirectRoute});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final middleware = AuthMiddleware();
        final user = authProvider.currentUser;

        // Check authentication first
        if (!middleware.isAuthenticated(user)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check admin role
        if (!middleware.isAdmin(user)) {
          return Scaffold(
            appBar: AppBar(title: const Text('Không có quyền truy cập')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
                  const SizedBox(height: 24),
                  const Text(
                    'Bạn không có quyền truy cập trang này',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chỉ quản trị viên mới có thể truy cập.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(redirectRoute ?? '/home');
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Về trang chủ'),
                  ),
                ],
              ),
            ),
          );
        }

        // User is admin, show the protected content
        return child;
      },
    );
  }
}
