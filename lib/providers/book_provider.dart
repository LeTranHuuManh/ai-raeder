import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/book_model.dart';

class BookProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<BookModel> _books = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BookModel> get books => _books;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBooks() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final snapshot = await _firestore.collection('books').get();
      _books = snapshot.docs
          .map((doc) => BookModel.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi tải danh sách sách: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> fetchBookById(String bookId) async {
    try {
      final doc = await _firestore.collection('books').doc(bookId).get();
      if (doc.exists) {
        final book = BookModel.fromMap({
          'id': doc.id,
          ...doc.data()!,
        });
        final index = _books.indexWhere((b) => b.id == bookId);
        if (index != -1) {
          _books[index] = book;
        } else {
          _books.add(book);
        }
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Lỗi tải thông tin sách: ${e.toString()}';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
