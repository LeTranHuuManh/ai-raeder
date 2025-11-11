import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/reading_history_model.dart';

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

      final bookmark = BookmarkModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        page: page,
        chapterName: chapterName,
        createdAt: DateTime.now(),
      );

      await docRef.update({
        'bookmarks': FieldValue.arrayUnion([bookmark.toMap()]),
      });

      notifyListeners();
    } catch (e) {
      // Handle error
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
