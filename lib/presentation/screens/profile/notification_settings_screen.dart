import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/auth_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _newBooksNotification = true;
  bool _commentsNotification = true;
  bool _likesNotification = true;
  bool _followsNotification = true;
  bool _updatesNotification = true;
  bool _promotionsNotification = false;
  bool _emailNotification = true;
  bool _pushNotification = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _newBooksNotification =
            prefs.getBool('notif_new_books') ?? true;
        _commentsNotification =
            prefs.getBool('notif_comments') ?? true;
        _likesNotification = prefs.getBool('notif_likes') ?? true;
        _followsNotification =
            prefs.getBool('notif_follows') ?? true;
        _updatesNotification =
            prefs.getBool('notif_updates') ?? true;
        _promotionsNotification =
            prefs.getBool('notif_promotions') ?? false;
        _emailNotification = prefs.getBool('notif_email') ?? true;
        _pushNotification = prefs.getBool('notif_push') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu cài đặt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    IconData? icon,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          fontFamily: 'Roboto',
        ),
      ),
      secondary: icon != null
          ? Icon(icon, color: Colors.grey[600])
          : null,
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt thông báo'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Header Info
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.1),
                        Theme.of(context).primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Theme.of(context).primaryColor,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quản lý thông báo',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tùy chỉnh cách bạn nhận thông báo từ ứng dụng',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Notifications
                _buildSection(
                  title: 'Thông báo nội dung',
                  icon: Icons.auto_stories,
                  children: [
                    _buildSwitchTile(
                      title: 'Sách mới',
                      subtitle: 'Thông báo khi có sách mới được thêm vào',
                      icon: Icons.library_books,
                      value: _newBooksNotification,
                      onChanged: (value) {
                        setState(() => _newBooksNotification = value);
                        _saveSetting('notif_new_books', value);
                      },
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      title: 'Bình luận mới',
                      subtitle: 'Thông báo khi có người bình luận sách bạn yêu thích',
                      icon: Icons.comment,
                      value: _commentsNotification,
                      onChanged: (value) {
                        setState(() => _commentsNotification = value);
                        _saveSetting('notif_comments', value);
                      },
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      title: 'Lượt thích',
                      subtitle: 'Thông báo khi có người thích bình luận của bạn',
                      icon: Icons.favorite,
                      value: _likesNotification,
                      onChanged: (value) {
                        setState(() => _likesNotification = value);
                        _saveSetting('notif_likes', value);
                      },
                    ),
                  ],
                ),

                // Social Notifications
                _buildSection(
                  title: 'Thông báo xã hội',
                  icon: Icons.people,
                  children: [
                    _buildSwitchTile(
                      title: 'Người theo dõi mới',
                      subtitle: 'Thông báo khi có người theo dõi bạn',
                      icon: Icons.person_add,
                      value: _followsNotification,
                      onChanged: (value) {
                        setState(() => _followsNotification = value);
                        _saveSetting('notif_follows', value);
                      },
                    ),
                  ],
                ),

                // System Notifications
                _buildSection(
                  title: 'Thông báo hệ thống',
                  icon: Icons.settings_outlined,
                  children: [
                    _buildSwitchTile(
                      title: 'Cập nhật ứng dụng',
                      subtitle: 'Thông báo về các tính năng và cập nhật mới',
                      icon: Icons.system_update,
                      value: _updatesNotification,
                      onChanged: (value) {
                        setState(() => _updatesNotification = value);
                        _saveSetting('notif_updates', value);
                      },
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      title: 'Khuyến mãi & Ưu đãi',
                      subtitle: 'Nhận thông báo về các chương trình khuyến mãi',
                      icon: Icons.local_offer,
                      value: _promotionsNotification,
                      onChanged: (value) {
                        setState(() => _promotionsNotification = value);
                        _saveSetting('notif_promotions', value);
                      },
                    ),
                  ],
                ),

                // Notification Methods
                _buildSection(
                  title: 'Phương thức nhận thông báo',
                  icon: Icons.send,
                  children: [
                    _buildSwitchTile(
                      title: 'Thông báo đẩy',
                      subtitle: 'Nhận thông báo trực tiếp trên thiết bị',
                      icon: Icons.notifications,
                      value: _pushNotification,
                      onChanged: (value) {
                        setState(() => _pushNotification = value);
                        _saveSetting('notif_push', value);
                      },
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      title: 'Thông báo Email',
                      subtitle: 'Nhận thông báo qua email ${user?.email ?? ""}',
                      icon: Icons.email,
                      value: _emailNotification,
                      onChanged: (value) {
                        setState(() => _emailNotification = value);
                        _saveSetting('notif_email', value);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Test Notification Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đây là thông báo thử nghiệm!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.notification_add),
                    label: const Text(
                      'Gửi thông báo thử',
                      style: TextStyle(fontFamily: 'Roboto'),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
