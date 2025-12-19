import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/services/cloudinary_service.dart';
import '../../../data/services/category_service.dart';
import '../../../providers/book_provider.dart';
import '../../../providers/category_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBooks();
    });
  }

  Future<void> _loadBooks() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      await bookProvider.fetchBooks();

      if (!mounted) return;

      setState(() {
        _books = bookProvider.books;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: AppColors.accent,
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
                  color: AppColors.textPrimary,
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
                            color: AppColors.textPrimary,
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
                color: AppColors.accent.withOpacity(0.7),
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
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primary,
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
        final categoryName = book.category;
        await _firestore.collection('books').doc(book.id).delete();

        // Update book count for category
        final categoryService = CategoryService();
        try {
          await categoryService.updateBookCountByName(categoryName);
        } catch (e) {
          debugPrint('Lỗi cập nhật số lượng sách: $e');
        }

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
              backgroundColor: AppColors.primary,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quản lý sách',
          style: TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
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
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.accent,
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
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddBookDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add_rounded,
            size: 32,
            color: AppColors.primary,
          ),
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
                          color: AppColors.textPrimary,
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
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      book.rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accent,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Views
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.visibility_rounded,
                                    size: 16,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${book.viewCount}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accent,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
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
                        color: AppColors.primary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.edit_rounded,
                          color: AppColors.accent,
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
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_rounded,
                          color: AppColors.accent,
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

  // Category selection (multiselect)
  List<CategoryModel> _categories = [];
  List<CategoryModel> _selectedCategories = [];
  bool _isLoadingCategories = false;

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
    // Load categories after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;

    // Set loading state safely
    Future.microtask(() {
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = true;
      });
    });

    try {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      await categoryProvider.fetchCategories();

      if (!mounted) return;

      // Update categories safely after async operation
      Future.microtask(() {
        if (!mounted) return;
        setState(() {
          _categories = categoryProvider.categories;
          _isLoadingCategories = false;
        });

        // If editing a book, try to find the matching categories
        if (widget.book != null &&
            _categoryController.text.isNotEmpty &&
            _categories.isNotEmpty) {
          final categoryName = _categoryController.text;
          // Support multiple categories separated by comma
          final categoryNames = categoryName
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

          Future.microtask(() {
            if (!mounted) return;
            final matchedCategories = <CategoryModel>[];

            for (final name in categoryNames) {
              try {
                final matchingCategory = _categories.firstWhere(
                  (cat) => cat.name.toLowerCase() == name.toLowerCase(),
                );
                matchedCategories.add(matchingCategory);
              } catch (e) {
                // Try partial match
                try {
                  final partialMatch = _categories.firstWhere(
                    (cat) =>
                        cat.name.toLowerCase().contains(name.toLowerCase()) ||
                        name.toLowerCase().contains(cat.name.toLowerCase()),
                  );
                  matchedCategories.add(partialMatch);
                } catch (e2) {
                  // No match found for this category
                }
              }
            }

            if (matchedCategories.isNotEmpty) {
              setState(() {
                _selectedCategories = matchedCategories;
                _categoryController.text = matchedCategories
                    .map((c) => c.name)
                    .join(', ');
              });
            }
          });
        }
      });
    } catch (e) {
      Future.microtask(() {
        if (!mounted) return;
        setState(() {
          _isLoadingCategories = false;
        });
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi tải danh sách thể loại: ${e.toString()}'),
            ),
          );
        }
      });
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
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _selectedCoverImage = result.files.single;
          });
        }
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
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _selectedBookFile = result.files.single;
          });
        }
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

    // Use microtask to ensure safe setState
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _isUploading = true;
        });
      }
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

      // Validate category selection
      if (_selectedCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ít nhất một thể loại')),
        );
        Future.microtask(() {
          if (mounted) {
            setState(() {
              _isUploading = false;
            });
          }
        });
        return;
      }

      // Lưu danh sách thể loại (dùng thể loại đầu tiên làm category chính, và lưu tất cả vào tags)
      final categoryNames = _selectedCategories.map((c) => c.name).toList();
      final mainCategory = categoryNames.first;

      final bookData = {
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': mainCategory, // Thể loại chính (để tương thích với code cũ)
        'categories': categoryNames, // Danh sách tất cả thể loại
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

      String? oldCategoryName;
      if (widget.book != null) {
        oldCategoryName = widget.book!.category;
        await FirebaseFirestore.instance
            .collection('books')
            .doc(widget.book!.id)
            .update(bookData);
      } else {
        await FirebaseFirestore.instance.collection('books').add(bookData);
      }

      // Update book count for all selected categories
      final categoryService = CategoryService();
      try {
        // Update count for all new categories
        for (final category in _selectedCategories) {
          await categoryService.updateBookCountByName(category.name);
        }

        // If editing and category changed, update old category count too
        if (widget.book != null && oldCategoryName != null) {
          // Only update old category if it's not in the new list
          if (!categoryNames.contains(oldCategoryName)) {
            await categoryService.updateBookCountByName(oldCategoryName);
          }
        }
      } catch (e) {
        debugPrint('Lỗi cập nhật số lượng sách: $e');
      }

      if (mounted) {
        // Close dialog first
        Navigator.pop(context);

        // Update state after navigation completes
        Future.microtask(() {
          if (mounted) {
            setState(() {
              _isUploading = false;
            });
          }
        });

        // Wait multiple frames before calling onSaved to ensure dialog is fully closed
        // and all builds are complete
        SchedulerBinding.instance.addPostFrameCallback((_) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 200), () {
              widget.onSaved();
              if (mounted && context.mounted) {
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
            });
          });
        });
      }
    } catch (e) {
      if (mounted) {
        // Use microtask to ensure safe setState
        Future.microtask(() {
          if (mounted) {
            setState(() {
              _isUploading = false;
            });
          }
        });
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
                color: AppColors.primary,
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
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.book != null
                          ? Icons.edit
                          : Icons.add_circle_outline,
                      color: AppColors.primary,
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
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.accent),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accent.withOpacity(0.2),
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

                      _buildCategoryDropdown(),

                      const SizedBox(height: 24),

                      // Divider
                      Divider(color: Colors.grey[300], height: 1),
                      const SizedBox(height: 24),

                      // Details Section
                      _buildSectionLabel('Chi tiết', Icons.settings_outlined),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _pageCountController,
                        label: 'Số trang',
                        icon: Icons.auto_stories_outlined,
                        keyboardType: TextInputType.number,
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
                        color: AppColors.accent,
                      ),

                      const SizedBox(height: 12),

                      _buildFilePickerButton(
                        label: 'Chọn file sách',
                        icon: Icons.picture_as_pdf_outlined,
                        selectedFile: _selectedBookFile,
                        existingUrl: _fileUrl,
                        onTap: _isUploading ? null : _pickBookFile,
                        color: AppColors.accent,
                      ),

                      if (_isUploading) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.accent,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Đang tải lên...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
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
              padding: const EdgeInsets.all(20),
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
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isUploading
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, size: 18, color: Colors.grey[700]),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Hủy',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _saveBook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        shadowColor: AppColors.accent.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save_outlined, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              widget.book != null ? 'Cập nhật' : 'Lưu',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
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
          prefixIcon: Icon(icon, color: AppColors.accent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
          floatingLabelStyle: TextStyle(
            color: AppColors.accent,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
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

  Widget _buildCategoryDropdown() {
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
      child: InkWell(
        onTap: _isLoadingCategories || _categories.isEmpty
            ? null
            : () => _showCategoryPicker(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedCategories.isNotEmpty
                      ? _getColorFromHex(
                          _selectedCategories.first.color,
                        ).withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_offer_outlined,
                  color: _selectedCategories.isNotEmpty
                      ? _getColorFromHex(_selectedCategories.first.color)
                      : Colors.grey[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Thể loại',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _isLoadingCategories
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _selectedCategories.isNotEmpty
                                ? _selectedCategories.length == 1
                                      ? _selectedCategories.first.name
                                      : '${_selectedCategories.length} thể loại đã chọn'
                                : 'Chọn thể loại',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _selectedCategories.isNotEmpty
                                  ? AppColors.textPrimary
                                  : Colors.grey[400],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down_rounded,
                color: Colors.grey[600],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorFromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.category_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chọn thể loại',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (_selectedCategories.isNotEmpty)
                            Text(
                              'Đã chọn: ${_selectedCategories.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                        ],
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
              // Categories list
              Flexible(
                child: _categories.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có thể loại nào',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _selectedCategories.any(
                            (c) => c.id == category.id,
                          );
                          final categoryColor = _getColorFromHex(
                            category.color,
                          );

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? categoryColor.withOpacity(0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? categoryColor
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? categoryColor.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // Update selected categories
                                  if (isSelected) {
                                    // Bỏ chọn nếu đã chọn
                                    _selectedCategories.removeWhere(
                                      (c) => c.id == category.id,
                                    );
                                  } else {
                                    // Thêm vào danh sách nếu chưa chọn
                                    _selectedCategories.add(category);
                                  }

                                  // Update dialog state to rebuild UI (rebuilds everything inside StatefulBuilder)
                                  setModalState(() {});

                                  // Update parent state and controller
                                  setState(() {
                                    _categoryController.text =
                                        _selectedCategories
                                            .map((c) => c.name)
                                            .join(', ');
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              categoryColor,
                                              categoryColor.withOpacity(0.7),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: categoryColor.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.local_offer_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              category.name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            if (category
                                                .description
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                category.description,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? categoryColor
                                                : Colors.grey[400]!,
                                            width: 2,
                                          ),
                                          color: isSelected
                                              ? categoryColor
                                              : Colors.transparent,
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 16,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Footer with Done button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Update category controller text
                      _categoryController.text = _selectedCategories
                          .map((c) => c.name)
                          .join(', ');
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Builder(
                      builder: (context) {
                        // This will be rebuilt by setModalState
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Xong (${_selectedCategories.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
