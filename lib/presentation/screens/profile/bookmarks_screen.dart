import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/reading_provider.dart';
import '../../../providers/book_provider.dart';
import '../../../data/models/reading_history_model.dart';
import '../../../data/models/book_model.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final readingProvider = Provider.of<ReadingProvider>(
      context,
      listen: false,
    );

    if (authProvider.currentUser != null) {
      await readingProvider.fetchReadingHistory(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đánh dấu',
          style: TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer2<ReadingProvider, BookProvider>(
        builder: (context, readingProvider, bookProvider, child) {
          if (readingProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // Collect all bookmarks from reading history
          final allBookmarks = <MapEntry<BookModel, BookmarkModel>>[];

          for (final history in readingProvider.readingHistory) {
            final book = bookProvider.books.firstWhere(
              (b) => b.id == history.bookId,
              orElse: () => BookModel(
                id: history.bookId,
                title: 'Sách không tìm thấy',
                author: '',
                description: '',
                coverImageUrl: '',
                fileUrl: '',
                format: BookFormat.pdf,
                category: '',
                publishedDate: DateTime.now(),
                addedAt: DateTime.now(),
              ),
            );

            for (final bookmark in history.bookmarks) {
              allBookmarks.add(MapEntry(book, bookmark));
            }
          }

          // Sort by createdAt descending
          allBookmarks.sort(
            (a, b) => b.value.createdAt.compareTo(a.value.createdAt),
          );

          if (allBookmarks.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadBookmarks,
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allBookmarks.length,
              itemBuilder: (context, index) {
                final entry = allBookmarks[index];
                return _buildBookmarkItem(entry.key, entry.value);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_border,
              size: 64,
              color: AppColors.accent.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có đánh dấu',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đánh dấu trang sách khi đọc để lưu lại',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkItem(BookModel book, BookmarkModel bookmark) {
    final createdAt = _formatDate(bookmark.createdAt);

    return GestureDetector(
      onTap: () {
        if (book.title != 'Sách không tìm thấy') {
          Navigator.pushNamed(
            context,
            AppRoutes.bookDetail,
            arguments: book.id,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Bookmark icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bookmark, color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 16),

            // Bookmark info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (bookmark.chapterName.isNotEmpty)
                    Text(
                      bookmark.chapterName,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Trang ${bookmark.page}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        createdAt,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Delete button
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[400]),
              onPressed: () => _confirmDelete(book.id, bookmark),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String bookId, BookmarkModel bookmark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa đánh dấu'),
        content: Text('Bạn có chắc muốn xóa đánh dấu trang ${bookmark.page}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBookmark(bookId, bookmark.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBookmark(String bookId, String bookmarkId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final readingProvider = Provider.of<ReadingProvider>(
      context,
      listen: false,
    );

    if (authProvider.currentUser != null) {
      await readingProvider.removeBookmark(
        userId: authProvider.currentUser!.id,
        bookId: bookId,
        bookmarkId: bookmarkId,
      );

      // Refresh the list
      await _loadBookmarks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa đánh dấu'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
