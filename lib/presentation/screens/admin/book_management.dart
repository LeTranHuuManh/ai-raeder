import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
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
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa sách "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa'),
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
            const SnackBar(content: Text('Đã xóa sách thành công')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa sách: ${e.toString()}')),
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
      appBar: AppBar(
        title: const Text('Quản lý sách'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBooks),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sách...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _filteredBooks.isEmpty
                ? const Center(child: Text('Không có sách nào'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = _filteredBooks[index];
                      return _buildBookItem(book);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBookDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBookItem(BookModel book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: book.coverImageUrl,
            width: 60,
            height: 80,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 60,
              height: 80,
              color: AppColors.gray200,
              child: const Icon(Icons.book),
            ),
            errorWidget: (context, url, error) => Container(
              width: 60,
              height: 80,
              color: AppColors.gray200,
              child: const Icon(Icons.book),
            ),
          ),
        ),
        title: Text(book.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.author),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${book.rating.toStringAsFixed(1)}'),
                const SizedBox(width: 16),
                Icon(Icons.visibility, size: 14),
                const SizedBox(width: 4),
                Text('${book.viewCount}'),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showAddBookDialog(book: book),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () => _deleteBook(book),
            ),
          ],
        ),
        isThreeLine: true,
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
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.book != null ? 'Chỉnh sửa sách' : 'Thêm sách mới',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Vui lòng nhập tiêu đề' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _authorController,
                  decoration: const InputDecoration(
                    labelText: 'Tác giả',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Vui lòng nhập tác giả' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Vui lòng nhập mô tả' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Thể loại',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Vui lòng nhập thể loại'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<BookFormat>(
                        value: _selectedFormat,
                        decoration: const InputDecoration(
                          labelText: 'Định dạng',
                          border: OutlineInputBorder(),
                        ),
                        items: BookFormat.values.map((format) {
                          return DropdownMenuItem(
                            value: format,
                            child: Text(format.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedFormat = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pageCountController,
                        decoration: const InputDecoration(
                          labelText: 'Số trang',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Miễn phí'),
                        value: _isFree,
                        onChanged: (value) {
                          setState(() {
                            _isFree = value ?? true;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (!_isFree) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Giá',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickCoverImage,
                        icon: const Icon(Icons.image),
                        label: Text(
                          _selectedCoverImage != null
                              ? 'Ảnh: ${_selectedCoverImage!.name}'
                              : (_coverImageUrl != null
                                    ? 'Đã có ảnh'
                                    : 'Chọn ảnh bìa'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickBookFile,
                        icon: const Icon(Icons.file_upload),
                        label: Text(
                          _selectedBookFile != null
                              ? 'File: ${_selectedBookFile!.name}'
                              : (_fileUrl != null
                                    ? 'Đã có file'
                                    : 'Chọn file sách'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isUploading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Đang upload file lên Cloudinary...'),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveBook,
                      child: const Text('Lưu'),
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
