import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/admin_guard.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/loading_widget.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final snapshot = await _firestore.collection('users').get();
      setState(() {
        _users = snapshot.docs
            .map((doc) => UserModel.fromMap({'id': doc.id, ...doc.data()}))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _toggleAdminStatus(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          user.isAdmin ? 'Xóa quyền admin' : 'Cấp quyền admin',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          user.isAdmin
              ? 'Bạn có chắc muốn xóa quyền admin của "${user.displayName}"?'
              : 'Bạn có chắc muốn cấp quyền admin cho "${user.displayName}"?',
          style: const TextStyle(fontFamily: 'Roboto', fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Xác nhận',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('users').doc(user.id).update({
          'isAdmin': !user.isAdmin,
        });
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                user.isAdmin
                    ? 'Đã xóa quyền admin'
                    : 'Đã cấp quyền admin thành công',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
        }
      }
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xóa người dùng "${user.displayName}"?\n\n'
          'Hành động này không thể hoàn tác.',
          style: const TextStyle(fontFamily: 'Roboto', fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(
              'Xóa',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('users').doc(user.id).delete();
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa người dùng thành công')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa người dùng: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          user.displayName,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', user.email),
              if (user.phoneNumber != null)
                _buildDetailRow('Số điện thoại', user.phoneNumber!),
              _buildDetailRow(
                'Ngày tạo',
                user.createdAt.toString().split(' ')[0],
              ),
              if (user.lastLoginAt != null)
                _buildDetailRow(
                  'Đăng nhập lần cuối',
                  user.lastLoginAt!.toString().split(' ')[0],
                ),
              _buildDetailRow('Quyền admin', user.isAdmin ? 'Có' : 'Không'),
              _buildDetailRow(
                'Sách yêu thích',
                '${user.favoriteBooks.length} cuốn',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Đóng',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<UserModel> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      return user.displayName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Quản lý người dùng',
            style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadUsers,
              tooltip: 'Làm mới',
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                style: const TextStyle(fontFamily: 'Roboto', fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm người dùng...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                  ),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.people, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Tổng số: ${_users.length} người dùng',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const LoadingWidget()
                  : _filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Chưa có người dùng nào'
                                : 'Không tìm thấy người dùng',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return _buildUserItem(user);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserItem(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: user.photoUrl != null
              ? CachedNetworkImageProvider(user.photoUrl!)
              : null,
          child: user.photoUrl == null
              ? Text(
                  user.displayName[0].toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user.displayName,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (user.isAdmin) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite, size: 14, color: AppColors.error),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${user.favoriteBooks.length} sách yêu thích',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              iconSize: 20,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Xem chi tiết',
              onPressed: () => _showUserDetails(user),
            ),
            IconButton(
              icon: Icon(
                user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                size: 20,
                color: user.isAdmin
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              iconSize: 20,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: user.isAdmin ? 'Xóa quyền admin' : 'Cấp quyền admin',
              onPressed: () => _toggleAdminStatus(user),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
              iconSize: 20,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Xóa người dùng',
              onPressed: () => _deleteUser(user),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () => _showUserDetails(user),
      ),
    );
  }
}
