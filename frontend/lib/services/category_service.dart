import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import 'api_service.dart';

class CategoryService {
  final ApiService _apiService = ApiService();

  Future<List<CategoryModel>> getCategories({bool activeOnly = false}) async {
    try {
      final response = await _apiService.dio.get(
        '/categories',
        queryParameters: {'activeOnly': activeOnly},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        return data.map((c) => CategoryModel.fromMap(c)).toList();
      }
    } catch (e) {
      debugPrint('Erro ao buscar categorias: $e');
    }
    return [];
  }

  Future<CategoryModel?> createCategory(String name, String description) async {
    try {
      final response = await _apiService.dio.post(
        '/categories',
        data: {
          'name': name,
          'description': description,
        },
      );
      if (response.statusCode == 201) {
        return CategoryModel.fromMap(response.data['data']);
      }
    } catch (e) {
      debugPrint('Erro ao criar categoria: $e');
    }
    return null;
  }

  Future<bool> deleteCategory(String id) async {
    try {
      final response = await _apiService.dio.delete('/categories/$id');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro ao deletar categoria: $e');
      return false;
    }
  }

  Future<ActivityModel?> createActivity(
      String name, String description, String categoryId) async {
    try {
      final response = await _apiService.dio.post(
        '/activities',
        data: {
          'name': name,
          'description': description,
          'categoryId': categoryId,
        },
      );
      if (response.statusCode == 201) {
        return ActivityModel.fromMap(response.data['data']);
      }
    } catch (e) {
      debugPrint('Erro ao criar atividade: $e');
    }
    return null;
  }

  Future<bool> deleteActivity(String id) async {
    try {
      final response = await _apiService.dio.delete('/activities/$id');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro ao deletar atividade: $e');
      return false;
    }
  }
}
