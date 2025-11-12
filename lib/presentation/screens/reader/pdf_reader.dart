import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/book_model.dart';

class PdfReader extends StatefulWidget {
  final BookModel book;

  const PdfReader({super.key, required this.book});

  @override
  State<PdfReader> createState() => _PdfReaderState();
}

class _PdfReaderState extends State<PdfReader> {
  String? _localPath;
  bool _isLoading = true;
  String? _errorMessage;
  PDFViewController? _pdfViewController;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Download PDF file
      final response = await http.get(Uri.parse(widget.book.fileUrl));
      if (response.statusCode != 200) {
        throw Exception('Không thể tải file PDF');
      }

      // Save to local storage
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${widget.book.id}.pdf');
      await file.writeAsBytes(response.bodyBytes);

      setState(() {
        _localPath = file.path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải sách: ${e.toString()}';
      });
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
          child: CircularProgressIndicator(),
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPdf,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_localPath == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.book.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text('Không tìm thấy file'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              // TODO: Add bookmark
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Show settings
            },
          ),
        ],
      ),
      body: PDFView(
        filePath: _localPath!,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        defaultPage: _currentPage,
        fitPolicy: FitPolicy.BOTH,
        preventLinkNavigation: false,
        onRender: (pages) {
          setState(() {
            _totalPages = pages ?? 0;
          });
        },
        onError: (error) {
          setState(() {
            _errorMessage = error.toString();
          });
        },
        onPageError: (page, error) {
          // Handle page error
        },
        onViewCreated: (PDFViewController pdfViewController) {
          _pdfViewController = pdfViewController;
        },
        onLinkHandler: (String? uri) {
          // Handle link navigation
        },
        onPageChanged: (int? page, int? total) {
          setState(() {
            _currentPage = page ?? 0;
            _totalPages = total ?? 0;
          });
        },
      ),
      bottomNavigationBar: _totalPages > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: _currentPage > 0
                        ? () {
                            _pdfViewController?.setPage(_currentPage - 1);
                          }
                        : null,
                  ),
                  Expanded(
                    child: Slider(
                      value: _currentPage.toDouble(),
                      min: 0,
                      max: (_totalPages - 1).toDouble(),
                      divisions: _totalPages - 1,
                      label: 'Trang $_currentPage',
                      onChanged: (value) {
                        _pdfViewController?.setPage(value.toInt());
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: _currentPage < _totalPages - 1
                        ? () {
                            _pdfViewController?.setPage(_currentPage + 1);
                          }
                        : null,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

