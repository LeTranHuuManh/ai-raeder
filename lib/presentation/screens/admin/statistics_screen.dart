import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/admin_guard.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all statistics in parallel
      final results = await Future.wait([
        _getTotalBooks(),
        _getTotalUsers(),
        _getTotalCategories(),
        _getTotalComments(),
        _getTotalViews(),
        _getTopBooks(),
        _getTopCategories(),
        _getRecentBooks(),
      ]);

      setState(() {
        _stats = {
          'totalBooks': results[0],
          'totalUsers': results[1],
          'totalCategories': results[2],
          'totalComments': results[3],
          'totalViews': results[4],
          'topBooks': results[5],
          'topCategories': results[6],
          'recentBooks': results[7],
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thống kê: ${e.toString()}')),
        );
      }
    }
  }

  Future<int> _getTotalBooks() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getTotalUsers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getTotalCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getTotalComments() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('comments')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getTotalViews() async {
    final snapshot = await FirebaseFirestore.instance.collection('books').get();
    int total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['viewCount'] ?? 0) as int;
    }
    return total;
  }

  Future<List<Map<String, dynamic>>> _getTopBooks() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .orderBy('viewCount', descending: true)
        .limit(5)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'author': data['author'] ?? '',
        'viewCount': data['viewCount'] ?? 0,
        'rating': (data['rating'] ?? 0.0).toDouble(),
        'coverImageUrl': data['coverImageUrl'] ?? '',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getTopCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .orderBy('bookCount', descending: true)
        .limit(5)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? '',
        'bookCount': data['bookCount'] ?? 0,
        'color': data['color'] ?? AppColors.primary.toString(),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getRecentBooks() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'author': data['author'] ?? '',
        'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        'coverImageUrl': data['coverImageUrl'] ?? '',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Thống kê'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadStatistics,
              tooltip: 'Làm mới',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadStatistics,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Overview Cards
                      _buildOverviewSection(),
                      const SizedBox(height: 20),
                      // Top Books Section
                      _buildTopBooksSection(),
                      const SizedBox(height: 20),
                      // Top Categories Section
                      _buildTopCategoriesSection(),
                      const SizedBox(height: 20),
                      // Recent Books Section
                      _buildRecentBooksSection(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tổng quan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            _buildStatCard(
              icon: Icons.menu_book_rounded,
              title: 'Tổng sách',
              value: '${_stats['totalBooks'] ?? 0}',
              color: AppColors.primary,
              gradient: AppColors.primaryGradient,
            ),
            _buildStatCard(
              icon: Icons.people_rounded,
              title: 'Người dùng',
              value: '${_stats['totalUsers'] ?? 0}',
              color: AppColors.secondary,
              gradient: AppColors.secondaryGradient,
            ),
            _buildStatCard(
              icon: Icons.category_rounded,
              title: 'Thể loại',
              value: '${_stats['totalCategories'] ?? 0}',
              color: AppColors.info,
              gradient: const LinearGradient(
                colors: [AppColors.info, Color(0xFF60A5FA)],
              ),
            ),
            _buildStatCard(
              icon: Icons.comment_rounded,
              title: 'Bình luận',
              value: '${_stats['totalComments'] ?? 0}',
              color: AppColors.warning,
              gradient: const LinearGradient(
                colors: [AppColors.warning, Color(0xFFFBBF24)],
              ),
            ),
            _buildStatCard(
              icon: Icons.visibility_rounded,
              title: 'Lượt xem',
              value: '${_formatNumber(_stats['totalViews'] ?? 0)}',
              color: AppColors.success,
              gradient: const LinearGradient(
                colors: [AppColors.success, Color(0xFF34D399)],
              ),
            ),
            _buildStatCard(
              icon: Icons.star_rounded,
              title: 'Đánh giá TB',
              value: _calculateAverageRating(),
              color: Colors.amber,
              gradient: const LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Gradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBooksSection() {
    final topBooks = _stats['topBooks'] as List<Map<String, dynamic>>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sách phổ biến nhất',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Top 5',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (topBooks.isEmpty)
          _buildEmptyState('Chưa có dữ liệu sách')
        else
          ...topBooks.asMap().entries.map((entry) {
            final index = entry.key;
            final book = entry.value;
            return _buildTopBookItem(book, index + 1);
          }),
      ],
    );
  }

  Widget _buildTopBookItem(Map<String, dynamic> book, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: rank <= 3
                  ? LinearGradient(
                      colors: rank == 1
                          ? [Colors.amber, Colors.orange]
                          : rank == 2
                          ? [Colors.grey, Colors.grey.shade700]
                          : [Colors.brown, Colors.brown.shade700],
                    )
                  : AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Book Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              book['coverImageUrl'] ?? '',
              width: 50,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 50,
                height: 70,
                color: AppColors.gray200,
                child: const Icon(Icons.book, color: AppColors.gray400),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Book Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  book['author'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${_formatNumber(book['viewCount'] ?? 0)} lượt xem',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          (book['rating'] ?? 0.0).toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategoriesSection() {
    final topCategories =
        _stats['topCategories'] as List<Map<String, dynamic>>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Thể loại phổ biến',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Top 5',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (topCategories.isEmpty)
          _buildEmptyState('Chưa có dữ liệu thể loại')
        else
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.7,
            children: topCategories.map((category) {
              return _buildCategoryCard(category);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.category_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  '${category['bookCount'] ?? 0}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              category['name'] ?? '',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'sách',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBooksSection() {
    final recentBooks =
        _stats['recentBooks'] as List<Map<String, dynamic>>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sách mới nhất',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (recentBooks.isEmpty)
          _buildEmptyState('Chưa có sách mới')
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentBooks.length,
              itemBuilder: (context, index) {
                final book = recentBooks[index];
                return _buildRecentBookCard(book);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecentBookCard(Map<String, dynamic> book) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              book['coverImageUrl'] ?? '',
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: double.infinity,
                height: 180,
                color: AppColors.gray200,
                child: const Icon(Icons.book, color: AppColors.gray400),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book['title'] ?? '',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            book['author'] ?? '',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: AppColors.gray400),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _calculateAverageRating() {
    final topBooks = _stats['topBooks'] as List<Map<String, dynamic>>? ?? [];
    if (topBooks.isEmpty) return '0.0';
    double total = 0;
    int count = 0;
    for (var book in topBooks) {
      final rating = (book['rating'] ?? 0.0).toDouble();
      if (rating > 0) {
        total += rating;
        count++;
      }
    }
    return count > 0 ? (total / count).toStringAsFixed(1) : '0.0';
  }
}
