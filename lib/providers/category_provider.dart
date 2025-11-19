import 'package:flutter/foundation.dart';
import '../data/models/category_model.dart';
import '../data/services/category_service.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all categories
  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _categoryService.getCategories();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _categories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get category by ID
  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  // Create new category
  Future<bool> createCategory({
    required String name,
    required String description,
    String iconName = 'book',
    String color = '#6C63FF',
  }) async {
    try {
      await _categoryService.createCategory(
        name: name,
        description: description,
        iconName: iconName,
        color: color,
      );
      await fetchCategories(); // Refresh list
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update category
  Future<bool> updateCategory({
    required String id,
    String? name,
    String? description,
    String? iconName,
    String? color,
  }) async {
    try {
      await _categoryService.updateCategory(
        id: id,
        name: name,
        description: description,
        iconName: iconName,
        color: color,
      );
      await fetchCategories(); // Refresh list
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete category
  Future<bool> deleteCategory(String id) async {
    try {
      await _categoryService.deleteCategory(id);
      await fetchCategories(); // Refresh list
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Search categories
  Future<void> searchCategories(String query) async {
    if (query.isEmpty) {
      await fetchCategories();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _categoryService.searchCategories(query);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
