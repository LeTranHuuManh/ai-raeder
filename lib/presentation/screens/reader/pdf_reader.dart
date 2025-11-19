import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/book_model.dart';

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
  final ScrollController _scrollController = ScrollController();
  final Map<int, PdfPageImage?> _pageImages = {};
  final Set<int> _loadingPages = {};

  @override
  void initState() {
    super.initState();
    _loadPdf();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pdfDocument?.close();
    super.dispose();
  }

  void _onScroll() {
    // Preload nearby pages when scrolling
    final scrollPosition = _scrollController.position.pixels;
    final viewportHeight = _scrollController.position.viewportDimension;
    final estimatedPageHeight = viewportHeight * 0.8;
    final currentPageIndex = (scrollPosition / estimatedPageHeight).floor();

    // Preload current page and next 2 pages
    for (
      int i = currentPageIndex;
      i < currentPageIndex + 3 && i < _totalPages;
      i++
    ) {
      if (!_pageImages.containsKey(i) && !_loadingPages.contains(i)) {
        _loadPage(i);
      }
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

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
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
                'Tổng số trang: $_totalPages',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tính năng bookmark đang phát triển'),
                ),
              );
            },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        child: const Icon(Icons.arrow_upward),
        tooltip: 'Về đầu trang',
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
