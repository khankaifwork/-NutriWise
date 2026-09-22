class Recipe {
  final String id;
  final String title;
  final String category;
  final String description;
  final int prepTimeMin;
  final int cookTimeMin;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatsG;
  final List<String> ingredients;
  final List<String> instructions;
  final String? youtubeUrl;
  final String imageUrl;
  final bool isFavorite;

  const Recipe({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.prepTimeMin,
    required this.cookTimeMin,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    required this.ingredients,
    required this.instructions,
    this.youtubeUrl,
    required this.imageUrl,
    this.isFavorite = false,
  });

  int get totalTimeMin => prepTimeMin + cookTimeMin;

  Recipe copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    int? prepTimeMin,
    int? cookTimeMin,
    int? calories,
    int? proteinG,
    int? carbsG,
    int? fatsG,
    List<String>? ingredients,
    List<String>? instructions,
    String? youtubeUrl,
    String? imageUrl,
    bool? isFavorite,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      prepTimeMin: prepTimeMin ?? this.prepTimeMin,
      cookTimeMin: cookTimeMin ?? this.cookTimeMin,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatsG: fatsG ?? this.fatsG,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'prepTimeMin': prepTimeMin,
      'cookTimeMin': cookTimeMin,
      'calories': calories,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatsG': fatsG,
      'ingredients': ingredients,
      'instructions': instructions,
      'youtubeUrl': youtubeUrl,
      'imageUrl': imageUrl,
      'isFavorite': isFavorite,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      description: map['description'] as String? ?? '',
      prepTimeMin: (map['prepTimeMin'] as num?)?.toInt() ?? 10,
      cookTimeMin: (map['cookTimeMin'] as num?)?.toInt() ?? 20,
      calories: (map['calories'] as num?)?.toInt() ?? 300,
      proteinG: (map['proteinG'] as num?)?.toInt() ?? 15,
      carbsG: (map['carbsG'] as num?)?.toInt() ?? 30,
      fatsG: (map['fatsG'] as num?)?.toInt() ?? 10,
      ingredients: (map['ingredients'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      instructions: (map['instructions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      youtubeUrl: map['youtubeUrl'] as String?,
      imageUrl: map['imageUrl'] as String? ?? '',
      isFavorite: map['isFavorite'] as bool? ?? false,
    );
  }
}
