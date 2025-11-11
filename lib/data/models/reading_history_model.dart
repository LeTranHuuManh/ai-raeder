import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingHistoryModel {
  final String id;
  final String userId;
  final String bookId;
  final int currentPage;
  final int totalPages;
  final double progress;
  final DateTime lastReadAt;
  final int readingTimeMinutes;
  final List<BookmarkModel> bookmarks;
  final List<HighlightModel> highlights;
  final List<NoteModel> notes;

  ReadingHistoryModel({
    required this.id,
    required this.userId,
    required this.bookId,
    this.currentPage = 0,
    this.totalPages = 0,
    this.progress = 0.0,
    required this.lastReadAt,
    this.readingTimeMinutes = 0,
    this.bookmarks = const [],
    this.highlights = const [],
    this.notes = const [],
  });

  double get progressPercentage =>
      totalPages > 0 ? (currentPage / totalPages) * 100 : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'bookId': bookId,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'progress': progress,
      'lastReadAt': Timestamp.fromDate(lastReadAt),
      'readingTimeMinutes': readingTimeMinutes,
      'bookmarks': bookmarks.map((b) => b.toMap()).toList(),
      'highlights': highlights.map((h) => h.toMap()).toList(),
      'notes': notes.map((n) => n.toMap()).toList(),
    };
  }

  factory ReadingHistoryModel.fromMap(Map<String, dynamic> map) {
    return ReadingHistoryModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      bookId: map['bookId'] ?? '',
      currentPage: map['currentPage'] ?? 0,
      totalPages: map['totalPages'] ?? 0,
      progress: (map['progress'] ?? 0).toDouble(),
      lastReadAt: (map['lastReadAt'] as Timestamp).toDate(),
      readingTimeMinutes: map['readingTimeMinutes'] ?? 0,
      bookmarks:
          (map['bookmarks'] as List?)
              ?.map((b) => BookmarkModel.fromMap(b))
              .toList() ??
          [],
      highlights:
          (map['highlights'] as List?)
              ?.map((h) => HighlightModel.fromMap(h))
              .toList() ??
          [],
      notes:
          (map['notes'] as List?)?.map((n) => NoteModel.fromMap(n)).toList() ??
          [],
    );
  }
}

class BookmarkModel {
  final String id;
  final int page;
  final String chapterName;
  final DateTime createdAt;

  BookmarkModel({
    required this.id,
    required this.page,
    required this.chapterName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'page': page,
      'chapterName': chapterName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory BookmarkModel.fromMap(Map<String, dynamic> map) {
    return BookmarkModel(
      id: map['id'] ?? '',
      page: map['page'] ?? 0,
      chapterName: map['chapterName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

class HighlightModel {
  final String id;
  final String text;
  final int page;
  final String color;
  final DateTime createdAt;

  HighlightModel({
    required this.id,
    required this.text,
    required this.page,
    this.color = '#FFEB3B',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'page': page,
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory HighlightModel.fromMap(Map<String, dynamic> map) {
    return HighlightModel(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      page: map['page'] ?? 0,
      color: map['color'] ?? '#FFEB3B',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

class NoteModel {
  final String id;
  final String content;
  final int page;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NoteModel({
    required this.id,
    required this.content,
    required this.page,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'page': page,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      page: map['page'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
