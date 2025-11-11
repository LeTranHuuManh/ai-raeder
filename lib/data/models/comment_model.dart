import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String bookId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String content;
  final double rating;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likesCount;
  final List<String> likedBy;
  final bool isApproved;

  CommentModel({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.content,
    required this.rating,
    required this.createdAt,
    this.updatedAt,
    this.likesCount = 0,
    this.likedBy = const [],
    this.isApproved = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'likesCount': likesCount,
      'likedBy': likedBy,
      'isApproved': isApproved,
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] ?? '',
      bookId: map['bookId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      content: map['content'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      likesCount: map['likesCount'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      isApproved: map['isApproved'] ?? true,
    );
  }

  CommentModel copyWith({
    String? id,
    String? bookId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? content,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    List<String>? likedBy,
    bool? isApproved,
  }) {
    return CommentModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      content: content ?? this.content,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}
