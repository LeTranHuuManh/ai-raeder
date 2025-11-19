
import 'dart:io';
import 'package:flutter/material.dart';
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
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.path != null) {
      await _uploadImage(result.files.single.path!);
    }
  }

  Future<void> _pickBookFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null && result.files.single.path != null) {
      await _uploadFile(result.files.single.path!);
    }
  }

  Future<void> _uploadImage(String path) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('File không tồn tại');
      }

      debugPrint('Uploading image to Cloudinary...');

      final cloudinaryService = CloudinaryService();
      final url = await cloudinaryService.uploadImage(
        file,
        folder: 'book_covers',
      );

      if (url == null) {
        throw Exception('Không nhận được URL từ Cloudinary');
      }

      setState(() {
        _coverImageUrl = url;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload ảnh thành công')));
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      String errorMessage = 'Lỗi upload ảnh: ${e.toString()}';
      String detailMessage = '';

      if (e.toString().contains('Cloudinary chưa được cấu hình')) {
        errorMessage = 'Cloudinary chưa được cấu hình.';
        detailMessage = '''
Hướng dẫn khắc phục:
1. Vào Cloudinary Console: https://console.cloudinary.com
2. Đăng nhập hoặc tạo tài khoản
3. Lấy thông tin từ Dashboard:
   - Cloud Name
   - API Key
   - API Secret
4. Thêm vào file .env:
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_API_KEY=your_api_key
   CLOUDINARY_API_SECRET=your_api_secret
5. Restart ứng dụng
        ''';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Lỗi Upload'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(errorMessage),
                  if (detailMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Chi tiết:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(detailMessage, style: const TextStyle(fontSize: 12)),
                  ],
                ],
              ),
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
    }
  }

  Future<void> _uploadFile(String path) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('File không tồn tại');
      }

      debugPrint('Uploading file to Cloudinary...');

      final cloudinaryService = CloudinaryService();
      final url = await cloudinaryService.uploadImage(
        file,
        folder: 'books',
      );

      if (url == null) {
        throw Exception('Không nhận được URL từ Cloudinary');
      }

      setState(() {
        _fileUrl = url;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload file thành công')));
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      String errorMessage = 'Lỗi upload file: ${e.toString()}';
      String detailMessage = '';

      if (e.toString().contains('Cloudinary chưa được cấu hình')) {
        errorMessage = 'Cloudinary chưa được cấu hình.';
        detailMessage = '''
Hướng dẫn khắc phục:
1. Vào Cloudinary Console: https://console.cloudinary.com
2. Đăng nhập hoặc tạo tài khoản
3. Lấy thông tin từ Dashboard:
   - Cloud Name
   - API Key
   - API Secret
4. Thêm vào file .env:
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_API_KEY=your_api_key
   CLOUDINARY_API_SECRET=your_api_secret
5. Restart ứng dụng
        ''';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Lỗi Upload'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(errorMessage),
                  if (detailMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Chi tiết:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(detailMessage, style: const TextStyle(fontSize: 12)),
                  ],
                ],
              ),
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
    }
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;
    if (_coverImageUrl == null || _fileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh bìa và file sách')),
      );
      return;
    }

    try {
      final bookData = {
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim(),
        'coverImageUrl': _coverImageUrl,
        'fileUrl': _fileUrl,
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
                          _coverImageUrl != null
                              ? 'Đã chọn ảnh'
                              : 'Chọn ảnh bìa',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickBookFile,
                        icon: const Icon(Icons.file_upload),
                        label: Text(
                          _fileUrl != null ? 'Đã chọn file' : 'Chọn file sách',
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isUploading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
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
