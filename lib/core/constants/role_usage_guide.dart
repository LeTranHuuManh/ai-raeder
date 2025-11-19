/// Hướng dẫn sử dụng hệ thống phân quyền Admin/User
///
/// 1. Bảo vệ màn hình Admin với AdminGuard:
/// ```dart
/// class MyAdminScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return AdminGuard(
///       child: Scaffold(
///         // Your admin screen content
///       ),
///     );
///   }
/// }
/// ```
///
/// 2. Kiểm tra quyền trong code:
/// ```dart
/// final authMiddleware = AuthMiddleware();
/// final user = Provider.of<AuthProvider>(context).currentUser;
///
/// if (authMiddleware.isAdmin(user)) {
///   // User is admin
/// }
/// ```
///
/// 3. Kiểm tra quyền cụ thể:
/// ```dart
/// final roleService = RoleService();
/// final hasPermission = await roleService.hasPermission(
///   userId,
///   Permission.manageBooks,
/// );
/// ```
///
/// 4. Cấp/thu hồi quyền admin:
/// ```dart
/// final roleService = RoleService();
///
/// // Cấp quyền admin
/// await roleService.grantAdminRole(userId);
///
/// // Thu hồi quyền admin
/// await roleService.revokeAdminRole(userId);
/// ```
///
/// 5. Firestore Security Rules được tự động áp dụng:
/// - Users chỉ có thể đọc/ghi dữ liệu của chính họ
/// - Admin có thể đọc/ghi dữ liệu của tất cả users
/// - Chỉ admin mới có thể tạo/sửa/xóa sách
/// - Users không thể tự cấp quyền admin cho mình
library;
