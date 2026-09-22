class MealItem {
  final String title;
  final String description;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;
  final int prepTimeMin;
  final List<String> ingredients;

  const MealItem({
    required this.title,
    required this.description,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    this.prepTimeMin = 15,
    this.ingredients = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'calories': calories,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatsG': fatsG,
      'prepTimeMin': prepTimeMin,
      'ingredients': ingredients,
    };
  }

  factory MealItem.fromMap(Map<String, dynamic> map) {
    return MealItem(
      title: map['title'] as String? ?? 'Healthy Meal',
      description: map['description'] as String? ?? '',
      calories: (map['calories'] as num?)?.toInt() ?? 350,
      proteinG: (map['proteinG'] as num?)?.toInt() ?? 20,
      carbsG: (map['carbsG'] as num?)?.toInt() ?? 35,
      fatsG: (map['fatsG'] as num?)?.toInt() ?? 10,
      prepTimeMin: (map['prepTimeMin'] as num?)?.toInt() ?? 15,
      ingredients: (map['ingredients'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class DailyMealPlan {
  final String dayName; // e.g. "Today", "Monday", etc.
  final MealItem breakfast;
  final MealItem lunch;
  final MealItem snacks;
  final MealItem dinner;

  const DailyMealPlan({
    required this.dayName,
    required this.breakfast,
    required this.lunch,
    required this.snacks,
    required this.dinner,
  });

  int get totalCalories =>
      breakfast.calories + lunch.calories + snacks.calories + dinner.calories;
  int get totalProtein =>
      breakfast.proteinG + lunch.proteinG + snacks.proteinG + dinner.proteinG;
  int get totalCarbs =>
      breakfast.carbsG + lunch.carbsG + snacks.carbsG + dinner.carbsG;
  int get totalFats =>
      breakfast.fatsG + lunch.fatsG + snacks.fatsG + dinner.fatsG;

  Map<String, dynamic> toMap() {
    return {
      'dayName': dayName,
      'breakfast': breakfast.toMap(),
      'lunch': lunch.toMap(),
      'snacks': snacks.toMap(),
      'dinner': dinner.toMap(),
    };
  }

  factory DailyMealPlan.fromMap(Map<String, dynamic> map) {
    return DailyMealPlan(
      dayName: map['dayName'] as String? ?? 'Day 1',
      breakfast: MealItem.fromMap(map['breakfast'] as Map<String, dynamic>? ?? {}),
      lunch: MealItem.fromMap(map['lunch'] as Map<String, dynamic>? ?? {}),
      snacks: MealItem.fromMap(map['snacks'] as Map<String, dynamic>? ?? {}),
      dinner: MealItem.fromMap(map['dinner'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class MealPlan {
  final String id;
  final String title;
  final String healthGoal;
  final String dietPreference;
  final DateTime createdAt;
  final List<DailyMealPlan> days;

  const MealPlan({
    required this.id,
    required this.title,
    required this.healthGoal,
    required this.dietPreference,
    required this.createdAt,
    required this.days,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'healthGoal': healthGoal,
      'dietPreference': dietPreference,
      'createdAt': createdAt.toIso8601String(),
      'days': days.map((d) => d.toMap()).toList(),
    };
  }

  factory MealPlan.fromMap(Map<String, dynamic> map) {
    return MealPlan(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: map['title'] as String? ?? 'Personalized Meal Plan',
      healthGoal: map['healthGoal'] as String? ?? 'Healthy Lifestyle',
      dietPreference: map['dietPreference'] as String? ?? 'Balanced',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      days: (map['days'] as List<dynamic>?)
              ?.map((d) => DailyMealPlan.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
