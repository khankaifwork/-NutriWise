import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_card.dart';
import '../widgets/weight_chart.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _selectedFilterDays = 30; // 7 (Weekly), 30 (Monthly), 90 (Quarterly)

  void _showAddWeightDialog() {
    final current = context.read<AppState>().profile.weightKg;
    final controller = TextEditingController(text: current.toStringAsFixed(1));
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Log Today\'s Weight',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Weight',
                  suffixText: 'kg',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'e.g. Morning fasted, post-workout',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final weight = double.tryParse(controller.text.trim());
                    if (weight != null && weight > 20 && weight < 300) {
                      Navigator.pop(ctx);
                      context.read<AppState>().addWeightEntry(
                            weight,
                            note: noteController.text.trim().isEmpty
                                ? null
                                : noteController.text.trim(),
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Weight logged successfully!'),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save Entry'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile;
    final allEntries = appState.weightHistory;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final startWeight = appState.startingWeight;
    final currentWeight = profile.weightKg;
    final targetWeight = profile.targetWeightKg;
    final completionPct = appState.goalCompletionPercentage;

    final weightDiff = currentWeight - startWeight;
    final toTargetDiff = (currentWeight - targetWeight).abs();

    // Filtered entries for the chart
    final cutoff = DateTime.now().subtract(Duration(days: _selectedFilterDays));
    final chartEntries = allEntries.where((e) => e.date.isAfter(cutoff)).toList();
    final displayEntries = chartEntries.isEmpty ? allEntries : chartEntries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight & Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.primaryGreen, size: 28),
            tooltip: 'Log Weight',
            onPressed: _showAddWeightDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Overview 3-Pillar Cards (Start, Current, Target)
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'Start',
                    value: '${startWeight.toStringAsFixed(1)} kg',
                    subtitle: 'Baseline',
                    icon: Icons.flag_outlined,
                    iconColor: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricCard(
                    title: 'Current',
                    value: '${currentWeight.toStringAsFixed(1)} kg',
                    subtitle: weightDiff == 0
                        ? 'Unchanged'
                        : '${weightDiff > 0 ? "+" : ""}${weightDiff.toStringAsFixed(1)} kg',
                    icon: Icons.monitor_weight_rounded,
                    iconColor: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricCard(
                    title: 'Target',
                    value: '${targetWeight.toStringAsFixed(1)} kg',
                    subtitle: '${toTargetDiff.toStringAsFixed(1)} kg to go',
                    icon: Icons.sports_score_rounded,
                    iconColor: AppTheme.accentTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Goal Completion % Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Goal Completion',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${(completionPct * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: completionPct,
                      minHeight: 12,
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dynamic Progress Summary Text
                  Text(
                    _getProgressSummary(profile.healthGoal, weightDiff, toTargetDiff),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Weight Chart Section with Weekly / Monthly Toggles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weight Trend',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Row(
                  children: [
                    _buildFilterPill('7D', 7),
                    const SizedBox(width: 6),
                    _buildFilterPill('30D', 30),
                    const SizedBox(width: 6),
                    _buildFilterPill('All', 365),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: WeightChart(
                entries: displayEntries,
                targetWeight: targetWeight,
              ),
            ),
            const SizedBox(height: 24),

            // 4. Weight History Log
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weight History Log',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                TextButton.icon(
                  onPressed: _showAddWeightDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Entry'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (allEntries.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No weight logs yet. Tap + to add one!',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allEntries.reversed.length,
                itemBuilder: (context, index) {
                  final entry = allEntries.reversed.toList()[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.calendar_today_rounded,
                                  size: 16, color: AppTheme.primaryGreen),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEEE, MMM d, y').format(entry.date),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (entry.note != null && entry.note!.isNotEmpty)
                                  Text(
                                    entry.note!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '${entry.weightKg.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, int days) {
    final isSelected = _selectedFilterDays == days;
    return InkWell(
      onTap: () => setState(() => _selectedFilterDays = days),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  String _getProgressSummary(String goal, double weightDiff, double toTargetDiff) {
    if (toTargetDiff < 0.2) {
      return '🎉 Outstanding achievement! You have reached your target weight. Maintain your healthy habits!';
    }
    if (goal == 'Weight Loss') {
      if (weightDiff < 0) {
        return '🔥 Great progress! You have dropped ${(-weightDiff).toStringAsFixed(1)} kg since starting. Keep up the consistent nutrition to reach your target!';
      }
      return 'Stay consistent with your daily calorie deficit target to see continuous progress toward your goal.';
    }
    return 'Track your weight every 3 to 7 days in the morning for the most reliable long-term insights.';
  }
}
