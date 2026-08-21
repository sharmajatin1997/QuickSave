import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../widgets/neubrutal.dart';
import '../utils/string_helper.dart';
import '../utils/theme_notifier.dart';
import '../utils/language_notifier.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<String>(
      valueListenable: LanguageNotifier.languageCode,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF0F0F0),
          appBar: NeuAppBar(
            title: StringHelper.settings,
            leading: buildCircleIcon(Icons.arrow_back, () => Navigator.pop(context)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(StringHelper.preferences),
                const SizedBox(height: 12),
                
                // Theme Option
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: ThemeNotifier.themeMode,
                  builder: (context, mode, child) {
                    String themeLabel = StringHelper.lightMode;
                    if (mode == ThemeMode.dark) themeLabel = StringHelper.darkMode;
                    if (mode == ThemeMode.system) themeLabel = StringHelper.systemDefault;

                    return _buildSettingsItem(
                      context,
                      StringHelper.theme,
                      themeLabel,
                      Icons.palette_outlined,
                      const Color(0xFFE8EAF6),
                      () => _showThemePicker(context),
                    );
                  },
                ),

                _buildSettingsItem(
                  context,
                  StringHelper.language,
                  StringHelper.languageDefault,
                  Icons.language,
                  const Color(0xFFFFF9C4),
                  () => context.push('/language'),
                ),
                
                const SizedBox(height: 32),
                _buildSectionTitle(StringHelper.support),
                const SizedBox(height: 12),
                _buildSettingsItem(
                  context,
                  StringHelper.faq,
                  StringHelper.faqDesc,
                  Icons.help_outline,
                  const Color(0xFFE1F5FE),
                  () => _showFAQ(context),
                ),
                const SizedBox(height: 32),
                _buildSectionTitle(StringHelper.legal),
                const SizedBox(height: 12),
                _buildSettingsItem(
                  context,
                  StringHelper.terms,
                  StringHelper.termsDesc,
                  Icons.description_outlined,
                  const Color(0xFFF3E5F5),
                  () => _showContent(context, StringHelper.terms, StringHelper.termsContent),
                ),
                _buildSettingsItem(
                  context,
                  StringHelper.privacy,
                  StringHelper.privacyDesc,
                  Icons.security_outlined,
                  const Color(0xFFE8F5E9),
                  () => _showContent(context, StringHelper.privacy, StringHelper.privacyContent),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    '${StringHelper.appName} ${StringHelper.version}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
              ].animate(interval: 100.ms).fadeIn().slideY(begin: 0.1),
            ),
          ),
        );
      }
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color iconBg,
    VoidCallback onTap,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: NeuContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Icon(icon, color: Colors.black),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: isDark ? Colors.white : Colors.black),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Material(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      StringHelper.theme,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildThemeCard(context, StringHelper.lightMode, Icons.light_mode_rounded, ThemeMode.light, const Color(0xFFFFE082)),
                    const SizedBox(width: 16),
                    _buildThemeCard(context, StringHelper.darkMode, Icons.dark_mode_rounded, ThemeMode.dark, const Color(0xFF9FA8DA)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildThemeCard(context, StringHelper.systemDefault, Icons.settings_suggest_rounded, ThemeMode.system, const Color(0xFFB0BEC5), fullWidth: true),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeCard(BuildContext context, String label, IconData icon, ThemeMode mode, Color color, {bool fullWidth = false}) {
    final bool isSelected = ThemeNotifier.themeMode.value == mode;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = GestureDetector(
      onTap: () {
        ThemeNotifier.setTheme(mode);
        Navigator.pop(context);
      },
      child: NeuContainer(
        padding: const EdgeInsets.symmetric(vertical: 20),
        color: isSelected ? color : (isDark ? const Color(0xFF333333) : Colors.white),
        shadowOffset: isSelected ? 2 : 6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black54)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: card) : Expanded(child: card);
  }

  void _showFAQ(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (_, controller) => Material(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: controller,
                children: [
                  Text(StringHelper.faq, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 20),
                  _buildFAQItem(context, StringHelper.faqQ1, StringHelper.faqA1),
                  _buildFAQItem(context, StringHelper.faqQ2, StringHelper.faqA2),
                  _buildFAQItem(context, StringHelper.faqQ3, StringHelper.faqA3),
                  _buildFAQItem(context, StringHelper.faqQ4, StringHelper.faqA4),
                  _buildFAQItem(context, StringHelper.faqQ8, StringHelper.faqA8),
                  _buildFAQItem(context, StringHelper.faqQ5, StringHelper.faqA5),
                  _buildFAQItem(context, StringHelper.faqQ6, StringHelper.faqA6),
                  _buildFAQItem(context, StringHelper.faqQ7, StringHelper.faqA7),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFAQItem(BuildContext context, String q, String a) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Text(a, style: const TextStyle(color: Color(0xFF666666), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showContent(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (_, controller) => Material(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: controller,
                children: [
                  Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 20),
                  Text(content, style: const TextStyle(color: Color(0xFF666666), fontWeight: FontWeight.bold, height: 1.5)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
