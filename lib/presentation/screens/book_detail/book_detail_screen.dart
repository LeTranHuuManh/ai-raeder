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
      final snapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('bookId', isEqualTo: widget.bookId)
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      setState(() {
        _comments = snapshot.docs
            .map((doc) => CommentModel.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList();
      });
    } catch (e) {
      // Handle error silently
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
          const SnackBar(content: Text('Vui lòng đăng nhập để thêm vào yêu thích')),
        );
      }
      return;
    }

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.id);
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
            content: Text(_isFavorite 
                ? 'Đã thêm vào yêu thích' 
                : 'Đã xóa khỏi yêu thích'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
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

      await FirebaseFirestore.instance
          .collection('comments')
          .doc(comment.id)
          .set(comment.toMap());

      _commentController.clear();
      setState(() {
        _userRating = 0.0;
      });

      await _loadComments();
      await _loadBookDetails(); // Reload to update rating

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

  void _navigateToReader() {
    if (_book != null) {
      Navigator.of(context).pushNamed(
        AppRoutes.reader,
        arguments: _book,
      );
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
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _book!.author,
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              RatingBarIndicator(
                rating: _book!.rating,
                itemBuilder: (context, index) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đánh giá',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildCommentForm(),
          const SizedBox(height: 24),
          Text(
            'Bình luận (${_comments.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_comments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('Chưa có đánh giá nào'),
              ),
            )
          else
            ..._comments.map((comment) => _buildCommentItem(comment)),
        ],
      ),
    );
  }

  Widget _buildCommentForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Đánh giá của bạn'),
          const SizedBox(height: 8),
          RatingBar.builder(
            initialRating: _userRating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 5,
            itemSize: 30,
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (rating) {
              setState(() {
                _userRating = rating;
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Nhập đánh giá của bạn...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitComment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Gửi đánh giá'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: comment.userPhotoUrl != null
                    ? NetworkImage(comment.userPhotoUrl!)
                    : null,
                child: comment.userPhotoUrl == null
                    ? Text(comment.userName[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    RatingBarIndicator(
                      rating: comment.rating,
                      itemBuilder: (context, index) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 14,
                      ),
                      itemCount: 5,
                      itemSize: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment.content),
        ],
      ),
    );
  }
}

