import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/book_model.dart';
import '../../../data/services/cloudinary_service.dart';
import '../../../providers/book_provider.dart';
import '../../widgets/loading_widget.dart';

class BookManagementScreen extends StatefulWidget {
  const BookManagementScreen({super.key});

  @override
  State<BookManagementScreen> createState() => _BookManagementScreenState();
}

class _BookManagementScreenState extends State<BookManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<BookModel> _books = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      await bookProvider.fetchBooks();

      setState(() {
        _books = bookProvider.books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteBook(BookModel book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Xác nhận xóa',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
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
              'Bạn có chắc muốn xóa sách:',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: book.coverImageUrl,
                      width: 40,
                      height: 56,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 40,
                        height: 56,
                        color: Colors.grey[300],
                        child: const Icon(Icons.book, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF2D3142),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.author,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hành động này không thể hoàn tác!',
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: BorderSide(color: Colors.grey[300]!, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Hủy',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_rounded, size: 18),
                SizedBox(width: 8),
                Text(
                  'Xóa',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('books').doc(book.id).delete();
        await _loadBooks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Đã xóa sách thành công',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lỗi xóa sách: ${e.toString()}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  void _showAddBookDialog({BookModel? book}) {
    showDialog(
      context: context,
      builder: (context) => _BookEditDialog(book: book, onSaved: _loadBooks),
    );
  }

  List<BookModel> get _filteredBooks {
    if (_searchQuery.isEmpty) return _books;
    return _books.where((book) {
      return book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.author.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6C63FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quản lý sách',
          style: TextStyle(
            color: Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6C63FF)),
              onPressed: _loadBooks,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Modern search bar
          Container(
            margin: const EdgeInsets.all(16),
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
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sách...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF6C63FF),
                  size: 24,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Results count
          if (!_isLoading && _filteredBooks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Tìm thấy ${_filteredBooks.length} cuốn sách',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _filteredBooks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy sách nào',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = _filteredBooks[index];
                      return _buildBookItem(book);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddBookDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, size: 32),
        ),
      ),
    );
  }

  Widget _buildBookItem(BookModel book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showAddBookDialog(book: book),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book cover with shadow
                Hero(
                  tag: 'book_${book.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: book.coverImageUrl,
                        width: 70,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 70,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[200]!, Colors.grey[300]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.book,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 70,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[300]!, Colors.grey[400]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Book info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Author
                      Text(
                        book.author,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Stats row
                      Row(
                        children: [
                          // Rating
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  book.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Views
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.visibility_rounded,
                                  size: 16,
                                  color: Color(0xFF6C63FF),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${book.viewCount}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6C63FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: Color(0xFF6C63FF),
                          size: 20,
                        ),
                        onPressed: () => _showAddBookDialog(book: book),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _deleteBook(book),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookEditDialog extends StatefulWidget {
  final BookModel? book;
  final VoidCallback onSaved;

  const _BookEditDialog({this.book, required this.onSaved});

  @override
  State<_BookEditDialog> createState() => _BookEditDialogState();
}

class _BookEditDialogState extends State<_BookEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _pageCountController = TextEditingController();
  final _priceController = TextEditingController();

  BookFormat _selectedFormat = BookFormat.pdf;
  bool _isFree = true;
  String? _coverImageUrl;
  String? _fileUrl;
  bool _isUploading = false;

  // Store selected files instead of uploading immediately
  PlatformFile? _selectedCoverImage;
  PlatformFile? _selectedBookFile;

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      final book = widget.book!;
      _titleController.text = book.title;
      _authorController.text = book.author;
      _descriptionController.text = book.description;
      _categoryController.text = book.category;
      _pageCountController.text = book.pageCount.toString();
      _priceController.text = book.price?.toString() ?? '';
      _selectedFormat = book.format;
      _isFree = book.isFree;
      _coverImageUrl = book.coverImageUrl;
      _fileUrl = book.fileUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _pageCountController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: kIsWeb, // Important for web: load file bytes
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedCoverImage = result.files.single;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã chọn ảnh: ${result.files.single.name}')),
        );
      }
    }
  }

  Future<void> _pickBookFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: kIsWeb, // Important for web: load file bytes
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedBookFile = result.files.single;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã chọn file: ${result.files.single.name}')),
        );
      }
    }
  }

  Future<String> _uploadImage(PlatformFile platformFile) async {
    try {
      // Validate file existence
      if (kIsWeb) {
        if (platformFile.bytes == null) {
          throw Exception('Không thể đọc dữ liệu file');
        }
      } else {
        if (platformFile.path == null) {
          throw Exception('Không tìm thấy đường dẫn file');
        }
        final file = File(platformFile.path!);
        if (!await file.exists()) {
          throw Exception('File không tồn tại');
        }
      }

      debugPrint('Uploading image to Cloudinary...');

      final cloudinaryService = CloudinaryService();
      final url = await cloudinaryService.uploadImage(
        file: kIsWeb ? null : File(platformFile.path!),
        bytes: kIsWeb ? platformFile.bytes : null,
        fileName: platformFile.name,
        folder: 'book_covers',
      );

      if (url == null) {
        throw Exception('Không nhận được URL từ Cloudinary');
      }

      return url;
    } catch (e) {
      throw Exception('Lỗi upload ảnh: ${e.toString()}');
    }
  }

  Future<String> _uploadFile(PlatformFile platformFile) async {
    try {
      // Validate file existence
      if (kIsWeb) {
        if (platformFile.bytes == null) {
          throw Exception('Không thể đọc dữ liệu file');
        }
      } else {
        if (platformFile.path == null) {
          throw Exception('Không tìm thấy đường dẫn file');
        }
        final file = File(platformFile.path!);
        if (!await file.exists()) {
          throw Exception('File không tồn tại');
        }
      }

      debugPrint('Uploading file to Cloudinary...');

      final cloudinaryService = CloudinaryService();
      final url = await cloudinaryService.uploadImage(
        file: kIsWeb ? null : File(platformFile.path!),
        bytes: kIsWeb ? platformFile.bytes : null,
        fileName: platformFile.name,
        folder: 'books',
        resourceType:
            'auto', // Use 'auto' to let Cloudinary detect and allow public access
      );

      if (url == null) {
        throw Exception('Không nhận được URL từ Cloudinary');
      }

      return url;
    } catch (e) {
      throw Exception('Lỗi upload file: ${e.toString()}');
    }
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if files are selected (for new book) or URLs exist (for existing book)
    final isEditingExistingBook = widget.book != null;
    final hasExistingCoverImage =
        _coverImageUrl != null && _coverImageUrl!.isNotEmpty;
    final hasExistingBookFile = _fileUrl != null && _fileUrl!.isNotEmpty;

    if (!isEditingExistingBook ||
        (!hasExistingCoverImage || !hasExistingBookFile)) {
      if (_selectedCoverImage == null || _selectedBookFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ảnh bìa và file sách')),
        );
        return;
      }
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload files to Cloudinary if new files are selected
      String finalCoverImageUrl = _coverImageUrl ?? '';
      String finalFileUrl = _fileUrl ?? '';

      if (_selectedCoverImage != null) {
        debugPrint('Uploading cover image...');
        finalCoverImageUrl = await _uploadImage(_selectedCoverImage!);
        debugPrint('Cover image uploaded: $finalCoverImageUrl');
      }

      if (_selectedBookFile != null) {
        debugPrint('Uploading book file...');
        finalFileUrl = await _uploadFile(_selectedBookFile!);
        debugPrint('Book file uploaded: $finalFileUrl');
      }

      final bookData = {
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim(),
        'coverImageUrl': finalCoverImageUrl,
        'fileUrl': finalFileUrl,
        'format': _selectedFormat.name,
        'pageCount': int.tryParse(_pageCountController.text) ?? 0,
        'isFree': _isFree,
        'price': _isFree ? null : double.tryParse(_priceController.text),
        'rating': 0.0,
        'reviewCount': 0,
        'viewCount': 0,
        'downloadCount': 0,
        'language': 'vi',
        'publishedDate': DateTime.now(),
        'addedAt': DateTime.now(),
        'tags': <String>[],
      };

      if (widget.book != null) {
        await FirebaseFirestore.instance
            .collection('books')
            .doc(widget.book!.id)
            .update(bookData);
      } else {
        await FirebaseFirestore.instance.collection('books').add(bookData);
      }

      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.book != null
                  ? 'Đã cập nhật sách'
                  : 'Đã thêm sách thành công',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6C63FF),
                    const Color(0xFF6C63FF).withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.book != null
                          ? Icons.edit
                          : Icons.add_circle_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.book != null ? 'Chỉnh sửa sách' : 'Thêm sách mới',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info Section
                      _buildSectionLabel(
                        'Thông tin cơ bản',
                        Icons.info_outline,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _titleController,
                        label: 'Tiêu đề',
                        icon: Icons.title,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Vui lòng nhập tiêu đề'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _authorController,
                        label: 'Tác giả',
                        icon: Icons.person_outline,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Vui lòng nhập tác giả'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Mô tả',
                        icon: Icons.description_outlined,
                        maxLines: 4,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Vui lòng nhập mô tả'
                            : null,
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Divider(color: Colors.grey[300], height: 1),
                      const SizedBox(height: 24),

                      // Category & Format Section
                      _buildSectionLabel('Phân loại', Icons.category_outlined),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _categoryController,
                              label: 'Thể loại',
                              icon: Icons.local_offer_outlined,
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Vui lòng nhập thể loại'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Divider(color: Colors.grey[300], height: 1),
                      const SizedBox(height: 24),

                      // Details Section
                      _buildSectionLabel('Chi tiết', Icons.settings_outlined),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _pageCountController,
                              label: 'Số trang',
                              icon: Icons.auto_stories_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),

                      if (!_isFree) ...[
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _priceController,
                          label: 'Giá (VNĐ)',
                          icon: Icons.payments_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Divider
                      Divider(color: Colors.grey[300], height: 1),
                      const SizedBox(height: 24),

                      // Files Section
                      _buildSectionLabel(
                        'Tệp đính kèm',
                        Icons.cloud_upload_outlined,
                      ),
                      const SizedBox(height: 16),

                      _buildFilePickerButton(
                        label: 'Chọn ảnh bìa',
                        icon: Icons.image_outlined,
                        selectedFile: _selectedCoverImage,
                        existingUrl: _coverImageUrl,
                        onTap: _isUploading ? null : _pickCoverImage,
                        color: const Color(0xFF6C63FF),
                      ),

                      const SizedBox(height: 12),

                      _buildFilePickerButton(
                        label: 'Chọn file sách',
                        icon: Icons.picture_as_pdf_outlined,
                        selectedFile: _selectedBookFile,
                        existingUrl: _fileUrl,
                        onTap: _isUploading ? null : _pickBookFile,
                        color: const Color(0xFFE91E63),
                      ),

                      if (_isUploading) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6C63FF).withOpacity(0.1),
                                const Color(0xFF6C63FF).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Đang tải lên...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6C63FF),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Vui lòng đợi trong giây lát',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Footer with action buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isUploading
                        ? null
                        : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Hủy',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isUploading ? null : _saveBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shadowColor: const Color(0xFF6C63FF).withOpacity(0.3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.save_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.book != null ? 'Cập nhật' : 'Lưu',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
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

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C63FF),
                const Color(0xFF6C63FF).withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF6C63FF),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2D3142),
        ),
      ),
    );
  }

  Widget _buildFilePickerButton({
    required String label,
    required IconData icon,
    required PlatformFile? selectedFile,
    required String? existingUrl,
    required VoidCallback? onTap,
    required Color color,
  }) {
    final hasFile = selectedFile != null || existingUrl != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasFile ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? color : Colors.grey[300]!,
            width: hasFile ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: hasFile
                  ? color.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: hasFile
                    ? LinearGradient(colors: [color, color.withOpacity(0.7)])
                    : LinearGradient(
                        colors: [Colors.grey[200]!, Colors.grey[100]!],
                      ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: hasFile
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                hasFile ? Icons.check_circle : icon,
                color: hasFile ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: hasFile ? color : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedFile != null
                        ? selectedFile.name
                        : (existingUrl != null
                              ? 'Đã có file'
                              : 'Chưa chọn file'),
                    style: TextStyle(
                      fontSize: 13,
                      color: hasFile
                          ? color.withOpacity(0.8)
                          : Colors.grey[500],
                      fontWeight: hasFile ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: hasFile ? color : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
