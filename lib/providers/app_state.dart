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
}
