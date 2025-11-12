import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/book_model.dart';

class EpubReader extends StatefulWidget {
  final BookModel book;

  const EpubReader({super.key, required this.book});

  @override
  State<EpubReader> createState() => _EpubReaderState();
}

class _EpubReaderState extends State<EpubReader> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEpub();
  }

  Future<void> _loadEpub() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Download and open EPUB file
      // Note: vocsy_epub_viewer requires a local file path
      // You may need to download the file first using http package
      
      // For now, we'll show a placeholder
      // In production, you should:
      // 1. Download the file from widget.book.fileUrl
      // 2. Save it to local storage
      // 3. Pass the local path to EpubViewer.setConfig

      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _isLoading = false;
      });

      // Open EPUB viewer
      // Note: vocsy_epub_viewer API may vary by version
      // This implementation may need adjustment based on the actual package version
      // For now, we'll show a message that the viewer will open
      
      // TODO: Implement proper EPUB viewer integration
      // The package may require:
      // 1. Downloading the file to local storage first
      // 2. Using a different API structure
      // 3. Platform-specific configuration
      
      // Placeholder: Show that EPUB will open
      // In production, implement based on vocsy_epub_viewer documentation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang mở sách EPUB...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
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
                onPressed: _loadEpub,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    // EPUB viewer will open in a new screen
    // This widget serves as a container
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text('Đang mở sách...'),
      ),
    );
  }
}

