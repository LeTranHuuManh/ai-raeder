import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/reading_history_model.dart';
import '../../../providers/reading_provider.dart';
import '../../../providers/auth_provider.dart';

class PdfReader extends StatefulWidget {
  final BookModel book;

  const PdfReader({super.key, required this.book});

  @override
  State<PdfReader> createState() => _PdfReaderState();
}

class _PdfReaderState extends State<PdfReader> {
  PdfDocument? _pdfDocument;
  bool _isLoading = true;
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;
  final ScrollController _scrollController = ScrollController();
  final Map<int, PdfPageImage?> _pageImages = {};
  final Set<int> _loadingPages = {};
  ReadingHistoryModel? _readingHistory;
  bool _isFabExpanded = false;

  @override
  void initState() {
    super.initState();
    _isFabExpanded = false; // Ensure initialized
    _loadPdf();
    _scrollController.addListener(_onScroll);
    _loadReadingProgress();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pdfDocument?.close();
    super.dispose();
  }

  Future<void> _loadReadingProgress() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final readingProvider =
        Provider.of<ReadingProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return;

    try {
      await readingProvider.loadReadingProgress(
        userId: user.id,
        bookId: widget.book.id,
      );
      setState(() {
        _readingHistory = readingProvider.currentReading;
      });

      // Jump to last reading position if exists
      if (_readingHistory != null && _readingHistory!.currentPage > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _jumpToPage(_readingHistory!.currentPage);
        });
      }
    } catch (e) {
      debugPrint('Error loading reading progress: $e');
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !mounted) return;

    // Close FAB menu when scrolling
    if (_isFabExpanded == true) {
      if (mounted) {
        setState(() {
          _isFabExpanded = false;
        });
      }
    }

    // Calculate current page from scroll position
    final scrollPosition = _scrollController.position.pixels;
    final viewportHeight = _scrollController.position.viewportDimension;
    final estimatedPageHeight = viewportHeight * 0.8;
    final calculatedPage = (scrollPosition / estimatedPageHeight).floor().clamp(
          0,
          _totalPages - 1,
        );

    if (calculatedPage != _currentPage) {
      setState(() {
        _currentPage = calculatedPage;
      });

      // Auto-save reading progress every 5 pages
      if (calculatedPage % 5 == 0) {
        _saveReadingProgress(calculatedPage);
      }
    }

    // Preload nearby pages when scrolling
    for (
      int i = calculatedPage;
      i < calculatedPage + 3 && i < _totalPages;
      i++
    ) {
      if (!_pageImages.containsKey(i) && !_loadingPages.contains(i)) {
        _loadPage(i);
      }
    }
  }

  Future<void> _saveReadingProgress(int page) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final readingProvider =
        Provider.of<ReadingProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return;

    try {
      await readingProvider.updateReadingProgress(
        userId: user.id,
        bookId: widget.book.id,
        currentPage: page + 1, // PDF pages are 1-indexed
        totalPages: _totalPages,
      );
    } catch (e) {
      debugPrint('Error saving reading progress: $e');
    }
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      debugPrint('Loading PDF from: ${widget.book.fileUrl}');

      // Download PDF data
      final pdfData = await _downloadPdf(widget.book.fileUrl);

      // Open PDF document
      _pdfDocument = await PdfDocument.openData(Uint8List.fromList(pdfData));
      final pageCount = _pdfDocument!.pagesCount;

      setState(() {
        _totalPages = pageCount;
        _isLoading = false;
      });

      debugPrint('PDF loaded successfully. Total pages: $pageCount');

      // Load first few pages
      for (int i = 0; i < 3 && i < pageCount; i++) {
        _loadPage(i);
      }
    } catch (e) {
      debugPrint('Error loading PDF: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải sách: ${e.toString()}';
      });
    }
  }

  Future<void> _loadPage(int pageIndex) async {
    if (_loadingPages.contains(pageIndex) || _pdfDocument == null) return;

    _loadingPages.add(pageIndex);

    try {
      final page = await _pdfDocument!.getPage(pageIndex + 1);
      final pageImage = await page.render(
        width: page.width * 2, // Higher resolution
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );
      await page.close();

      if (mounted) {
        setState(() {
          _pageImages[pageIndex] = pageImage;
          _loadingPages.remove(pageIndex);
        });
      }
    } catch (e) {
      debugPrint('Error loading page $pageIndex: $e');
      _loadingPages.remove(pageIndex);
    }
  }

  Future<List<int>> _downloadPdf(String url) async {
    try {
      debugPrint('Downloading PDF from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/pdf, */*'},
      );

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(
          'Không thể tải file PDF. Mã lỗi: ${response.statusCode}',
        );
      }

      debugPrint('PDF downloaded. Size: ${response.bodyBytes.length} bytes');
      return response.bodyBytes;
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      rethrow;
    }
  }

  Future<void> _addBookmark() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final readingProvider =
        Provider.of<ReadingProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để sử dụng tính năng này'),
        ),
      );
      return;
    }

    try {
      await readingProvider.addBookmark(
        userId: user.id,
        bookId: widget.book.id,
        page: _currentPage + 1, // PDF pages are 1-indexed
        chapterName: 'Trang ${_currentPage + 1}',
      );

      // Reload reading progress to get updated bookmarks
      await readingProvider.loadReadingProgress(
        userId: user.id,
        bookId: widget.book.id,
      );
      setState(() {
        _readingHistory = readingProvider.currentReading;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm bookmark tại trang ${_currentPage + 1}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi thêm bookmark: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _removeBookmark(String bookmarkId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final readingProvider =
        Provider.of<ReadingProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return;

    try {
      await readingProvider.removeBookmark(
        userId: user.id,
        bookId: widget.book.id,
        bookmarkId: bookmarkId,
      );

      // Reload reading progress
      await readingProvider.loadReadingProgress(
        userId: user.id,
        bookId: widget.book.id,
      );
      setState(() {
        _readingHistory = readingProvider.currentReading;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa bookmark'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa bookmark: ${e.toString()}'),
          ),
        );
      }
    }
  }

  void _jumpToPage(int page) {
    if (!_scrollController.hasClients) return;

    final viewportHeight = _scrollController.position.viewportDimension;
    final estimatedPageHeight = viewportHeight * 0.8;
    final targetPosition = (page - 1) * estimatedPageHeight;

    _scrollController.animateTo(
      targetPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _showBookmarksDialog() {
    final bookmarks = _readingHistory?.bookmarks ?? [];
    bookmarks.sort((a, b) => b.page.compareTo(a.page)); // Sort by page desc

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bookmark, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Đánh dấu trang',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Bookmarks List
            Expanded(
              child: bookmarks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có bookmark nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: bookmarks.length,
                      itemBuilder: (context, index) {
                        final bookmark = bookmarks[index];
                        final isCurrentPage = bookmark.page == _currentPage + 1;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isCurrentPage
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrentPage
                                  ? AppColors.primary
                                  : Colors.grey[200]!,
                              width: isCurrentPage ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.bookmark,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              bookmark.chapterName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Trang ${bookmark.page}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCurrentPage)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Trang hiện tại',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: AppColors.error,
                                  onPressed: () {
                                    _removeBookmark(bookmark.id);
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              _jumpToPage(bookmark.page);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isBookmarked(int page) {
    return _readingHistory?.bookmarks.any((b) => b.page == page) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.book.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải sách...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.book.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadPdf,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_pdfDocument == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.book.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: Text('Không thể tải PDF')),
      );
    }

    final isBookmarked = _isBookmarked(_currentPage + 1);

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.book.title,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            if (_totalPages > 0)
              Text(
                'Trang ${_currentPage + 1} / $_totalPages',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Save progress before leaving
            _saveReadingProgress(_currentPage);
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? AppColors.primary : null,
            ),
            onPressed: () {
              if (isBookmarked) {
                final bookmark = _readingHistory!.bookmarks
                    .firstWhere((b) => b.page == _currentPage + 1);
                _removeBookmark(bookmark.id);
              } else {
                _addBookmark();
              }
            },
            tooltip: isBookmarked ? 'Xóa bookmark' : 'Thêm bookmark',
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks),
            onPressed: _showBookmarksDialog,
            tooltip: 'Danh sách bookmark',
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              // TODO: Toggle brightness
            },
          ),
        ],
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _totalPages,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildPage(index),
          );
        },
      ),
      floatingActionButton: SafeArea(
        minimum: const EdgeInsets.only(bottom: 16),
        child: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    // Ensure boolean value is never null
    final isExpanded = _isFabExpanded == true;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Text to Speech Button
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FloatingActionButton(
              heroTag: 'text_to_speech',
              onPressed: () {
                if (!mounted) return;
                setState(() {
                  _isFabExpanded = false;
                });
                _showTextToSpeechDialog();
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.volume_up),
              tooltip: 'Text to Speech',
            ),
          ),
        // Scroll to Top Button
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FloatingActionButton(
              heroTag: 'scroll_to_top',
              onPressed: () {
                if (!mounted) return;
                setState(() {
                  _isFabExpanded = false;
                });
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              },
              backgroundColor: AppColors.secondary,
              child: const Icon(Icons.arrow_upward),
              tooltip: 'Về đầu trang',
            ),
          ),
        // Main FAB
        FloatingActionButton(
          heroTag: 'main_fab',
          onPressed: () {
            if (!mounted) return;
            setState(() {
              final currentValue = _isFabExpanded == true;
              _isFabExpanded = !currentValue;
            });
          },
          backgroundColor: AppColors.primary,
          child: AnimatedRotation(
            turns: isExpanded ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(isExpanded ? Icons.close : Icons.menu),
          ),
        ),
      ],
    );
  }

  void _showTextToSpeechDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.volume_up,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Text to Speech',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tính năng Text to Speech đang được phát triển.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tính năng này sẽ cho phép bạn nghe nội dung sách được đọc tự động.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int pageIndex) {
    final pageImage = _pageImages[pageIndex];

    if (pageImage != null) {
      return Image.memory(pageImage.bytes, fit: BoxFit.contain);
    }

    if (_loadingPages.contains(pageIndex)) {
      return const SizedBox(
        height: 800,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Page not loaded yet, trigger loading
    Future.microtask(() => _loadPage(pageIndex));

    return const SizedBox(
      height: 800,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
