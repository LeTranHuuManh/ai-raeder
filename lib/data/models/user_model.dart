import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final List<String> favoriteBooks;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.isAdmin = false,
    required this.createdAt,
    this.lastLoginAt,
    this.favoriteBooks = const [],
    this.preferences,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'isAdmin': isAdmin,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
      'favoriteBooks': favoriteBooks,
      'preferences': preferences ?? {},
    };
  }

  // Create from Firestore Document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      phoneNumber: map['phoneNumber'],
      isAdmin: map['isAdmin'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLoginAt: map['lastLoginAt'] != null
          ? (map['lastLoginAt'] as Timestamp).toDate()
          : null,
      favoriteBooks: List<String>.from(map['favoriteBooks'] ?? []),
      preferences: map['preferences'] as Map<String, dynamic>?,
    );
  }

  // Create from Firebase User
  factory UserModel.fromFirebaseUser(dynamic firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? 'User',
      photoUrl: firebaseUser.photoURL,
      phoneNumber: firebaseUser.phoneNumber,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }

  // Copy with method
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    List<String>? favoriteBooks,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      favoriteBooks: favoriteBooks ?? this.favoriteBooks,
      preferences: preferences ?? this.preferences,
    );
  }
}
