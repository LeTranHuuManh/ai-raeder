import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/comment_model.dart';
import '../../../providers/book_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';

class BookDetailScreen extends StatefulWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  BookModel? _book;
  bool _isLoading = true;
  bool _isFavorite = false;
  List<CommentModel> _comments = [];
  final TextEditingController _commentController = TextEditingController();
  double _userRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBookDetails();
    _loadComments();
    _checkFavorite();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadBookDetails() async {
    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      await bookProvider.fetchBookById(widget.bookId);

      final book = bookProvider.books.firstWhere(
        (b) => b.id == widget.bookId,
        orElse: () => _book!,
      );

      setState(() {
        _book = book;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thông tin sách: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadComments() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.id;

      // Load tất cả comments của sách này
      final snapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('bookId', isEqualTo: widget.bookId)
          .get();

      final allComments = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              return CommentModel.fromMap({'id': doc.id, ...data});
            } catch (e) {
              debugPrint('Lỗi parse comment ${doc.id}: $e');
              return null;
            }
          })
          .whereType<CommentModel>()
          .where((comment) {
            // Hiển thị comments đã được approve HOẶC comments của chính user hiện tại
            return comment.isApproved || comment.userId == currentUserId;
          })
          .toList();

      // Sắp xếp theo thời gian tạo (mới nhất trước)
      allComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint(
        'Loaded ${allComments.length} comments for book ${widget.bookId}',
      );

      setState(() {
        _comments = allComments;
      });
    } catch (e) {
      debugPrint('Lỗi load comments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải bình luận: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _checkFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      setState(() {
        _isFavorite = user.favoriteBooks.contains(widget.bookId);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để thêm vào yêu thích'),
          ),
        );
      }
      return;
    }

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.id);
      final favoriteBooks = List<String>.from(user.favoriteBooks);

      if (_isFavorite) {
        favoriteBooks.remove(widget.bookId);
      } else {
        favoriteBooks.add(widget.bookId);
      }

      await userRef.update({'favoriteBooks': favoriteBooks});

      setState(() {
        _isFavorite = !_isFavorite;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite ? 'Đã thêm vào yêu thích' : 'Đã xóa khỏi yêu thích',
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

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty || _userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đánh giá và nội dung')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đánh giá')),
      );
      return;
    }

    try {
      final comment = CommentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bookId: widget.bookId,
        userId: user.id,
        userName: user.displayName,
        userPhotoUrl: user.photoUrl,
        content: _commentController.text.trim(),
        rating: _userRating,
        createdAt: DateTime.now(),
      );

      // Lưu comment vào Firestore
      await FirebaseFirestore.instance
          .collection('comments')
          .doc(comment.id)
          .set(comment.toMap());

      debugPrint('Đã lưu comment: ${comment.id}');

      // Tính lại và cập nhật rating trung bình của sách
      await _updateBookRating();

      // Xóa form
      _commentController.clear();
      setState(() {
        _userRating = 0.0;
      });

      // Reload comments để hiển thị comment mới
      await _loadComments();
      debugPrint('Đã reload comments, số lượng: ${_comments.length}');

      // Reload book details để cập nhật rating
      await _loadBookDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi đánh giá thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi đánh giá: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateBookRating() async {
    try {
      // Lấy tất cả comments đã được approve của sách này
      final snapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('bookId', isEqualTo: widget.bookId)
          .where('isApproved', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        // Nếu không có comment nào được approve, set rating = 0 và reviewCount = 0
        await FirebaseFirestore.instance
            .collection('books')
            .doc(widget.bookId)
            .update({'rating': 0.0, 'reviewCount': 0});
        debugPrint('Đã cập nhật rating: 0.0 (0 reviews)');
        return;
      }

      // Tính tổng rating và số lượng comments
      double totalRating = 0.0;
      int reviewCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final rating = (data['rating'] ?? 0.0).toDouble();
        if (rating > 0) {
          totalRating += rating;
          reviewCount++;
        }
      }

      // Tính rating trung bình
      final averageRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;

      // Làm tròn đến 1 chữ số thập phân
      final roundedRating = double.parse(averageRating.toStringAsFixed(1));

      // Cập nhật rating và reviewCount vào Firestore
      await FirebaseFirestore.instance
          .collection('books')
          .doc(widget.bookId)
          .update({'rating': roundedRating, 'reviewCount': reviewCount});

      debugPrint('Đã cập nhật rating: $roundedRating ($reviewCount reviews)');
    } catch (e) {
      debugPrint('Lỗi cập nhật rating: $e');
      // Không throw error để không ảnh hưởng đến việc gửi comment
    }
  }

  Future<void> _navigateToReader() async {
    if (_book != null) {
      try {
        // Tăng lượt xem lên 1
        final newViewCount = (_book!.viewCount) + 1;

        // Cập nhật vào Firestore
        await FirebaseFirestore.instance
            .collection('books')
            .doc(_book!.id)
            .update({'viewCount': newViewCount});

        // Cập nhật state local để hiển thị ngay
        setState(() {
          _book = _book!.copyWith(viewCount: newViewCount);
        });

        // Navigate to reader screen
        if (mounted) {
          Navigator.of(context).pushNamed(AppRoutes.reader, arguments: _book);
        }
      } catch (e) {
        // Nếu có lỗi khi cập nhật lượt xem, vẫn cho phép đọc sách
        debugPrint('Lỗi cập nhật lượt xem: $e');
        if (mounted) {
          Navigator.of(context).pushNamed(AppRoutes.reader, arguments: _book);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết sách')),
        body: const LoadingWidget(),
      );
    }

    if (_book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết sách')),
        body: const Center(child: Text('Không tìm thấy sách')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBookHeader(),
                _buildBookInfo(),
                _buildDescription(),
                _buildActionButtons(),
                _buildCommentsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: CachedNetworkImage(
          imageUrl: _book!.coverImageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: AppColors.gray200,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: AppColors.gray200,
            child: const Icon(Icons.book, size: 100),
          ),
        ),
      ),
    );
  }

  Widget _buildBookHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _book!.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _book!.author,
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              RatingBarIndicator(
                rating: _book!.rating,
                itemBuilder: (context, index) =>
                    const Icon(Icons.star, color: Colors.amber),
                itemCount: 5,
                itemSize: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${_book!.rating.toStringAsFixed(1)} (${_book!.reviewCount})',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildInfoChip(Icons.category, _book!.category),
          _buildInfoChip(Icons.language, _book!.language.toUpperCase()),
          _buildInfoChip(Icons.book, '${_book!.pageCount} trang'),
          _buildInfoChip(Icons.visibility, '${_book!.viewCount} lượt xem'),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: AppColors.primary.withOpacity(0.1),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mô tả',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _book!.description,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _navigateToReader,
              icon: const Icon(Icons.book),
              label: const Text('Đọc ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? AppColors.error : AppColors.textSecondary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.gray100,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title - compact
          Row(
            children: [
              Icon(Icons.star_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Đánh giá',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Comment form
          _buildCommentForm(),
          const SizedBox(height: 24),
          // Comments list header - compact
          Row(
            children: [
              Text(
                'Bình luận',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_comments.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Comments list
          if (_comments.isEmpty)
            _buildEmptyComments()
          else
            ..._comments.map((comment) => _buildCommentItem(comment)),
        ],
      ),
    );
  }

  Widget _buildEmptyComments() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.comment_outlined, size: 20, color: AppColors.gray400),
          const SizedBox(width: 8),
          Text(
            'Chưa có đánh giá nào',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentForm() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact header
          Text(
            'Đánh giá của bạn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Compact rating section
          Row(
            children: [
              Text(
                'Sao:',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RatingBar.builder(
                  initialRating: _userRating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemSize: 28,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 2),
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star_rounded, color: Colors.amber),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _userRating = rating;
                    });
                  },
                ),
              ),
              if (_userRating > 0)
                Text(
                  _userRating.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Compact text field
          TextField(
            controller: _commentController,
            maxLines: 3,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Nhập đánh giá của bạn...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
              filled: true,
              fillColor: isDark ? AppColors.backgroundDark : AppColors.gray50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.gray300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.gray300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          // Compact submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitComment,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text(
                'Gửi đánh giá',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info header
            Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: comment.userPhotoUrl != null
                        ? NetworkImage(comment.userPhotoUrl!)
                        : null,
                    backgroundColor: Colors.transparent,
                    child: comment.userPhotoUrl == null
                        ? Text(
                            comment.userName.isNotEmpty
                                ? comment.userName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                // User name and rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: comment.rating,
                            itemBuilder: (context, index) => const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                            ),
                            itemCount: 5,
                            itemSize: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            comment.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Time
                Text(
                  _formatDate(comment.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Comment content
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDark
                    : AppColors.gray50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                comment.content,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                ),
              ),
            ),
            // Rating badge at bottom
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withOpacity(0.2),
                    Colors.orange.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Đánh giá ${comment.rating.toStringAsFixed(1)}/5.0',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Vừa xong';
        }
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
