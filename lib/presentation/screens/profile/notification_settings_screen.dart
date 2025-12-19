import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Email Notifications
  bool _emailNewContent = true;
  bool _emailUpdates = true;
  bool _emailPromotions = false;

  // Push Notifications
  bool _pushNewContent = true;
  bool _pushComments = true;
  bool _pushLikes = false;
  bool _pushFollows = true;

  // System Notifications
  bool _systemUpdates = true;
  bool _systemSecurity = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _loadSettings();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Email
      _emailNewContent = prefs.getBool('email_new_content') ?? true;
      _emailUpdates = prefs.getBool('email_updates') ?? true;
      _emailPromotions = prefs.getBool('email_promotions') ?? false;

      // Push
      _pushNewContent = prefs.getBool('push_new_content') ?? true;
      _pushComments = prefs.getBool('push_comments') ?? true;
      _pushLikes = prefs.getBool('push_likes') ?? false;
      _pushFollows = prefs.getBool('push_follows') ?? true;

      // System
      _systemUpdates = prefs.getBool('system_updates') ?? true;
      _systemSecurity = prefs.getBool('system_security') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _showTestNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Đây là thông báo thử nghiệm!',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD3DA95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFD3DA95),
              const Color(0xFFD3DA95).withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Cài đặt thông báo',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _showTestNotification,
                      icon: const Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          // Email Notifications
                          _buildSectionCard(
                            title: 'Thông báo Email',
                            icon: Icons.email_outlined,
                            color: const Color(0xFFD3DA95),
                            children: [
                              _buildSwitchTile(
                                title: 'Nội dung mới',
                                subtitle:
                                    'Nhận email khi có sách hoặc bài viết mới',
                                value: _emailNewContent,
                                icon: Icons.fiber_new,
                                onChanged: (value) {
                                  setState(() => _emailNewContent = value);
                                  _saveSetting('email_new_content', value);
                                },
                              ),
                              _buildSwitchTile(
                                title: 'Cập nhật',
                                subtitle:
                                    'Thông tin cập nhật về tài khoản và hoạt động',
                                value: _emailUpdates,
                                icon: Icons.update,
                                onChanged: (value) {
                                  setState(() => _emailUpdates = value);
                                  _saveSetting('email_updates', value);
                                },
                              ),
                              _buildSwitchTile(
                                title: 'Khuyến mãi',
                                subtitle:
                                    'Nhận thông tin về chương trình khuyến mãi',
                                value: _emailPromotions,
                                icon: Icons.local_offer,
                                onChanged: (value) {
                                  setState(() => _emailPromotions = value);
                                  _saveSetting('email_promotions', value);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Push Notifications
                          _buildSectionCard(
                            title: 'Thông báo đẩy',
                            icon: Icons.notifications_outlined,
                            color: const Color(0xFFFF6B9D),
                            children: [
                              _buildSwitchTile(
                                title: 'Nội dung mới',
                                subtitle:
                                    'Thông báo khi có sách mới được thêm vào',
                                value: _pushNewContent,
                                icon: Icons.library_books,
                                onChanged: (value) {
                                  setState(() => _pushNewContent = value);
                                  _saveSetting('push_new_content', value);
                                },
                              ),
                              _buildSwitchTile(
                                title: 'Bình luận',
                                subtitle: 'Thông báo khi có người bình luận',
                                value: _pushComments,
                                icon: Icons.comment,
                                onChanged: (value) {
                                  setState(() => _pushComments = value);
                                  _saveSetting('push_comments', value);
                                },
                              ),
                              _buildSwitchTile(
                                title: 'Lượt thích',
                                subtitle:
                                    'Thông báo khi có người thích nội dung của bạn',
                                value: _pushLikes,
                                icon: Icons.favorite,
                                onChanged: (value) {
                                  setState(() => _pushLikes = value);
                                  _saveSetting('push_likes', value);
                                },
                              ),
                              _buildSwitchTile(
                                title: 'Người theo dõi mới',
                                subtitle: 'Thông báo khi có người theo dõi bạn',
                                value: _pushFollows,
                                icon: Icons.person_add,
                                onChanged: (value) {
                                  setState(() => _pushFollows = value);
                                  _saveSetting('push_follows', value);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // System Notifications
                          _buildSectionCard(
                            title: 'Thông báo hệ thống',
                            icon: Icons.settings_outlined,
                            color: const Color(0xFF4CAF50),
                            children: [
                              _buildSwitchTile(
                                title: 'Cập nhật ứng dụng',
                                subtitle: 'Thông báo khi có phiên bản mới',
                                value: _systemUpdates,
                                icon: Icons.system_update,
                                onChanged: (value) {
                                  setState(() => _systemUpdates = value);
                                  _saveSetting('system_updates', value);
                                },
                              ),
                              _buildSwitchTile(
                                title: 'Bảo mật',
                                subtitle: 'Cảnh báo về hoạt động bất thường',
                                value: _systemSecurity,
                                icon: Icons.security,
                                onChanged: (value) {
                                  setState(() => _systemSecurity = value);
                                  _saveSetting('system_security', value);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Info Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFD3DA95).withOpacity(0.1),
                                  const Color(0xFFD3DA95).withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFD3DA95,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Color(0xFFD3DA95),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    'Bạn có thể thay đổi cài đặt thông báo bất cứ lúc nào. Các thay đổi sẽ có hiệu lực ngay lập tức.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFFD3DA95),
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFFD3DA95).withOpacity(0.05)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? const Color(0xFFD3DA95).withOpacity(0.3)
              : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: value ? const Color(0xFFD3DA95) : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: value ? const Color(0xFF2D3142) : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4, left: 28),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ),
        activeColor: const Color(0xFFD3DA95),
        activeTrackColor: const Color(0xFFD3DA95).withOpacity(0.3),
        inactiveTrackColor: Colors.grey[300],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
