import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/admin_guard.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản trị'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            // Temporary: Allow direct access for first-time setup
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Thông tin',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Hướng dẫn truy cập Admin'),
                    content: const Text(
                      'Để truy cập trang admin:\n\n'
                      '1. Đăng nhập vào app\n'
                      '2. Mở menu drawer (bên trái)\n'
                      '3. Chọn "Quản trị"\n\n'
                      'Nếu chưa thấy menu "Quản trị":\n'
                      '- Vào Firebase Console\n'
                      '- Firestore Database → collection "users"\n'
                      '- Tìm user của bạn và set isAdmin = true',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildDashboardCard(
                context,
                icon: Icons.book,
                title: 'Quản lý sách',
                subtitle: 'Thêm, sửa, xóa sách',
                color: AppColors.primary,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.adminBooks);
                },
              ),
              _buildDashboardCard(
                context,
                icon: Icons.category,
                title: 'Quản lý thể loại',
                subtitle: 'Thêm, sửa, xóa thể loại',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.adminCategories);
                },
              ),
              _buildDashboardCard(
                context,
                icon: Icons.people,
                title: 'Quản lý người dùng',
                subtitle: 'Xem và quản lý người dùng',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.adminUsers);
                },
              ),
              _buildDashboardCard(
                context,
                icon: Icons.analytics,
                title: 'Thống kê',
                subtitle: 'Xem thống kê ứng dụng',
                color: AppColors.info,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.adminStatistics);
                },
              ),
              _buildDashboardCard(
                context,
                icon: Icons.settings,
                title: 'Cài đặt',
                subtitle: 'Cấu hình hệ thống',
                color: AppColors.warning,
                onTap: () {
                  // TODO: Implement settings screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng đang phát triển')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
