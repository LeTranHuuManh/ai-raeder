import 'package:flutter/material.dart';
import '../../../data/models/book_model.dart';
import 'epub_reader.dart';
import 'pdf_reader.dart';

class ReaderScreen extends StatelessWidget {
  final BookModel book;

  const ReaderScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    switch (book.format) {
      case BookFormat.epub:
        return EpubReader(book: book);
      case BookFormat.pdf:
        return PdfReader(book: book);
      case BookFormat.txt:
        return _buildTextReader(context);
    }
  }

  Widget _buildTextReader(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Show settings
            },
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _loadTextContent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              snapshot.data ?? '',
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          );
        },
      ),
    );
  }

  Future<String> _loadTextContent() async {
    // TODO: Implement text file loading
    return 'Nội dung sách sẽ được tải từ: ${book.fileUrl}';
  }
}

