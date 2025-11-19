import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firestore Collections
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get books => _firestore.collection('books');
  CollectionReference get comments => _firestore.collection('comments');
  CollectionReference get readingHistory =>
      _firestore.collection('readingHistory');

  // Batch write operations
  Future<bool> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      final batch = _firestore.batch();

      for (var operation in operations) {
        final type = operation['type'] as String;
        final collection = operation['collection'] as String;
        final docId = operation['docId'] as String;
        final data = operation['data'] as Map<String, dynamic>?;

        final ref = _firestore.collection(collection).doc(docId);

        switch (type) {
          case 'set':
            batch.set(ref, data!);
            break;
          case 'update':
            batch.update(ref, data!);
            break;
          case 'delete':
            batch.delete(ref);
            break;
        }
      }

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Query with pagination
  Future<QuerySnapshot> paginatedQuery({
    required String collection,
    required int limit,
    DocumentSnapshot? startAfter,
    String? orderBy,
    bool descending = false,
  }) async {
    Query query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    return await query.get();
  }

  // Real-time listener
  Stream<QuerySnapshot> listenToCollection(String collection) {
    return _firestore.collection(collection).snapshots();
  }

  // Real-time listener with conditions
  Stream<QuerySnapshot> listenToCollectionWhere({
    required String collection,
    required String field,
    required dynamic value,
  }) {
    return _firestore
        .collection(collection)
        .where(field, isEqualTo: value)
        .snapshots();
  }

  // Transaction
  Future<T?> runTransaction<T>(
    Future<T> Function(Transaction transaction) updateFunction,
  ) async {
    try {
      return await _firestore.runTransaction(updateFunction);
    } catch (e) {
      return null;
    }
  }

  // Check if document exists
  Future<bool> documentExists(String collection, String docId) async {
    try {
      final doc = await _firestore.collection(collection).doc(docId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Get document count
  Future<int> getCollectionCount(String collection) async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}
