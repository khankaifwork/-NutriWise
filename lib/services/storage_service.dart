import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/meal_plan.dart';
import '../models/weight_entry.dart';
import '../models/chat_message.dart';

class StorageService {
  static const String _keyProfile = 'nutriwise_profile';
  static const String _keyMealPlan = 'nutriwise_meal_plan';
  static const String _keyFavorites = 'nutriwise_favorite_recipes';
  static const String _keyWeightHistory = 'nutriwise_weight_history';
  static const String _keyChatHistory = 'nutriwise_chat_history';
  static const String _keyGroqApiKey = 'nutriwise_groq_api_key';
  static const String _keyDarkMode = 'nutriwise_dark_mode';

  // --- Profile ---
  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, jsonEncode(profile.toMap()));
  }

  Future<UserProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyProfile);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserProfile.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  // --- Meal Plan ---
  Future<void> saveMealPlan(MealPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMealPlan, jsonEncode(plan.toMap()));
  }

  Future<MealPlan?> loadMealPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyMealPlan);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return MealPlan.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  // --- Favorite Recipe IDs ---
  Future<void> saveFavoriteRecipeIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFavorites, ids.toList());
  }

  Future<Set<String>> loadFavoriteRecipeIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyFavorites);
    return list?.toSet() ?? {};
  }

  // --- Weight History ---
  Future<void> saveWeightHistory(List<WeightEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final listMap = entries.map((e) => e.toMap()).toList();
    await prefs.setString(_keyWeightHistory, jsonEncode(listMap));
  }

  Future<List<WeightEntry>> loadWeightHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyWeightHistory);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => WeightEntry.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // --- Chat History ---
  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    // Keep at most last 50 messages
    final subset = messages.length > 50 ? messages.sublist(messages.length - 50) : messages;
    final listMap = subset.map((m) => m.toMap()).toList();
    await prefs.setString(_keyChatHistory, jsonEncode(listMap));
  }

  Future<List<ChatMessage>> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyChatHistory);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((m) => ChatMessage.fromMap(m as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // --- Groq API Key ---
  Future<void> saveGroqApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGroqApiKey, key.trim());
  }

  Future<String?> loadGroqApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGroqApiKey);
  }

  // --- Theme Mode ---
  Future<void> saveDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, isDark);
  }

  Future<bool> loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  // --- Reset & Clear ---
  Future<void> clearAllData({bool keepApiKey = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_keyGroqApiKey);
    final savedDark = prefs.getBool(_keyDarkMode);

    await prefs.remove(_keyProfile);
    await prefs.remove(_keyMealPlan);
    await prefs.remove(_keyFavorites);
    await prefs.remove(_keyWeightHistory);
    await prefs.remove(_keyChatHistory);

    if (!keepApiKey) {
      await prefs.remove(_keyGroqApiKey);
    } else if (savedKey != null) {
      await prefs.setString(_keyGroqApiKey, savedKey);
    }
    if (savedDark != null) {
      await prefs.setBool(_keyDarkMode, savedDark);
    }
  }
}
