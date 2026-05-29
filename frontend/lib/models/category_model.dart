class ActivityModel {
  final String id;
  final String name;
  final String description;
  final bool active;
  final String categoryId;

  ActivityModel({
    required this.id,
    required this.name,
    this.description = '',
    this.active = true,
    required this.categoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'active': active,
      'categoryId': categoryId,
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      active: map['active'] ?? true,
      categoryId: map['categoryId'] ?? map['category_id'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final bool active;
  final List<ActivityModel> activities;

  CategoryModel({
    required this.id,
    required this.name,
    this.description = '',
    this.active = true,
    this.activities = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'active': active,
      'activities': activities.map((a) => a.toMap()).toList(),
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    var rawActivities = map['activities'] as List?;
    List<ActivityModel> activitiesList = rawActivities != null
        ? rawActivities.map((a) => ActivityModel.fromMap(a)).toList()
        : [];

    return CategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      active: map['active'] ?? true,
      activities: activitiesList,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
