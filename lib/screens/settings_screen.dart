import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _keyController;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final currentKey = context.read<AppState>().groqApiKey ?? '';
    _keyController = TextEditingController(text: currentKey);
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _saveKey() async {
    final key = _keyController.text.trim();
    await context.read<AppState>().setGroqApiKey(key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(key.isEmpty
              ? 'Groq API Key removed. Using smart offline AI mode.'
              : 'Groq API Key saved successfully!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  void _openGroqConsole() async {
    final uri = Uri.parse('https://console.groq.com/keys');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Configuration'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Section 1: Groq AI Setup
          _buildSectionHeader('Groq AI Engine'),
          const SizedBox(height: 8),
          Text(
            'NutriWise uses ultra-fast Groq Llama 3 models for real-time meal planning and nutritionist chat consultations.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _keyController,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              labelText: 'Groq API Key (gsk_...)',
              hintText: 'Enter your Groq API key',
              prefixIcon: const Icon(Icons.key_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openGroqConsole,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Get Free Key (Groq)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveKey,
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: const Text('Save Key'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.primaryGreen, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No key? NutriWise will automatically run in Smart Offline Mode with balanced nutritionist-calibrated plans.',
                    style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Section 2: Appearance
          _buildSectionHeader('Appearance'),
          const SizedBox(height: 10),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              appState.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: AppTheme.accentAmber,
            ),
            title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              appState.isDarkMode ? 'Dark theme active' : 'Light theme active',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            trailing: Switch(
              value: appState.isDarkMode,
              activeColor: AppTheme.primaryGreen,
              onChanged: (_) => context.read<AppState>().toggleDarkMode(),
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: App Information
          _buildSectionHeader('About NutriWise'),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.eco_rounded, color: AppTheme.primaryGreen, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'NutriWise v1.0.0',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Unified intelligent nutrition and health tracking app powered by Flutter and Groq LLM API. Designed to make balanced eating and progress tracking seamless.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
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
