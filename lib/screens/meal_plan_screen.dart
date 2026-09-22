import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/meal_card.dart';
import '../widgets/macro_badge.dart';
import 'profile_edit_screen.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  int _selectedDayIndex = 0;

  void _showGenerateDialog() {
    final appState = context.read<AppState>();
    final profile = appState.profile;

    bool isWeekly = false;
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Generate AI Meal Plan',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'NutriWise Groq AI creates an optimized plan based on your saved profile:',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick profile recap card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Goal: ${profile.healthGoal}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            Text(
                              'Diet: ${profile.foodPreference} • ~${profile.dailyCalorieTarget} kcal',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                            );
                          },
                          child: const Text('Change', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Duration selection
                  Text(
                    'Plan Duration',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Today Only (1-Day)')),
                          selected: !isWeekly,
                          selectedColor: AppTheme.primaryGreen,
                          labelStyle: TextStyle(
                            color: !isWeekly ? Colors.white : (isDark ? Colors.white : Colors.black87),
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => isWeekly = false);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Full Week (7-Day)')),
                          selected: isWeekly,
                          selectedColor: AppTheme.primaryGreen,
                          labelStyle: TextStyle(
                            color: isWeekly ? Colors.white : (isDark ? Colors.white : Colors.black87),
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => isWeekly = true);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Custom preferences or notes
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Special Requests (Optional)',
                      hintText: 'e.g. include high protein smoothies, quick meals',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Generate CTA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _selectedDayIndex = 0);
                        context.read<AppState>().generateMealPlan(
                              isWeekly: isWeekly,
                              notes: notesController.text.trim(),
                            );
                      },
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Generate with Groq AI'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final plan = appState.currentMealPlan;
    final isGenerating = appState.isGeneratingMealPlan;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Meal Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryGreen),
            tooltip: 'Generate New Plan',
            onPressed: isGenerating ? null : _showGenerateDialog,
          ),
        ],
      ),
      body: isGenerating
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primaryGreen),
                  const SizedBox(height: 20),
                  const Text(
                    'Generating Your Personalized Meal Plan...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Calibrating calories & macros with Groq AI',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          : plan == null || plan.days.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.restaurant_rounded,
                            size: 64, color: AppTheme.primaryGreen),
                        const SizedBox(height: 16),
                        const Text(
                          'No Active Meal Plan',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Generate a personalized daily or weekly nutrition plan using Groq AI.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showGenerateDialog,
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: const Text('Generate Meal Plan'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Top Day Selector (if multiple days)
                    if (plan.days.length > 1)
                      Container(
                        height: 52,
                        margin: const EdgeInsets.only(top: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: plan.days.length,
                          itemBuilder: (context, index) {
                            final isSelected = _selectedDayIndex == index;
                            final day = plan.days[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(day.dayName),
                                selected: isSelected,
                                selectedColor: AppTheme.primaryGreen,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white : Colors.black87),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                                onSelected: (val) {
                                  if (val) setState(() => _selectedDayIndex = index);
                                },
                              ),
                            );
                          },
                        ),
                      ),

                    // Daily Nutrition Summary Bar
                    Builder(builder: (context) {
                      final currentDayIndex =
                          _selectedDayIndex.clamp(0, plan.days.length - 1);
                      final currentDay = plan.days[currentDayIndex];

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentDay.dayName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${currentDay.totalCalories} kcal',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 5,
                              children: [
                                MacroBadge(
                                  label: 'P',
                                  amount: '${currentDay.totalProtein}g',
                                  color: const Color(0xFF3B82F6),
                                ),
                                MacroBadge(
                                  label: 'C',
                                  amount: '${currentDay.totalCarbs}g',
                                  color: const Color(0xFFF59E0B),
                                ),
                                MacroBadge(
                                  label: 'F',
                                  amount: '${currentDay.totalFats}g',
                                  color: const Color(0xFFEC4899),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    // Meals List (Breakfast, Lunch, Snacks, Dinner)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final currentDayIndex =
                              _selectedDayIndex.clamp(0, plan.days.length - 1);
                          final currentDay = plan.days[currentDayIndex];

                          return ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            children: [
                              MealCard(
                                mealType: 'Breakfast',
                                meal: currentDay.breakfast,
                              ),
                              MealCard(
                                mealType: 'Lunch',
                                meal: currentDay.lunch,
                              ),
                              MealCard(
                                mealType: 'Snacks',
                                meal: currentDay.snacks,
                              ),
                              MealCard(
                                mealType: 'Dinner',
                                meal: currentDay.dinner,
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
