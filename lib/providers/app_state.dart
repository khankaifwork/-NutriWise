import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/meal_plan.dart';
import '../models/recipe.dart';
import '../models/weight_entry.dart';
import '../models/chat_message.dart';
import '../services/storage_service.dart';
import '../services/groq_service.dart';
import '../data/sample_recipes.dart';

class AppState extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final GroqService _groqService = GroqService();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Profile State
  late UserProfile _profile;
  UserProfile get profile => _profile;

  // Meal Plan State
  MealPlan? _currentMealPlan;
  MealPlan? get currentMealPlan => _currentMealPlan;
  bool _isGeneratingMealPlan = false;
  bool get isGeneratingMealPlan => _isGeneratingMealPlan;

  // Recipe State
  List<Recipe> _recipes = [];
  List<Recipe> get recipes => _recipes;
  Set<String> _favoriteIds = {};
  Set<String> get favoriteIds => _favoriteIds;

  // AI Assistant Chat State
  List<ChatMessage> _chatMessages = [];
  List<ChatMessage> get chatMessages => _chatMessages;
  bool _isChatThinking = false;
  bool get isChatThinking => _isChatThinking;

  // Weight & Progress State
  List<WeightEntry> _weightHistory = [];
  List<WeightEntry> get weightHistory => _weightHistory;

  // Settings & Theme
  String? _groqApiKey;
  String? get groqApiKey => _groqApiKey;
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  /// Startup initialization: Loads all persisted data or initializes defaults
  Future<void> initialize() async {
    // 1. Load Profile
    final savedProfile = await _storageService.loadProfile();
    if (savedProfile != null) {
      _profile = savedProfile;
    } else {
      _profile = UserProfile.defaultProfile();
      await _storageService.saveProfile(_profile);
    }

    // 2. Load Settings
    _groqApiKey = await _storageService.loadGroqApiKey();
    _isDarkMode = await _storageService.loadDarkMode();

    // 3. Load Meal Plan
    _currentMealPlan = await _storageService.loadMealPlan();
    if (_currentMealPlan == null) {
      // Auto-generate initial plan for immediate richness
      _currentMealPlan = await _groqService.generateMealPlan(
        profile: _profile,
        apiKey: _groqApiKey,
        isWeekly: false,
      );
      await _storageService.saveMealPlan(_currentMealPlan!);
    }

    // 4. Load Recipes & Favorites
    _favoriteIds = await _storageService.loadFavoriteRecipeIds();
    _recipes = SampleRecipes.list.map((r) {
      return r.copyWith(isFavorite: _favoriteIds.contains(r.id));
    }).toList();

    // 5. Load Weight History
    _weightHistory = await _storageService.loadWeightHistory();
    if (_weightHistory.isEmpty) {
      final now = DateTime.now();
      _weightHistory = [
        WeightEntry(
          id: 'w_init_1',
          date: now.subtract(const Duration(days: 21)),
          weightKg: _profile.weightKg + 2.5,
          note: 'Starting journey',
        ),
        WeightEntry(
          id: 'w_init_2',
          date: now.subtract(const Duration(days: 14)),
          weightKg: _profile.weightKg + 1.6,
          note: 'End of week 1',
        ),
        WeightEntry(
          id: 'w_init_3',
          date: now.subtract(const Duration(days: 7)),
          weightKg: _profile.weightKg + 0.8,
          note: 'Healthy eating rhythm',
        ),
        WeightEntry(
          id: 'w_init_4',
          date: now,
          weightKg: _profile.weightKg,
          note: 'Current baseline',
        ),
      ];
      await _storageService.saveWeightHistory(_weightHistory);
    }

    // 6. Load Chat History
    _chatMessages = await _storageService.loadChatHistory();
    if (_chatMessages.isEmpty) {
      _chatMessages = [
        ChatMessage(
          id: 'chat_welcome',
          sender: 'ai',
          text:
              'Hello ${_profile.name}! 👋 I am NutriWise AI, your personal clinical nutritionist. I have reviewed your profile: you are focusing on **${_profile.healthGoal}** with a **${_profile.foodPreference}** diet. How can I assist you with your meals or nutrition today?',
          timestamp: DateTime.now(),
        ),
      ];
      await _storageService.saveChatHistory(_chatMessages);
    }

    _isInitialized = true;
    notifyListeners();
  }

  // --- Profile Actions ---

  Future<void> updateProfile(UserProfile newProfile) async {
    final oldWeight = _profile.weightKg;
    _profile = newProfile;
    await _storageService.saveProfile(_profile);

    // If weight changed in profile, record an entry
    if ((newProfile.weightKg - oldWeight).abs() > 0.05) {
      await addWeightEntry(newProfile.weightKg, note: 'Updated from Profile');
    }

    notifyListeners();
  }

  // --- Meal Plan Actions ---

  Future<void> generateMealPlan({bool isWeekly = false, String? notes}) async {
    _isGeneratingMealPlan = true;
    notifyListeners();

    try {
      final newPlan = await _groqService.generateMealPlan(
        profile: _profile,
        apiKey: _groqApiKey,
        isWeekly: isWeekly,
        customNotes: notes,
      );
      _currentMealPlan = newPlan;
      await _storageService.saveMealPlan(newPlan);
    } catch (e) {
      print('Failed generating meal plan: $e');
    } finally {
      _isGeneratingMealPlan = false;
      notifyListeners();
    }
  }

  // --- Recipe Actions ---

  Future<void> toggleFavoriteRecipe(String recipeId) async {
    if (_favoriteIds.contains(recipeId)) {
      _favoriteIds.remove(recipeId);
    } else {
      _favoriteIds.add(recipeId);
    }
    await _storageService.saveFavoriteRecipeIds(_favoriteIds);

    _recipes = _recipes.map((r) {
      if (r.id == recipeId) {
        return r.copyWith(isFavorite: _favoriteIds.contains(recipeId));
      }
      return r;
    }).toList();

    notifyListeners();
  }

  // --- AI Assistant Actions ---

  Future<void> sendChatMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'user',
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    _chatMessages.add(userMsg);
    _isChatThinking = true;
    notifyListeners();

    try {
      final reply = await _groqService.sendChatMessage(
        history: _chatMessages,
        newUserMessage: userMsg.text,
        profile: _profile,
        apiKey: _groqApiKey,
      );

      final aiMsg = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        sender: 'ai',
        text: reply,
        timestamp: DateTime.now(),
      );

      _chatMessages.add(aiMsg);
      await _storageService.saveChatHistory(_chatMessages);
    } catch (e) {
      _chatMessages.add(
        ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          sender: 'ai',
          text: 'Sorry, I ran into an error processing that question. Please check your internet connection or Groq API settings.',
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      _isChatThinking = false;
      notifyListeners();
    }
  }

  Future<void> clearChat() async {
    _chatMessages = [
      ChatMessage(
        id: 'chat_welcome_cleared',
        sender: 'ai',
        text: 'Chat history cleared. How can I help you next, ${_profile.name}?',
        timestamp: DateTime.now(),
      ),
    ];
    await _storageService.saveChatHistory(_chatMessages);
    notifyListeners();
  }

  // --- Weight & Progress Actions ---

  Future<void> addWeightEntry(double weightKg, {String? note, DateTime? date}) async {
    final entry = WeightEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: date ?? DateTime.now(),
      weightKg: weightKg,
      note: note,
    );

    _weightHistory.add(entry);
    // Sort chronologically
    _weightHistory.sort((a, b) => a.date.compareTo(b.date));

    // Update profile current weight
    _profile = _profile.copyWith(weightKg: weightKg);
    await _storageService.saveProfile(_profile);
    await _storageService.saveWeightHistory(_weightHistory);

    notifyListeners();
  }

  /// Starting weight (first entry recorded)
  double get startingWeight {
    if (_weightHistory.isEmpty) return _profile.weightKg;
    return _weightHistory.first.weightKg;
  }

  /// Target weight
  double get targetWeight => _profile.targetWeightKg;

  /// Goal completion percentage (0.0 to 1.0 or beyond)
  double get goalCompletionPercentage {
    final start = startingWeight;
    final current = _profile.weightKg;
    final target = _profile.targetWeightKg;

    final totalToChange = (start - target).abs();
    if (totalToChange < 0.1) return 1.0;

    final actualChange = (start - current).abs();
    final pct = actualChange / totalToChange;
    return pct.clamp(0.0, 1.0);
  }

  // --- Settings & Theme Actions ---

  Future<void> setGroqApiKey(String key) async {
    _groqApiKey = key.trim();
    await _storageService.saveGroqApiKey(_groqApiKey!);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _storageService.saveDarkMode(_isDarkMode);
    notifyListeners();
  }

  // --- Reset & Demo Actions ---

  /// Clears all user data, returning to fresh baseline defaults
  Future<void> resetAllData() async {
    await _storageService.clearAllData(keepApiKey: true);

    _profile = UserProfile.defaultProfile();
    await _storageService.saveProfile(_profile);

    _weightHistory = [
      WeightEntry(
        id: 'w_reset_${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        weightKg: _profile.weightKg,
        note: 'Starting baseline',
      ),
    ];
    await _storageService.saveWeightHistory(_weightHistory);

    _favoriteIds = {};
    await _storageService.saveFavoriteRecipeIds(_favoriteIds);
    _recipes = SampleRecipes.list.map((r) => r.copyWith(isFavorite: false)).toList();

    _chatMessages = [
      ChatMessage(
        id: 'chat_welcome_reset',
        sender: 'ai',
        text: 'Hello ${_profile.name}! 👋 All data has been reset. How can I help you start your nutrition journey?',
        timestamp: DateTime.now(),
      ),
    ];
    await _storageService.saveChatHistory(_chatMessages);

    // Regenerate fresh starter meal plan
    _currentMealPlan = await _groqService.generateMealPlan(
      profile: _profile,
      apiKey: _groqApiKey,
      isWeekly: false,
    );
    await _storageService.saveMealPlan(_currentMealPlan!);

    notifyListeners();
  }

  /// Loads realistic, rich demonstration data so users can explore charts, meal plans, and features
  Future<void> loadDemoData() async {
    final now = DateTime.now();

    // 1. Rich Demo Profile
    _profile = const UserProfile(
      name: 'Alex Morgan',
      age: 27,
      gender: 'Male',
      heightCm: 178.0,
      weightKg: 76.5,
      targetWeightKg: 70.0,
      targetWeeks: 10,
      healthGoal: 'Weight Loss',
      foodPreference: 'Non-Vegetarian',
      allergies: ['Peanuts'],
      activityLevel: 'Moderately Active',
    );
    await _storageService.saveProfile(_profile);

    // 2. Realistic 30-Day Weight History with progress
    _weightHistory = [
      WeightEntry(
        id: 'demo_w1',
        date: now.subtract(const Duration(days: 28)),
        weightKg: 80.5,
        note: 'Starting fitness journey 🚀',
      ),
      WeightEntry(
        id: 'demo_w2',
        date: now.subtract(const Duration(days: 21)),
        weightKg: 79.6,
        note: 'Week 1: Cut late-night snacks',
      ),
      WeightEntry(
        id: 'demo_w3',
        date: now.subtract(const Duration(days: 14)),
        weightKg: 78.4,
        note: 'Week 2: Consistent 500 kcal deficit',
      ),
      WeightEntry(
        id: 'demo_w4',
        date: now.subtract(const Duration(days: 7)),
        weightKg: 77.3,
        note: 'Week 3: Increased daily protein to 150g',
      ),
      WeightEntry(
        id: 'demo_w5',
        date: now.subtract(const Duration(days: 2)),
        weightKg: 76.8,
        note: 'Post-workout weigh-in',
      ),
      WeightEntry(
        id: 'demo_w6',
        date: now,
        weightKg: 76.5,
        note: 'Current baseline: -4.0 kg down!',
      ),
    ];
    await _storageService.saveWeightHistory(_weightHistory);

    // 3. Demo Favorites
    _favoriteIds = {'rec_1', 'rec_3'};
    await _storageService.saveFavoriteRecipeIds(_favoriteIds);
    _recipes = SampleRecipes.list.map((r) {
      return r.copyWith(isFavorite: _favoriteIds.contains(r.id));
    }).toList();

    // 4. Demo Chat Dialogue
    _chatMessages = [
      ChatMessage(
        id: 'demo_c1',
        sender: 'ai',
        text: 'Hello Alex! 👋 I am your NutriWise AI nutrition coach. I see your goal is **Weight Loss** with a target of **70 kg**.',
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
      ChatMessage(
        id: 'demo_c2',
        sender: 'user',
        text: 'What is an optimal post-workout snack with at least 25g of protein?',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      ChatMessage(
        id: 'demo_c3',
        sender: 'ai',
        text: 'Great question Alex! Here are two high-protein post-workout snacks tailored for you:\n\n'
            '• **Greek Yogurt Power Bowl (~28g Protein, 260 kcal)**: 200g Greek yogurt topped with blueberries and 1 scoop whey protein or pumpkin seeds.\n'
            '• **Seared Egg White & Turkey Wrap (~26g Protein, 240 kcal)**: 3 egg whites + 2 slices lean turkey breast wrapped in a light whole-wheat tortilla with baby spinach.\n\n'
            'Both keep you in your **2,050 kcal** daily target while accelerating muscle recovery!',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
    ];
    await _storageService.saveChatHistory(_chatMessages);

    // 5. Rich Multi-day Demo Meal Plan
    _currentMealPlan = MealPlan(
      id: 'demo_plan_1',
      title: 'High-Protein Fat Loss Plan (Alex)',
      healthGoal: 'Weight Loss',
      dietPreference: 'Non-Vegetarian',
      createdAt: now,
      days: [
        DailyMealPlan(
          dayName: 'Monday',
          breakfast: const MealItem(
            title: 'Avocado & Poached Egg Protein Toast',
            description: 'Whole grain sourdough topped with mashed avocado, 2 poached eggs, and crushed red pepper.',
            calories: 380,
            proteinG: 22,
            carbsG: 32,
            fatsG: 16,
            prepTimeMin: 12,
            ingredients: ['Sourdough bread', '2 free-range eggs', 'Half avocado', 'Chia seeds'],
          ),
          lunch: const MealItem(
            title: 'Grilled Herb Chicken & Quinoa Bowl',
            description: 'Tender chicken breast with fluffy tri-color quinoa, roasted cherry tomatoes, and cucumber slices.',
            calories: 580,
            proteinG: 48,
            carbsG: 54,
            fatsG: 14,
            prepTimeMin: 20,
            ingredients: ['Chicken breast (200g)', 'Quinoa (1 cup)', 'Cucumbers', 'Extra virgin olive oil'],
          ),
          snacks: const MealItem(
            title: 'Greek Yogurt with Blueberries & Walnuts',
            description: 'Creamy zero-fat Greek yogurt with fresh blueberries and raw walnut halves.',
            calories: 210,
            proteinG: 18,
            carbsG: 18,
            fatsG: 7,
            prepTimeMin: 5,
            ingredients: ['Greek yogurt (180g)', 'Blueberries (50g)', 'Walnuts (15g)'],
          ),
          dinner: const MealItem(
            title: 'Pan-Seared Salmon with Steamed Asparagus',
            description: 'Omega-3 rich salmon fillet with garlic asparagus spears and sweet potato mash.',
            calories: 520,
            proteinG: 44,
            carbsG: 36,
            fatsG: 18,
            prepTimeMin: 25,
            ingredients: ['Atlantic salmon (180g)', 'Asparagus bunch', 'Sweet potato', 'Lemon'],
          ),
        ),
        DailyMealPlan(
          dayName: 'Tuesday',
          breakfast: const MealItem(
            title: 'Berry Protein Oatmeal with Chia',
            description: 'Warm rolled oats cooked with protein powder, cinnamon, and fresh raspberries.',
            calories: 390,
            proteinG: 28,
            carbsG: 46,
            fatsG: 8,
            prepTimeMin: 10,
            ingredients: ['Rolled oats', 'Whey protein', 'Almond milk', 'Raspberries'],
          ),
          lunch: const MealItem(
            title: 'Seared Tuna Steak Mediterranean Salad',
            description: 'Yellowfin tuna served over mixed greens, kalamata olives, and olive oil vinaigrette.',
            calories: 540,
            proteinG: 46,
            carbsG: 24,
            fatsG: 18,
            prepTimeMin: 18,
            ingredients: ['Tuna steak (180g)', 'Mixed greens', 'Kalamata olives', 'Balsamic vinegar'],
          ),
          snacks: const MealItem(
            title: 'Crisp Apple & Cottage Cheese',
            description: 'Fresh sliced Honeycrisp apple paired with low-fat cottage cheese and cinnamon.',
            calories: 190,
            proteinG: 14,
            carbsG: 26,
            fatsG: 3,
            prepTimeMin: 3,
            ingredients: ['1 Honeycrisp apple', 'Cottage cheese (120g)', 'Ground cinnamon'],
          ),
          dinner: const MealItem(
            title: 'Lean Turkey & Zucchini Stir-Fry',
            description: 'Ground turkey breast cooked with crisp zucchini coins and brown jasmine rice.',
            calories: 510,
            proteinG: 42,
            carbsG: 45,
            fatsG: 12,
            prepTimeMin: 22,
            ingredients: ['Lean turkey breast', 'Zucchini', 'Brown jasmine rice', 'Tamari soy sauce'],
          ),
        ),
      ],
    );
    await _storageService.saveMealPlan(_currentMealPlan!);

    notifyListeners();
  }
}
