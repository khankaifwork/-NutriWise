import 'package:flutter/material.dart';
import '../models/meal_plan.dart';
import '../theme/app_theme.dart';
import 'macro_badge.dart';

class MealCard extends StatelessWidget {
  final String mealType; // 'Breakfast', 'Lunch', 'Snacks', 'Dinner'
  final MealItem meal;

  const MealCard({
    super.key,
    required this.mealType,
    required this.meal,
  });

  IconData _getMealIcon() {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_sunny_rounded;
      case 'lunch':
        return Icons.lunch_dining_rounded;
      case 'snacks':
        return Icons.cookie_rounded;
      case 'dinner':
        return Icons.nightlight_round;
      default:
        return Icons.restaurant_rounded;
    }
  }

  Color _getMealColor() {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return AppTheme.accentAmber;
      case 'lunch':
        return AppTheme.primaryGreen;
      case 'snacks':
        return AppTheme.accentTeal;
      case 'dinner':
        return const Color(0xFF8B5CF6); // Violet
      default:
        return AppTheme.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _getMealColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Meal Category + Calories Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getMealIcon(), color: color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      mealType,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          size: 16, color: AppTheme.primaryGreen),
                      const SizedBox(width: 4),
                      Text(
                        '${meal.calories} kcal',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Meal Title
            Text(
              meal.title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),

            // Description
            if (meal.description.isNotEmpty)
              Text(
                meal.description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            const SizedBox(height: 14),

            // Macro Pills
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                MacroBadge(
                  label: 'Protein',
                  amount: '${meal.proteinG}g',
                  color: const Color(0xFF3B82F6), // Blue
                ),
                MacroBadge(
                  label: 'Carbs',
                  amount: '${meal.carbsG}g',
                  color: const Color(0xFFF59E0B), // Amber
                ),
                MacroBadge(
                  label: 'Fats',
                  amount: '${meal.fatsG}g',
                  color: const Color(0xFFEC4899), // Pink
                ),
                if (meal.prepTimeMin > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${meal.prepTimeMin} min',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Ingredients Preview
            if (meal.ingredients.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingredients: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      meal.ingredients.join(', '),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
