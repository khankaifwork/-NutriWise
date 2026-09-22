import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _targetWeightController;
  late TextEditingController _targetWeeksController;

  late String _selectedGender;
  late String _selectedGoal;
  late String _selectedDiet;
  late String _selectedActivity;
  late List<String> _selectedAllergies;

  final List<String> _goals = [
    'Weight Loss',
    'Muscle Gain',
    'Maintain Weight',
    'Healthy Lifestyle',
  ];

  final List<String> _diets = [
    'Vegetarian',
    'Non-Vegetarian',
    'Vegan',
    'Pescatarian',
    'Keto',
  ];

  final List<String> _activities = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
  ];

  final List<String> _availableAllergies = [
    'Peanuts',
    'Dairy',
    'Gluten',
    'Shellfish',
    'Soy',
    'Eggs',
    'Tree Nuts',
  ];

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile;

    _nameController = TextEditingController(text: profile.name);
    _ageController = TextEditingController(text: profile.age.toString());
    _heightController = TextEditingController(text: profile.heightCm.toStringAsFixed(0));
    _weightController = TextEditingController(text: profile.weightKg.toStringAsFixed(1));
    _targetWeightController =
        TextEditingController(text: profile.targetWeightKg.toStringAsFixed(1));
    _targetWeeksController =
        TextEditingController(text: profile.targetWeeks.toString());

    _selectedGender = profile.gender;
    _selectedGoal = profile.healthGoal;
    _selectedDiet = profile.foodPreference;
    _selectedActivity = profile.activityLevel;
    _selectedAllergies = List.from(profile.allergies);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _targetWeeksController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedProfile = UserProfile(
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 25,
      gender: _selectedGender,
      heightCm: double.tryParse(_heightController.text.trim()) ?? 170.0,
      weightKg: double.tryParse(_weightController.text.trim()) ?? 70.0,
      targetWeightKg: double.tryParse(_targetWeightController.text.trim()) ?? 65.0,
      targetWeeks: int.tryParse(_targetWeeksController.text.trim()) ?? 12,
      healthGoal: _selectedGoal,
      foodPreference: _selectedDiet,
      allergies: _selectedAllergies,
      activityLevel: _selectedActivity,
    );

    await context.read<AppState>().updateProfile(updatedProfile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully! All pages updated.'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile & Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, color: AppTheme.primaryGreen, size: 28),
            tooltip: 'Save',
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Section 1: Basic Information
            _buildSectionHeader('Basic Details'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      prefixIcon: Icon(Icons.cake_outlined),
                      suffixText: 'yrs',
                    ),
                    validator: (v) {
                      final val = int.tryParse(v ?? '');
                      if (val == null || val <= 5 || val > 120) return 'Valid age';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.wc_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedGender = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 2: Physical Metrics
            _buildSectionHeader('Body Measurements'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Height',
                      prefixIcon: Icon(Icons.height_rounded),
                      suffixText: 'cm',
                    ),
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val < 50 || val > 260) return 'Valid height';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Current Weight',
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                      suffixText: 'kg',
                    ),
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val < 20 || val > 300) return 'Valid weight';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _targetWeightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target Weight',
                      prefixIcon: Icon(Icons.flag_outlined),
                      suffixText: 'kg',
                    ),
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val < 20 || val > 300) return 'Valid target';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _targetWeeksController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Timeline',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      suffixText: 'weeks',
                    ),
                    validator: (v) {
                      final val = int.tryParse(v ?? '');
                      if (val == null || val < 1 || val > 104) return 'Valid weeks';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 3: Health Goal & Diet
            _buildSectionHeader('Health Goal & Diet Preference'),
            const SizedBox(height: 12),

            Text(
              'Health Goal',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _goals.map((goal) {
                final isSelected = _selectedGoal == goal;
                return ChoiceChip(
                  label: Text(goal),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryGreen,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedGoal = goal);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Text(
              'Dietary Preference',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _diets.map((diet) {
                final isSelected = _selectedDiet == diet;
                return ChoiceChip(
                  label: Text(diet),
                  selected: isSelected,
                  selectedColor: AppTheme.accentTeal,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedDiet = diet);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Text(
              'Activity Level',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedActivity,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.directions_run_rounded),
              ),
              items: _activities
                  .map((act) => DropdownMenuItem(value: act, child: Text(act)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedActivity = val);
              },
            ),
            const SizedBox(height: 24),

            // Section 4: Allergies & Food Dislikes
            _buildSectionHeader('Allergies & Food Dislikes'),
            const SizedBox(height: 8),
            Text(
              'Select any ingredients you are allergic to or want strictly excluded from meals:',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableAllergies.map((allergy) {
                final isSelected = _selectedAllergies.contains(allergy);
                return FilterChip(
                  label: Text(allergy),
                  selected: isSelected,
                  selectedColor: AppTheme.accentRose.withOpacity(0.2),
                  checkmarkColor: AppTheme.accentRose,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.accentRose : (isDark ? Colors.white : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAllergies.add(allergy);
                      } else {
                        _selectedAllergies.remove(allergy);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 36),

            // Save Button
            ElevatedButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Profile Information'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: isDark ? AppTheme.primaryLightGreen : AppTheme.primaryDarkGreen,
      ),
    );
  }
}
