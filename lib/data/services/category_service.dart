import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categories';

  // Get all categories
  Future<List<CategoryModel>> getCategories() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách thể loại: $e');
    }
  }

  // Get categories stream for real-time updates
  Stream<List<CategoryModel>> getCategoriesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CategoryModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get category by ID
  Future<CategoryModel?> getCategoryById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return CategoryModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi khi lấy thông tin thể loại: $e');
    }
  }

  // Create new category
  Future<String> createCategory({
    required String name,
    required String description,
    String iconName = 'book',
    String color = '#6C63FF',
  }) async {
    try {
      final now = DateTime.now();
      final categoryData = {
        'name': name,
        'description': description,
        'iconName': iconName,
        'color': color,
        'bookCount': 0,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final docRef = await _firestore.collection(_collection).add(categoryData);
      return docRef.id;
    } catch (e) {
      throw Exception('Lỗi khi tạo thể loại: $e');
    }
  }

  // Update category
  Future<void> updateCategory({
    required String id,
    String? name,
    String? description,
    String? iconName,
    String? color,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (iconName != null) updateData['iconName'] = iconName;
      if (color != null) updateData['color'] = color;

      await _firestore.collection(_collection).doc(id).update(updateData);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật thể loại: $e');
    }
  }

  // Delete category
  Future<void> deleteCategory(String id) async {
    try {
      // Check if category has books
      final bookCount = await _getBookCountForCategory(id);
      if (bookCount > 0) {
        throw Exception(
          'Không thể xóa thể loại này vì còn $bookCount cuốn sách trong thể loại',
        );
      }

      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Lỗi khi xóa thể loại: $e');
    }
  }

  // Update book count for category
  Future<void> updateBookCount(String categoryId) async {
    try {
      final count = await _getBookCountForCategory(categoryId);
      await _firestore.collection(_collection).doc(categoryId).update({
        'bookCount': count,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Lỗi khi cập nhật số lượng sách: $e');
    }
  }

  // Get book count for a category
  Future<int> _getBookCountForCategory(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection('books')
          .where('categoryId', isEqualTo: categoryId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Search categories
  Future<List<CategoryModel>> searchCategories(String query) async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      final categories = snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();

      return categories
          .where(
            (category) =>
                category.name.toLowerCase().contains(query.toLowerCase()) ||
                category.description.toLowerCase().contains(
                  query.toLowerCase(),
                ),
          )
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tìm kiếm thể loại: $e');
    }
  }
}
