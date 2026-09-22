# NutriWise - Intelligent Nutrition, Meal Planning & Health Tracking 🥗📱

**NutriWise** is a full-featured Flutter application designed to simplify personal nutrition and weight goals. Users configure their profile **once**, and all subsequent features—custom Groq-powered AI meal plans, recipe suggestions, clinical AI nutritionist chat, and weight trajectory tracking—automatically synchronize with their personalized data.

---

## 🌟 Key Features

### 🏠 1. Home + Profile
- **Unified Profile System**: User's name, age, gender, height, current weight, target weight, activity level, dietary preference, and allergies.
- **Dynamic BMR & TDEE Calculations**: Accurately computes Basal Metabolic Rate and Total Daily Energy Expenditure via the Mifflin-St Jeor formula.
- **Daily Health Summary**:
  - Target Caloric Needs tailored for weight loss, muscle gain, or maintenance.
  - Recommended Macronutrient Target Split (Carbs, Protein, Fats).
  - Target daily hydration recommendation (Liters / glasses).
- **Edit Profile**: Seamless form with live state propagation across every screen and persistent local database storage.

### 🍽️ 2. AI Meal Plan (Powered by Groq)
- **Goal-Calibrated Plans**: Automatically generates plans honoring diet preferences (Vegetarian, Non-Veg, Vegan, Keto, etc.) and strictly excluding any declared allergies.
- **Daily & 7-Day Weekly Views**: Intuitive horizontal tab switching between days.
- **Structured 4-Meal Breakdown**:
  - 🌅 **Breakfast**
  - 🥗 **Lunch**
  - 🥜 **Snacks**
  - 🍲 **Dinner**
- **Complete Nutritional Breakdown**: Calories, protein (g), carbs (g), fats (g), prep time, and ingredient list per meal.
- **Groq API Integration**: Employs ultra-fast `llama-3.3-70b-versatile` inference, backed by an intelligent offline nutritionist generator if no API key is provided.

### 🥗 3. Recipe Catalog & Search
- **Curated Database**: Filter by categories (*High Protein*, *Quick & Easy*, *Low Carb*, *Vegetarian*).
- **Ingredient & Food Search**: Instantly find meals by ingredient (e.g. "salmon", "oats", "chickpeas", "spinach").
- **Detailed Recipe Pages**:
  - Preparation and cooking times.
  - Complete ingredient measurements.
  - Step-by-step numbered cooking instructions.
  - Calories & macro pills (Protein, Carbs, Fats).
  - Direct **YouTube Video Tutorial** integration via `url_launcher`.
- **Favorites System**: Save favorite recipes with instant local persistence.

### 💬 4. AI Nutrition Assistant
- **Context-Aware Dialogue**: Automatically injects the user's active profile (Weight, Goal, Allergies, Diet) into the AI system prompt.
- **Interactive Chat Interface**:
  - Real-time responses with typing/thinking indicators.
  - Copy answer to clipboard button.
  - Pre-built quick suggestion chips (*"Suggest high-protein snacks"*, *"Healthy dinner under 500 kcal"*, *"Pre-workout meal idea"*).
  - Clear chat history support.

### 📊 5. Progress & Weight Tracking
- **3-Pillar Metric Cards**: Starting weight, Current weight, and Target weight with remaining delta.
- **Goal Completion Gauge**: Interactive percentage progress bar visually showing how close you are to your goal.
- **Custom Smooth Trend Chart**: Beautiful Bezier curve chart rendering weight trends over 7-Day, 30-Day, or All-time ranges with a target reference line.
- **Weight History Log**: Chronological record of weigh-ins with date and custom notes.
- **Log Today's Weight**: Modal dialog to quickly log daily or weekly weigh-ins, which instantly recalculates BMI, calorie targets, and progress metrics.

---

## 🏗️ Architecture & State Management

```
lib/
├── main.dart                      # App entry point & ThemeMode configuration
├── theme/
│   └── app_theme.dart             # Material 3 light/dark color palette & styles
├── models/
│   ├── user_profile.dart          # Unified profile with BMR/TDEE & macro formulas
│   ├── meal_plan.dart             # Daily & weekly meal models with macros
│   ├── recipe.dart                # Recipe model with YouTube link & ingredients
│   ├── weight_entry.dart          # Weight tracking entry
│   └── chat_message.dart          # AI chat message model
├── services/
│   ├── storage_service.dart       # Cross-platform JSON persistence (SharedPreferences)
│   └── groq_service.dart          # Groq API client with offline fallback
├── providers/
│   └── app_state.dart             # Unified ChangeNotifier state management
├── data/
│   └── sample_recipes.dart        # Built-in recipe database
├── widgets/
│   ├── metric_card.dart           # Dashboard metric display
│   ├── macro_badge.dart           # Colored macro pills
│   ├── meal_card.dart             # Structured meal card (Breakfast, Lunch, etc.)
│   ├── recipe_card.dart           # Recipe thumbnail & details card
│   ├── weight_chart.dart          # Custom canvas Bezier trend chart
│   └── chat_bubble.dart           # Chat message UI with copy & timestamp
└── screens/
    ├── main_navigation_screen.dart# Curved bottom navigation tabs
    ├── home_screen.dart           # Home & Health overview
    ├── profile_edit_screen.dart   # Profile form & allergy selector
    ├── meal_plan_screen.dart      # Daily/weekly AI meal plan viewer
    ├── recipe_list_screen.dart    # Recipe search and filters
    ├── recipe_detail_screen.dart  # Recipe instructions & YouTube launcher
    ├── ai_assistant_screen.dart   # Contextual nutrition chatbot
    ├── progress_screen.dart       # Weight tracker & goal charts
    └── settings_screen.dart       # Groq API key configuration & dark mode
```

---

## ⚡ How to Run the App

### 1. Install Flutter (If not already installed)
If Flutter is not yet in your Windows PATH, install it using `winget` in PowerShell:
```powershell
winget install -e --id Google.Flutter
```
Or download the official Flutter SDK zip from [flutter.dev](https://docs.flutter.dev/get-started/install/windows/mobile) and extract it to `C:\src\flutter`, then add `C:\src\flutter\bin` to your environment PATH.

### 2. Install Dependencies
In this project folder, run:
```bash
flutter pub get
```

### 3. Run the App
To run on your desired target:
- **Chrome / Web**:
  ```bash
  flutter run -d chrome
  ```
- **Windows Desktop**:
  ```bash
  flutter run -d windows
  ```
- **Android / iOS Device / Emulator**:
  ```bash
  flutter run
  ```

---

## 🔑 Groq API Setup (Optional)
NutriWise includes an intelligent offline generator that works without any setup. To enable live AI meal plan generation and interactive consultations with Groq LLM:
1. Open the app and navigate to **Home -> Tune (Settings Icon)** or go to Settings.
2. Enter your Groq API key (starts with `gsk_...`).
3. You can generate a free Groq API key at [console.groq.com/keys](https://console.groq.com/keys).
4. Tap **Save Key**. The app will immediately use the live Groq API!
