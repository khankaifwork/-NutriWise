class UserProfile {
  final String name;
  final int age;
  final String gender; // 'Male', 'Female', 'Other'
  final double heightCm;
  final double weightKg;
  final double targetWeightKg;
  final int targetWeeks;
  final String healthGoal; // 'Weight Loss', 'Muscle Gain', 'Maintain Weight', 'Healthy Lifestyle'
  final String foodPreference; // 'Vegetarian', 'Non-Vegetarian', 'Vegan', 'Pescatarian', 'Keto'
  final List<String> allergies;
  final String activityLevel; // 'Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active'

  const UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.targetWeightKg,
    this.targetWeeks = 12,
    required this.healthGoal,
    required this.foodPreference,
    required this.allergies,
    required this.activityLevel,
  });

  /// Default starting profile for new users
  factory UserProfile.defaultProfile() {
    return const UserProfile(
      name: 'Alex Johnson',
      age: 26,
      gender: 'Male',
      heightCm: 175.0,
      weightKg: 78.0,
      targetWeightKg: 72.0,
      targetWeeks: 10,
      healthGoal: 'Weight Loss',
      foodPreference: 'Vegetarian',
      allergies: ['Peanuts'],
      activityLevel: 'Moderately Active',
    );
  }

  // --- Computed Health Metrics ---

  /// Body Mass Index (BMI)
  double get bmi {
    if (heightCm <= 0) return 0.0;
    final heightInMeters = heightCm / 100.0;
    return weightKg / (heightInMeters * heightInMeters);
  }

  /// Human-readable BMI Category
  String get bmiCategory {
    final value = bmi;
    if (value < 18.5) return 'Underweight';
    if (value < 25.0) return 'Normal weight';
    if (value < 30.0) return 'Overweight';
    return 'Obese';
  }

  /// Basal Metabolic Rate (Mifflin-St Jeor Formula)
  double get bmr {
    if (gender.toLowerCase() == 'female') {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
    return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
  }

  /// Total Daily Energy Expenditure (TDEE) based on activity level
  double get tdee {
    double factor = 1.2; // Sedentary
    switch (activityLevel) {
      case 'Lightly Active':
        factor = 1.375;
        break;
      case 'Moderately Active':
        factor = 1.55;
        break;
      case 'Very Active':
        factor = 1.725;
        break;
      default:
        factor = 1.2;
    }
    return bmr * factor;
  }

  /// Recommended Daily Calorie Intake
  int get dailyCalorieTarget {
    final maintenance = tdee;
    switch (healthGoal) {
      case 'Weight Loss':
        return (maintenance - 450).round().clamp(1200, 4000);
      case 'Muscle Gain':
        return (maintenance + 350).round();
      case 'Maintain Weight':
      case 'Healthy Lifestyle':
      default:
        return maintenance.round();
    }
  }

  /// Recommended Daily Water Intake in Liters (approx 35 ml per kg)
  double get dailyWaterTargetLiters {
    return (weightKg * 0.035).clamp(1.5, 5.0);
  }

  /// Target Macronutrient Distribution in Grams
  Map<String, int> get dailyMacros {
    final calories = dailyCalorieTarget;
    double proteinPct;
    double carbsPct;
    double fatsPct;

    if (healthGoal == 'Muscle Gain') {
      proteinPct = 0.30;
      carbsPct = 0.45;
      fatsPct = 0.25;
    } else if (healthGoal == 'Weight Loss') {
      proteinPct = 0.35;
      carbsPct = 0.35;
      fatsPct = 0.30;
    } else {
      proteinPct = 0.25;
      carbsPct = 0.50;
      fatsPct = 0.25;
    }

    // 1g Protein = 4 kcal, 1g Carbs = 4 kcal, 1g Fat = 9 kcal
    final proteinGrams = (calories * proteinPct / 4).round();
    final carbsGrams = (calories * carbsPct / 4).round();
    final fatsGrams = (calories * fatsPct / 9).round();

    return {
      'protein': proteinGrams,
      'carbs': carbsGrams,
      'fats': fatsGrams,
    };
  }

  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    int? targetWeeks,
    String? healthGoal,
    String? foodPreference,
    List<String>? allergies,
    String? activityLevel,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      targetWeeks: targetWeeks ?? this.targetWeeks,
      healthGoal: healthGoal ?? this.healthGoal,
      foodPreference: foodPreference ?? this.foodPreference,
      allergies: allergies ?? this.allergies,
      activityLevel: activityLevel ?? this.activityLevel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'targetWeightKg': targetWeightKg,
      'targetWeeks': targetWeeks,
      'healthGoal': healthGoal,
      'foodPreference': foodPreference,
      'allergies': allergies,
      'activityLevel': activityLevel,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] as String? ?? 'User',
      age: (map['age'] as num?)?.toInt() ?? 25,
      gender: map['gender'] as String? ?? 'Other',
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 170.0,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 70.0,
      targetWeightKg: (map['targetWeightKg'] as num?)?.toDouble() ?? 65.0,
      targetWeeks: (map['targetWeeks'] as num?)?.toInt() ?? 12,
      healthGoal: map['healthGoal'] as String? ?? 'Maintain Weight',
      foodPreference: map['foodPreference'] as String? ?? 'Vegetarian',
      allergies: (map['allergies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      activityLevel: map['activityLevel'] as String? ?? 'Moderately Active',
    );
  }
}
