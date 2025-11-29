import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/reading_history_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class ReadingProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ReadingHistoryModel? _currentReading;
  List<ReadingHistoryModel> _readingHistory = [];
  bool _isLoading = false;

  // Reader settings
  double _fontSize = 16.0;
  String _fontFamily = 'Inter';
  Color _backgroundColor = Colors.white;
  Color _textColor = Colors.black;
  double _lineHeight = 1.5;
  bool _isNightMode = false;

  ReadingHistoryModel? get currentReading => _currentReading;
  List<ReadingHistoryModel> get readingHistory => _readingHistory;
  bool get isLoading => _isLoading;

  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  Color get backgroundColor => _backgroundColor;
  Color get textColor => _textColor;
  double get lineHeight => _lineHeight;
  bool get isNightMode => _isNightMode;

  Future<void> fetchReadingHistory(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore
          .collection('readingHistory')
          .where('userId', isEqualTo: userId)
          .orderBy('lastReadAt', descending: true)
          .get();

      _readingHistory = snapshot.docs
          .map((doc) => ReadingHistoryModel.fromMap(doc.data()))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ReadingHistoryModel?> getReadingProgress(
    String userId,
    String bookId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('readingHistory')
          .where('userId', isEqualTo: userId)
          .where('bookId', isEqualTo: bookId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ReadingHistoryModel.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateReadingProgress({
    required String userId,
    required String bookId,
    required int currentPage,
    required int totalPages,
  }) async {
    try {
      final progress = totalPages > 0 ? (currentPage / totalPages) : 0.0;

      final historyId = '${userId}_$bookId';
      final docRef = _firestore.collection('readingHistory').doc(historyId);
      final doc = await docRef.get();

      if (doc.exists) {
        final existingHistory = ReadingHistoryModel.fromMap(doc.data()!);
        final updatedHistory = ReadingHistoryModel(
          id: historyId,
          userId: userId,
          bookId: bookId,
          currentPage: currentPage,
          totalPages: totalPages,
          progress: progress,
          lastReadAt: DateTime.now(),
          readingTimeMinutes: existingHistory.readingTimeMinutes,
          bookmarks: existingHistory.bookmarks,
          highlights: existingHistory.highlights,
          notes: existingHistory.notes,
        );
        await docRef.update(updatedHistory.toMap());
        _currentReading = updatedHistory;
      } else {
        final newHistory = ReadingHistoryModel(
          id: historyId,
          userId: userId,
          bookId: bookId,
          currentPage: currentPage,
          totalPages: totalPages,
          progress: progress,
          lastReadAt: DateTime.now(),
        );
        await docRef.set(newHistory.toMap());
        _currentReading = newHistory;
      }

      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> addBookmark({
    required String userId,
    required String bookId,
    required int page,
    required String chapterName,
  }) async {
    try {
      final historyId = '${userId}_$bookId';
      final docRef = _firestore.collection('readingHistory').doc(historyId);
      final doc = await docRef.get();

      // Check if bookmark already exists for this page
      List<BookmarkModel> existingBookmarks = [];
      if (doc.exists) {
        final data = doc.data()!;
        existingBookmarks = (data['bookmarks'] as List?)
                ?.map((b) => BookmarkModel.fromMap(b))
                .toList() ??
            [];
        
        // Check if bookmark already exists
        if (existingBookmarks.any((b) => b.page == page)) {
          return; // Bookmark already exists
        }
      }

      final bookmark = BookmarkModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        page: page,
        chapterName: chapterName,
        createdAt: DateTime.now(),
      );

      if (doc.exists) {
        // Document exists, use update
        await docRef.update({
          'bookmarks': FieldValue.arrayUnion([bookmark.toMap()]),
        });
      } else {
        // Document doesn't exist, create it first
        final newHistory = ReadingHistoryModel(
          id: historyId,
          userId: userId,
          bookId: bookId,
          currentPage: 0,
          totalPages: 0,
          progress: 0.0,
          lastReadAt: DateTime.now(),
          bookmarks: [bookmark],
        );
        await docRef.set(newHistory.toMap());
      }

      // Update local state
      if (_currentReading != null && _currentReading!.bookId == bookId) {
        final updatedBookmarks = List<BookmarkModel>.from(
          _currentReading!.bookmarks,
        )..add(bookmark);
        _currentReading = ReadingHistoryModel(
          id: _currentReading!.id,
          userId: _currentReading!.userId,
          bookId: _currentReading!.bookId,
          currentPage: _currentReading!.currentPage,
          totalPages: _currentReading!.totalPages,
          progress: _currentReading!.progress,
          lastReadAt: _currentReading!.lastReadAt,
          readingTimeMinutes: _currentReading!.readingTimeMinutes,
          bookmarks: updatedBookmarks,
          highlights: _currentReading!.highlights,
          notes: _currentReading!.notes,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding bookmark: $e');
    }
  }

  Future<void> removeBookmark({
    required String userId,
    required String bookId,
    required String bookmarkId,
  }) async {
    try {
      final historyId = '${userId}_$bookId';
      final docRef = _firestore.collection('readingHistory').doc(historyId);
      final doc = await docRef.get();

      if (!doc.exists) return;

      final data = doc.data()!;
      
      // Verify userId matches (security check)
      if (data['userId'] != userId) {
        throw Exception('Permission denied: User ID mismatch');
      }

      final bookmarks = (data['bookmarks'] as List?)
              ?.map((b) => BookmarkModel.fromMap(b))
              .toList() ??
          [];

      final updatedBookmarks = bookmarks
          .where((b) => b.id != bookmarkId)
          .map((b) => b.toMap())
          .toList();

      await docRef.update({
        'bookmarks': updatedBookmarks,
        'userId': userId, // Ensure userId is preserved
      });

      // Update local state
      if (_currentReading != null && _currentReading!.bookId == bookId) {
        final updatedBookmarksList = _currentReading!.bookmarks
            .where((b) => b.id != bookmarkId)
            .toList();
        _currentReading = ReadingHistoryModel(
          id: _currentReading!.id,
          userId: _currentReading!.userId,
          bookId: _currentReading!.bookId,
          currentPage: _currentReading!.currentPage,
          totalPages: _currentReading!.totalPages,
          progress: _currentReading!.progress,
          lastReadAt: _currentReading!.lastReadAt,
          readingTimeMinutes: _currentReading!.readingTimeMinutes,
          bookmarks: updatedBookmarksList,
          highlights: _currentReading!.highlights,
          notes: _currentReading!.notes,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error removing bookmark: $e');
    }
  }

  Future<void> loadReadingProgress({
    required String userId,
    required String bookId,
  }) async {
    try {
      final progress = await getReadingProgress(userId, bookId);
      _currentReading = progress;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading reading progress: $e');
    }
  }

  Future<void> addHighlight({
    required String userId,
    required String bookId,
    required String text,
    required int page,
    String color = '#FFEB3B',
  }) async {
    try {
      final historyId = '${userId}_$bookId';
      final docRef = _firestore.collection('readingHistory').doc(historyId);

      final highlight = HighlightModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        page: page,
        color: color,
        createdAt: DateTime.now(),
      );

      await docRef.update({
        'highlights': FieldValue.arrayUnion([highlight.toMap()]),
      });

      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> addNote({
    required String userId,
    required String bookId,
    required String content,
    required int page,
  }) async {
    try {
      final historyId = '${userId}_$bookId';
      final docRef = _firestore.collection('readingHistory').doc(historyId);

      final note = NoteModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        page: page,
        createdAt: DateTime.now(),
      );

      await docRef.update({
        'notes': FieldValue.arrayUnion([note.toMap()]),
      });

      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  // Reader settings methods
  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  void setFontFamily(String family) {
    _fontFamily = family;
    notifyListeners();
  }

  void setBackgroundColor(Color color) {
    _backgroundColor = color;
    notifyListeners();
  }

  void setTextColor(Color color) {
    _textColor = color;
    notifyListeners();
  }

  void setLineHeight(double height) {
    _lineHeight = height;
    notifyListeners();
  }

  void toggleNightMode() {
    _isNightMode = !_isNightMode;
    if (_isNightMode) {
      _backgroundColor = const Color(0xFF1A1A2E);
      _textColor = Colors.white;
    } else {
      _backgroundColor = Colors.white;
      _textColor = Colors.black;
    }
    notifyListeners();
  }
}
