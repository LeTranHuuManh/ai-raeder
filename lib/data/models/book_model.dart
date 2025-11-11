import 'package:cloud_firestore/cloud_firestore.dart';

enum BookFormat { epub, pdf, txt }

class BookModel {
  final String id;
  final String title;
  final String author;
  final String description;
  final String coverImageUrl;
  final String fileUrl;
  final BookFormat format;
  final String category;
  final List<String> tags;
  final double rating;
  final int reviewCount;
  final int pageCount;
  final String language;
  final DateTime publishedDate;
  final DateTime addedAt;
  final int viewCount;
  final int downloadCount;
  final bool isFree;
  final double? price;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.coverImageUrl,
    required this.fileUrl,
    required this.format,
    required this.category,
    this.tags = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.pageCount = 0,
    this.language = 'vi',
    required this.publishedDate,
    required this.addedAt,
    this.viewCount = 0,
    this.downloadCount = 0,
    this.isFree = true,
    this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'fileUrl': fileUrl,
      'format': format.name,
      'category': category,
      'tags': tags,
      'rating': rating,
      'reviewCount': reviewCount,
      'pageCount': pageCount,
      'language': language,
      'publishedDate': Timestamp.fromDate(publishedDate),
      'addedAt': Timestamp.fromDate(addedAt),
      'viewCount': viewCount,
      'downloadCount': downloadCount,
      'isFree': isFree,
      'price': price,
    };
  }

  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      description: map['description'] ?? '',
      coverImageUrl: map['coverImageUrl'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      format: BookFormat.values.firstWhere(
        (e) => e.name == map['format'],
        orElse: () => BookFormat.pdf,
      ),
      category: map['category'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      rating: (map['rating'] ?? 0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      pageCount: map['pageCount'] ?? 0,
      language: map['language'] ?? 'vi',
      publishedDate: (map['publishedDate'] as Timestamp).toDate(),
      addedAt: (map['addedAt'] as Timestamp).toDate(),
      viewCount: map['viewCount'] ?? 0,
      downloadCount: map['downloadCount'] ?? 0,
      isFree: map['isFree'] ?? true,
      price: map['price']?.toDouble(),
    );
  }

  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? coverImageUrl,
    String? fileUrl,
    BookFormat? format,
    String? category,
    List<String>? tags,
    double? rating,
    int? reviewCount,
    int? pageCount,
    String? language,
    DateTime? publishedDate,
    DateTime? addedAt,
    int? viewCount,
    int? downloadCount,
    bool? isFree,
    double? price,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      format: format ?? this.format,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      pageCount: pageCount ?? this.pageCount,
      language: language ?? this.language,
      publishedDate: publishedDate ?? this.publishedDate,
      addedAt: addedAt ?? this.addedAt,
      viewCount: viewCount ?? this.viewCount,
      downloadCount: downloadCount ?? this.downloadCount,
      isFree: isFree ?? this.isFree,
      price: price ?? this.price,
    );
  }
}
