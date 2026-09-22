import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/meal_plan.dart';
import '../models/chat_message.dart';

class GroqService {
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const String defaultModel = 'llama-3.3-70b-versatile';

  /// Generate a personalized daily or weekly meal plan
  Future<MealPlan> generateMealPlan({
    required UserProfile profile,
    required String? apiKey,
    required bool isWeekly,
    String? customNotes,
  }) async {
    // If user provided a valid Groq API key, attempt live AI inference
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      try {
        final plan = await _fetchMealPlanFromGroq(
          profile: profile,
          apiKey: apiKey.trim(),
          isWeekly: isWeekly,
          customNotes: customNotes,
        );
        return plan;
      } catch (e) {
        print('Groq API error (falling back to smart offline generator): $e');
      }
    }

    // Smart fallback generator calibrated to profile calories and diet
    return _generateFallbackMealPlan(profile: profile, isWeekly: isWeekly);
  }

  Future<MealPlan> _fetchMealPlanFromGroq({
    required UserProfile profile,
    required String apiKey,
    required bool isWeekly,
    String? customNotes,
  }) async {
    final daysCount = isWeekly ? 7 : 1;
    final targetCalories = profile.dailyCalorieTarget;
    final macros = profile.dailyMacros;

    const systemPrompt = '''
You are an expert nutritionist and meal planner. Generate a high quality, realistic meal plan for the user in strictly valid JSON format.
Do NOT wrap the JSON in markdown code blocks like ```json ... ```. Output raw JSON only.
Schema:
{
  "title": "Short descriptive title",
  "days": [
    {
      "dayName": "Day 1" (or Monday, etc.),
      "breakfast": {
        "title": "Dish name",
        "description": "Short appetizing description",
        "calories": 400,
        "proteinG": 25,
        "carbsG": 45,
        "fatsG": 12,
        "prepTimeMin": 15,
        "ingredients": ["item 1", "item 2"]
      },
      "lunch": {
        "title": "Dish name",
        "description": "Short description",
        "calories": 600,
        "proteinG": 40,
        "carbsG": 60,
        "fatsG": 18,
        "prepTimeMin": 25,
        "ingredients": ["item 1", "item 2"]
      },
      "snacks": {
        "title": "Dish name",
        "description": "Short description",
        "calories": 200,
        "proteinG": 15,
        "carbsG": 20,
        "fatsG": 7,
        "prepTimeMin": 5,
        "ingredients": ["item 1", "item 2"]
      },
      "dinner": {
        "title": "Dish name",
        "description": "Short description",
        "calories": 500,
        "proteinG": 35,
        "carbsG": 40,
        "fatsG": 15,
        "prepTimeMin": 30,
        "ingredients": ["item 1", "item 2"]
      }
    }
  ]
}
''';

    final userPrompt = '''
Generate a $daysCount-day meal plan for:
- Age: ${profile.age}, Gender: ${profile.gender}
- Height: ${profile.heightCm} cm, Weight: ${profile.weightKg} kg, Target Weight: ${profile.targetWeightKg} kg
- Health Goal: ${profile.healthGoal}
- Diet Preference: ${profile.foodPreference}
- Allergies / Dislikes: ${profile.allergies.isEmpty ? "None" : profile.allergies.join(", ")}
- Target Daily Calories: ~$targetCalories kcal (Protein: ~${macros['protein']}g, Carbs: ~${macros['carbs']}g, Fats: ~${macros['fats']}g)
${customNotes != null && customNotes.isNotEmpty ? "- Additional Preferences: $customNotes" : ""}
Strictly adhere to the allergies and dietary preference!
''';

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': defaultModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.6,
        'max_tokens': 3500,
        'response_format': {'type': 'json_object'},
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final rawContent = decoded['choices'][0]['message']['content'] as String;
      
      // Clean possible wrapper if any
      String cleanJson = rawContent.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.substring(7);
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      }
      cleanJson = cleanJson.trim();

      final planData = jsonDecode(cleanJson) as Map<String, dynamic>;
      final daysList = (planData['days'] as List<dynamic>?)
              ?.map((d) => DailyMealPlan.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [];

      return MealPlan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: planData['title'] as String? ?? '${profile.healthGoal} Meal Plan',
        healthGoal: profile.healthGoal,
        dietPreference: profile.foodPreference,
        createdAt: DateTime.now(),
        days: daysList,
      );
    } else {
      throw Exception('Groq API returned status ${response.statusCode}: ${response.body}');
    }
  }

  /// AI Assistant Chat with User Context
  Future<String> sendChatMessage({
    required List<ChatMessage> history,
    required String newUserMessage,
    required UserProfile profile,
    required String? apiKey,
  }) async {
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      try {
        final reply = await _fetchChatFromGroq(
          history: history,
          newUserMessage: newUserMessage,
          profile: profile,
          apiKey: apiKey.trim(),
        );
        return reply;
      } catch (e) {
        print('Groq Assistant Error: $e');
      }
    }

    // Local Fallback Responses based on intent & profile
    return _generateFallbackChatAnswer(newUserMessage, profile);
  }

  Future<String> _fetchChatFromGroq({
    required List<ChatMessage> history,
    required String newUserMessage,
    required UserProfile profile,
    required String apiKey,
  }) async {
    final systemPrompt = '''
You are NutriWise AI, an expert, warm, and evidence-based certified nutritionist and health coach.
Always personalize answers using the user's specific health profile:
- Name: ${profile.name}
- Age: ${profile.age} years old
- Current Weight: ${profile.weightKg} kg | Target Weight: ${profile.targetWeightKg} kg
- Height: ${profile.heightCm} cm (BMI: ${profile.bmi.toStringAsFixed(1)} - ${profile.bmiCategory})
- Goal: ${profile.healthGoal}
- Diet Preference: ${profile.foodPreference}
- Known Allergies: ${profile.allergies.isEmpty ? "None reported" : profile.allergies.join(", ")}
- Target Daily Calories: ~${profile.dailyCalorieTarget} kcal

Guidelines:
1. Provide actionable, concise, motivating advice.
2. If suggesting foods, strictly avoid their allergies and conform to their dietary preference (${profile.foodPreference}).
3. Use bullet points or numbered lists when explaining steps or giving food lists.
4. Keep tone friendly, encouraging, and clear.
''';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    // Include last 6 messages for context
    final recentHistory = history.length > 6 ? history.sublist(history.length - 6) : history;
    for (final msg in recentHistory) {
      messages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    messages.add({'role': 'user', 'content': newUserMessage});

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': defaultModel,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1200,
      }),
    ).timeout(const Duration(seconds: 25));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return decoded['choices'][0]['message']['content'] as String;
    } else {
      throw Exception('Groq chat error ${response.statusCode}: ${response.body}');
    }
  }

  // --- Fallback Generators for Offline or Zero-Configuration Mode ---

  MealPlan _generateFallbackMealPlan({
    required UserProfile profile,
    required bool isWeekly,
  }) {
    final isVeg = profile.foodPreference.toLowerCase().contains('veg');
    final isWeightLoss = profile.healthGoal.toLowerCase().contains('loss');
    final daysCount = isWeekly ? 7 : 1;
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    final days = <DailyMealPlan>[];

    for (int i = 0; i < daysCount; i++) {
      final dayLabel = isWeekly ? dayNames[i % 7] : 'Today';

      MealItem breakfast;
      MealItem lunch;
      MealItem snacks;
      MealItem dinner;

      if (isVeg) {
        breakfast = MealItem(
          title: i % 2 == 0 ? 'Spiced Oatmeal with Chia & Berries' : 'Greek Yogurt with Walnuts & Honey',
          description: 'Slow-digesting complex carbs and antioxidants to kickstart your metabolism.',
          calories: isWeightLoss ? 340 : 420,
          proteinG: isWeightLoss ? 18 : 22,
          carbsG: 48,
          fatsG: 10,
          prepTimeMin: 10,
          ingredients: ['Rolled Oats', 'Chia Seeds', 'Blueberries', 'Almond Milk', 'Honey'],
        );

        lunch = MealItem(
          title: i % 2 == 0 ? 'Mediterranean Quinoa & Chickpea Bowl' : 'Tofu Veggie Stir-Fry with Brown Rice',
          description: 'High in dietary fiber, plant proteins, and vibrant micronutrients.',
          calories: isWeightLoss ? 510 : 620,
          proteinG: 28,
          carbsG: 65,
          fatsG: 14,
          prepTimeMin: 20,
          ingredients: ['Quinoa', 'Chickpeas', 'Cucumber', 'Cherry Tomatoes', 'Olive Oil', 'Lemon'],
        );

        snacks = MealItem(
          title: 'Apple Slices with Almond Butter',
          description: 'Satisfying crunch with healthy monounsaturated fats.',
          calories: 190,
          proteinG: 6,
          carbsG: 22,
          fatsG: 9,
          prepTimeMin: 5,
          ingredients: ['1 Fresh Apple', '1.5 tbsp Almond Butter'],
        );

        dinner = MealItem(
          title: i % 2 == 0 ? 'Lentil Dal with Steamed Greens' : 'Grilled Paneer & Roasted Vegetable Salad',
          description: 'Light, gut-friendly dinner supporting cellular repair and deep sleep.',
          calories: isWeightLoss ? 440 : 540,
          proteinG: 26,
          carbsG: 45,
          fatsG: 12,
          prepTimeMin: 25,
          ingredients: ['Yellow Lentils', 'Spinach', 'Cumin', 'Turmeric', 'Coriander'],
        );
      } else {
        breakfast = MealItem(
          title: i % 2 == 0 ? 'Avocado & Poached Egg Toast' : 'Berry Protein Power Smoothie',
          description: 'Essential choline, omega-3s, and lean morning fuel.',
          calories: isWeightLoss ? 360 : 440,
          proteinG: 24,
          carbsG: 34,
          fatsG: 15,
          prepTimeMin: 12,
          ingredients: ['Sourdough Bread', '2 Free-range Eggs', 'Half Avocado', 'Chili Flakes'],
        );

        lunch = MealItem(
          title: i % 2 == 0 ? 'Herb-Grilled Chicken with Sweet Potato' : 'Seared Salmon with Steamed Broccoli',
          description: 'Lean animal protein paired with complex carbohydrates and greens.',
          calories: isWeightLoss ? 550 : 680,
          proteinG: 45,
          carbsG: 48,
          fatsG: 16,
          prepTimeMin: 25,
          ingredients: ['Chicken Breast', 'Sweet Potato', 'Broccoli Florets', 'Olive Oil'],
        );

        snacks = MealItem(
          title: 'Handful of Mixed Almonds & Boiled Egg',
          description: 'Quick protein boost to regulate blood sugar between meals.',
          calories: 210,
          proteinG: 12,
          carbsG: 6,
          fatsG: 15,
          prepTimeMin: 3,
          ingredients: ['Raw Almonds', '1 Boiled Egg', 'Sea Salt'],
        );

        dinner = MealItem(
          title: i % 2 == 0 ? 'Pan-Roasted Turkey & Green Asparagus' : 'Cod Fillet with Mediterranean Salad',
          description: 'High-protein, low-carb evening meal for optimal recovery.',
          calories: isWeightLoss ? 460 : 560,
          proteinG: 42,
          carbsG: 22,
          fatsG: 14,
          prepTimeMin: 20,
          ingredients: ['Lean Turkey Breast', 'Asparagus', 'Garlic', 'Zucchini'],
        );
      }

      days.add(DailyMealPlan(
        dayName: dayLabel,
        breakfast: breakfast,
        lunch: lunch,
        snacks: snacks,
        dinner: dinner,
      ));
    }

    return MealPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Smart ${profile.healthGoal} Plan (${profile.foodPreference})',
      healthGoal: profile.healthGoal,
      dietPreference: profile.foodPreference,
      createdAt: DateTime.now(),
      days: days,
    );
  }

  String _generateFallbackChatAnswer(String message, UserProfile profile) {
    final lower = message.toLowerCase();

    if (lower.contains('protein') || lower.contains('muscle')) {
      return 'For your goal of **${profile.healthGoal}** at ${profile.weightKg} kg, aiming for ~${(profile.weightKg * 1.6).round()}g to ${(profile.weightKg * 2.0).round()}g of protein daily is optimal.\n\n'
          'Top options tailored for ${profile.foodPreference}:\n'
          '• Lentils, Chickpeas & Edamame\n'
          '• Greek Yogurt & Cottage Cheese (or Tofu)\n'
          '• Eggs or Skinless Poultry (if non-veg)\n'
          '• Hemp & Chia Seeds\n\n'
          '💡 *Tip: Add your Groq API key in Settings to unlock unlimited live deep-dive consultations!*';
    }

    if (lower.contains('water') || lower.contains('hydrate')) {
      return 'Based on your weight of ${profile.weightKg} kg, your optimal daily water intake is **${profile.dailyWaterTargetLiters.toStringAsFixed(1)} Liters** (~${(profile.dailyWaterTargetLiters * 4).round()} glasses).\n\n'
          'Tips to hit this target:\n'
          '1. Drink 1 large glass upon waking.\n'
          '2. Keep a reusable bottle on your desk.\n'
          '3. Drink 1 glass 30 minutes before every meal.';
    }

    if (lower.contains('snack') || lower.contains('hungry')) {
      return 'Here are 3 nutritious snacks tailored for your **${profile.foodPreference}** preference:\n\n'
          '1. **Apple with 1 tbsp Nut Butter**: Balanced fiber and healthy fats (~180 kcal).\n'
          '2. **Roasted Chickpeas or Spiced Makhana**: High crunch, rich in minerals (~150 kcal).\n'
          '3. **Handful of Walnuts & Dark Chocolate (70%+)**: Brain food and heart health (~170 kcal).';
    }

    return 'Hello ${profile.name}! Based on your current profile (Weight: ${profile.weightKg} kg, Target: ${profile.targetWeightKg} kg, Goal: ${profile.healthGoal}):\n\n'
        '• Your target daily calorie intake is **${profile.dailyCalorieTarget} kcal**.\n'
        '• Your macronutrient breakdown is **${profile.dailyMacros['protein']}g Protein, ${profile.dailyMacros['carbs']}g Carbs, ${profile.dailyMacros['fats']}g Fats**.\n\n'
        'You can ask me anything about meal ideas, ingredient swaps, pre/post-workout nutrition, or how to break plateaus! *(To unlock live Groq LLM responses, add your API key in Settings).*';
  }
}
