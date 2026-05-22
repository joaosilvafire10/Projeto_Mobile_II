import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> fetchCategories({bool activeOnly = false}) async {
    _isLoading = true;
    notifyListeners();
    _categories = await _categoryService.getCategories(activeOnly: activeOnly);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addCategory(String name, String description) async {
    _isLoading = true;
    notifyListeners();
    final newCat = await _categoryService.createCategory(name, description);
    _isLoading = false;
    if (newCat != null) {
      _categories.add(newCat);
      _categories.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<bool> removeCategory(String id) async {
    _isLoading = true;
    notifyListeners();
    final success = await _categoryService.deleteCategory(id);
    _isLoading = false;
    if (success) {
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<bool> addActivity(
      String name, String description, String categoryId) async {
    _isLoading = true;
    notifyListeners();
    final newAct =
        await _categoryService.createActivity(name, description, categoryId);
    _isLoading = false;
    if (newAct != null) {
      // Find category and add activity locally
      final catIndex = _categories.indexWhere((c) => c.id == categoryId);
      if (catIndex != -1) {
        final category = _categories[catIndex];
        final updatedActivities = List<ActivityModel>.from(category.activities)
          ..add(newAct)
          ..sort((a, b) => a.name.compareTo(b.name));

        _categories[catIndex] = CategoryModel(
          id: category.id,
          name: category.name,
          description: category.description,
          active: category.active,
          activities: updatedActivities,
        );
      }
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<bool> removeActivity(String id, String categoryId) async {
    _isLoading = true;
    notifyListeners();
    final success = await _categoryService.deleteActivity(id);
    _isLoading = false;
    if (success) {
      final catIndex = _categories.indexWhere((c) => c.id == categoryId);
      if (catIndex != -1) {
        final category = _categories[catIndex];
        final updatedActivities = List<ActivityModel>.from(category.activities)
          ..removeWhere((a) => a.id == id);

        _categories[catIndex] = CategoryModel(
          id: category.id,
          name: category.name,
          description: category.description,
          active: category.active,
          activities: updatedActivities,
        );
      }
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }
}
