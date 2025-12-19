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
import '../../../providers/tts_provider.dart';
import '../../../data/services/pdf_text_extractor_service.dart';
import '../../../data/services/gemini_service.dart';

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
  late PageController _pageController;
  final Map<int, PdfPageImage?> _pageImages = {};
  final Map<int, String> _pageTexts = {}; // Cache extracted text
  final Set<int> _loadingPages = {};
  ReadingHistoryModel? _readingHistory;
  bool _isFabExpanded = false;
  Uint8List? _pdfBytes; // Store PDF bytes for text extraction
  final PdfTextExtractorService _textExtractor = PdfTextExtractorService();
  final GeminiService _geminiService = GeminiService();
  bool _isSummarizing = false;

  @override
  void initState() {
    super.initState();
    _isFabExpanded = false; // Ensure initialized
    _pageController = PageController(initialPage: 0);
    _pageController.addListener(_onPageChanged);
    _loadPdf();
    _loadReadingProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pdfDocument?.close();
    super.dispose();
  }

  Future<void> _loadReadingProgress() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final readingProvider = Provider.of<ReadingProvider>(
      context,
      listen: false,
    );
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
        // PDF pages are 1-indexed, convert to 0-indexed
        final savedPage = (_readingHistory!.currentPage - 1).clamp(
          0,
          _totalPages - 1,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients && savedPage < _totalPages) {
            _pageController.jumpToPage(savedPage);
            setState(() {
              _currentPage = savedPage;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading reading progress: $e');
    }
  }

  void _onPageChanged() {
    if (!_pageController.hasClients || !mounted) return;

    // Close FAB menu when page changes
    if (_isFabExpanded == true) {
      if (mounted) {
        setState(() {
          _isFabExpanded = false;
        });
      }
    }

    // Get current page from PageController
    final page = _pageController.page?.round() ?? _pageController.initialPage;
    final newPage = page.clamp(0, _totalPages - 1);

    if (newPage != _currentPage) {
      setState(() {
        _currentPage = newPage;
      });

      // Auto-save reading progress every 5 pages
      if (newPage % 5 == 0) {
        _saveReadingProgress(newPage);
      }

      // Preload nearby pages
      for (int i = newPage - 1; i <= newPage + 1; i++) {
        if (i >= 0 && i < _totalPages) {
          if (!_pageImages.containsKey(i) && !_loadingPages.contains(i)) {
            _loadPage(i);
          }
        }
      }
    }
  }

  Future<void> _saveReadingProgress(int page) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final readingProvider = Provider.of<ReadingProvider>(
      context,
      listen: false,
    );
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
      // Store original bytes for text extraction (keep original safe)
      _pdfBytes = Uint8List.fromList(pdfData);

      // Create a copy for PdfDocument to prevent ArrayBuffer detachment
      // PdfDocument.openData() may transfer/detach the ArrayBuffer on web
      final pdfBytesForDocument = Uint8List.fromList(_pdfBytes!);

      // Open PDF document using the copy
      _pdfDocument = await PdfDocument.openData(pdfBytesForDocument);
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

      // Không extract toàn bộ PDF nữa, chỉ extract trang hiện tại khi cần
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

      // Note: pdfx doesn't support direct text extraction
      // Text extraction would require OCR or a different PDF library
      // For now, we'll rely on manual text input or cached text

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
    final readingProvider = Provider.of<ReadingProvider>(
      context,
      listen: false,
    );
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
          SnackBar(content: Text('Lỗi thêm bookmark: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _removeBookmark(String bookmarkId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final readingProvider = Provider.of<ReadingProvider>(
      context,
      listen: false,
    );
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
          SnackBar(content: Text('Lỗi xóa bookmark: ${e.toString()}')),
        );
      }
    }
  }

  void _jumpToPage(int page) {
    if (!_pageController.hasClients) return;
    // PDF pages are 1-indexed, convert to 0-indexed
    final targetPage = (page - 1).clamp(0, _totalPages - 1);
    _pageController.animateToPage(
      targetPage,
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
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
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
                final bookmark = _readingHistory!.bookmarks.firstWhere(
                  (b) => b.page == _currentPage + 1,
                );
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
      body: PageView.builder(
        controller: _pageController,
        itemCount: _totalPages,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
          _onPageChanged();
        },
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.all(8),
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
        // Summarize Book Button
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FloatingActionButton(
              heroTag: 'summarize_book',
              onPressed: () {
                if (!mounted) return;
                setState(() {
                  _isFabExpanded = false;
                });
                _showSummarizeOptions();
              },
              backgroundColor: Colors.orange,
              child: _isSummarizing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              tooltip: 'Tóm tắt sách',
            ),
          ),
        // Text to Speech Button
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Consumer<TtsProvider>(
              builder: (context, ttsProvider, _) {
                final isPlaying = ttsProvider.isPlaying;
                final isSynthesizing = ttsProvider.isSynthesizing;

                return FloatingActionButton(
                  heroTag: 'text_to_speech',
                  onPressed: () {
                    if (!mounted) return;
                    setState(() {
                      _isFabExpanded = false;
                    });
                    _handleTextToSpeech(ttsProvider);
                  },
                  backgroundColor: isPlaying
                      ? AppColors.error
                      : AppColors.primary,
                  child: isSynthesizing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(isPlaying ? Icons.stop : Icons.volume_up),
                  tooltip: isPlaying ? 'Dừng đọc' : 'Đọc sách',
                );
              },
            ),
          ),
        // Jump to First Page Button
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FloatingActionButton(
              heroTag: 'jump_to_first',
              onPressed: () {
                if (!mounted) return;
                setState(() {
                  _isFabExpanded = false;
                });
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              },
              backgroundColor: AppColors.secondary,
              child: const Icon(Icons.first_page),
              tooltip: 'Về trang đầu',
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

  /// Extract text from current page if not already extracted
  /// Chỉ extract trang hiện tại khi cần, không extract toàn bộ PDF
  Future<String?> _extractCurrentPageText() async {
    // Check if already extracted and cached
    if (_pageTexts.containsKey(_currentPage)) {
      final text = _pageTexts[_currentPage];
      if (text != null && text.trim().isNotEmpty) {
        debugPrint('✅ Sử dụng text đã cache cho trang ${_currentPage + 1}');
        return text;
      }
    }

    // Extract from current page only (không extract toàn bộ PDF)
    if (_pdfBytes != null) {
      try {
        debugPrint('🔄 Đang extract text từ trang ${_currentPage + 1}...');
        final text = await _textExtractor.extractTextFromPage(
          _pdfBytes!,
          _currentPage,
        );

        if (text != null && text.trim().isNotEmpty) {
          // Cache text để không phải extract lại lần sau
          setState(() {
            _pageTexts[_currentPage] = text;
          });
          debugPrint(
            '✅ Đã extract ${text.length} ký tự từ trang ${_currentPage + 1}',
          );
          return text;
        } else {
          debugPrint('⚠️ Không tìm thấy text ở trang ${_currentPage + 1}');
        }
      } catch (e) {
        debugPrint('❌ Lỗi extract text từ trang ${_currentPage + 1}: $e');
      }
    } else {
      debugPrint('⚠️ PDF bytes chưa được load');
    }

    return null;
  }

  Future<void> _handleTextToSpeech(TtsProvider ttsProvider) async {
    // If already playing, stop it
    if (ttsProvider.isPlaying || ttsProvider.isPaused) {
      await ttsProvider.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã dừng đọc sách'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    // Chỉ đọc trang hiện tại
    debugPrint('Đang đọc trang ${_currentPage + 1}');

    // Try to get text from current page
    String? pageText = _pageTexts[_currentPage];

    // If not found, try to extract it
    if (pageText == null || pageText.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đang trích xuất văn bản từ trang ${_currentPage + 1}...',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      pageText = await _extractCurrentPageText();
    }

    if (pageText == null || pageText.trim().isEmpty) {
      // Still no text, show dialog to enter manually
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không tìm thấy văn bản ở trang ${_currentPage + 1}. Vui lòng nhập thủ công.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        _showTextInputDialog(ttsProvider);
      }
      return;
    }

    // Speak the extracted text (chỉ vài chục ký tự đầu để demo)
    await _speakText(ttsProvider, pageText);
  }

  Future<void> _speakText(TtsProvider ttsProvider, String text) async {
    try {
      // Clean and prepare text
      final cleanText = text.trim();

      if (cleanText.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không có nội dung để đọc')),
          );
        }
        return;
      }

      // Chỉ đọc vài chục ký tự đầu để demo (250 ký tự)
      const maxDemoChars = 1000;
      final textToSpeak = cleanText.length > maxDemoChars
          ? '${cleanText.substring(0, maxDemoChars)}...'
          : cleanText;

      await ttsProvider.speak(textToSpeak);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đang đọc trang ${_currentPage + 1} (${textToSpeak.length} ký tự)...',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error speaking text: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ========== SUMMARIZE BOOK FUNCTIONS ==========

  void _showSummarizeOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tóm tắt sách',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Sử dụng AI để tóm tắt nội dung',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Option 1: Summarize current page
            _buildSummarizeOption(
              icon: Icons.article,
              title: 'Tóm tắt trang hiện tại',
              subtitle: 'Tóm tắt nội dung trang ${_currentPage + 1}',
              onTap: () {
                Navigator.pop(context);
                _summarizeCurrentPage();
              },
            ),
            const SizedBox(height: 12),
            // Option 2: Summarize entire book
            _buildSummarizeOption(
              icon: Icons.menu_book,
              title: 'Tóm tắt toàn bộ sách',
              subtitle: 'Tóm tắt dựa trên thông tin sách',
              onTap: () {
                Navigator.pop(context);
                _summarizeEntireBook();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarizeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _summarizeCurrentPage() async {
    setState(() {
      _isSummarizing = true;
    });

    try {
      // Extract text from current page
      String? pageText = _pageTexts[_currentPage];

      if (pageText == null || pageText.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đang trích xuất văn bản từ trang ${_currentPage + 1}...',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        pageText = await _extractCurrentPageText();
      }

      if (pageText == null || pageText.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể trích xuất văn bản từ trang này'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Call Gemini API to summarize
      final summary = await _geminiService.summarizePage(
        bookTitle: widget.book.title,
        pageContent: pageText,
        pageNumber: _currentPage + 1,
      );

      if (mounted) {
        _showSummaryDialog(
          title: 'Tóm tắt trang ${_currentPage + 1}',
          summary: summary,
        );
      }
    } catch (e) {
      debugPrint('Error summarizing page: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSummarizing = false;
        });
      }
    }
  }

  Future<void> _summarizeEntireBook() async {
    setState(() {
      _isSummarizing = true;
    });

    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Đang tạo tóm tắt sách...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sử dụng AI để phân tích nội dung',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      }

      // Call Gemini API to summarize based on book info
      final summary = await _geminiService.summarizeBookByInfo(
        bookTitle: widget.book.title,
        bookAuthor: widget.book.author,
        bookDescription: widget.book.description,
        bookCategory: widget.book.category,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        _showSummaryDialog(
          title: 'Tóm tắt sách',
          summary: summary,
          bookTitle: widget.book.title,
          bookAuthor: widget.book.author,
        );
      }
    } catch (e) {
      debugPrint('Error summarizing book: $e');
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSummarizing = false;
        });
      }
    }
  }

  void _showSummaryDialog({
    required String title,
    required String summary,
    String? bookTitle,
    String? bookAuthor,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
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
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (bookTitle != null)
                                Text(
                                  '$bookTitle${bookAuthor != null ? ' - $bookAuthor' : ''}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: SelectableText(
                          summary,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Copy button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: summary));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép tóm tắt'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Sao chép tóm tắt'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // AI notice
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tóm tắt được tạo bởi AI (Gemini). Nội dung có thể chưa hoàn toàn chính xác.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
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
            ],
          ),
        ),
      ),
    );
  }

  // ========== END SUMMARIZE BOOK FUNCTIONS ==========

  void _showTextInputDialog(TtsProvider ttsProvider) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                'Đọc sách',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Không thể tự động trích xuất văn bản từ trang này. Vui lòng nhập hoặc dán nội dung bạn muốn đọc:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(context);
                await _speakText(ttsProvider, text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đọc'),
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
