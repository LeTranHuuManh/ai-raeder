import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/category_model.dart';
import '../../widgets/book_card.dart';
import '../../widgets/loading_widget.dart';

class ListCategoryBooksScreen extends StatefulWidget {
  final CategoryModel category;

  const ListCategoryBooksScreen({
    super.key,
    required this.category,
  });

  @override
  State<ListCategoryBooksScreen> createState() =>
      _ListCategoryBooksScreenState();
}

class _ListCategoryBooksScreenState extends State<ListCategoryBooksScreen> {
  List<BookModel> _books = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBooks();
    });
  }

  Future<void> _loadBooks() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('books')
          .where('category', isEqualTo: widget.category.name)
          .get();

      final books = snapshot.docs
          .map((doc) => BookModel.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      // Sort by viewCount descending (most popular first)
      books.sort((a, b) => b.viewCount.compareTo(a.viewCount));

      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải danh sách sách: ${e.toString()}';
      });
    }
  }

  Color _getColorFromHex(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'psychology':
        return Icons.psychology;
      case 'business':
        return Icons.business;
      case 'science':
        return Icons.science;
      case 'computer':
        return Icons.computer;
      case 'music_note':
        return Icons.music_note;
      case 'palette':
        return Icons.palette;
      case 'school':
        return Icons.school;
      case 'auto_stories':
        return Icons.auto_stories;
      case 'menu_book':
        return Icons.menu_book;
      case 'local_library':
        return Icons.local_library;
      default:
        return Icons.book;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getColorFromHex(widget.category.color);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    categoryColor,
                    categoryColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIconFromName(widget.category.iconName),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.category.name,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadBooks,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Header Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  categoryColor.withOpacity(0.1),
                  categoryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            categoryColor,
                            categoryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconFromName(widget.category.iconName),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: categoryColor,
                            ),
                          ),
                          if (widget.category.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.category.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatItem(
                      icon: Icons.book_outlined,
                      label: 'Sách',
                      value: '${_books.length}',
                      color: categoryColor,
                    ),
                    const SizedBox(width: 24),
                    _buildStatItem(
                      icon: Icons.visibility_outlined,
                      label: 'Lượt xem',
                      value: _books.fold<int>(
                            0,
                            (sum, book) => sum + book.viewCount,
                          ).toString(),
                      color: categoryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Books List
          Expanded(
            child: _buildBooksContent(categoryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBooksContent(Color categoryColor) {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadBooks,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_books.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadBooks,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 300,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.book_outlined,
                        size: 80,
                        color: categoryColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Chưa có sách nào',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Thể loại ${widget.category.name} chưa có sách nào.\nHãy quay lại sau để xem thêm sách mới.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBooks,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.6,
            crossAxisSpacing: 16,
            mainAxisSpacing: 20,
          ),
          itemCount: _books.length,
          itemBuilder: (context, index) {
            final book = _books[index];
            return BookCard(book: book);
          },
        ),
      ),
    );
  }
}

