import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/neubrutal.dart';
import '../utils/string_helper.dart';
import '../utils/language_notifier.dart';
import '../utils/localization_data.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final List<Map<String, String>> _languages = [
    {'name': 'English', 'native': 'English', 'code': 'en'},
    {'name': 'Hindi', 'native': 'हिन्दी', 'code': 'hi'},
    {'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ', 'code': 'pa'},
    {'name': 'Spanish', 'native': 'Español', 'code': 'es'},
    {'name': 'French', 'native': 'Français', 'code': 'fr'},
    {'name': 'German', 'native': 'Deutsch', 'code': 'de'},
    {'name': 'Chinese', 'native': '中文', 'code': 'zh'},
    {'name': 'Arabic', 'native': 'العربية', 'code': 'ar'},
    {'name': 'Portuguese', 'native': 'Português', 'code': 'pt'},
    {'name': 'Russian', 'native': 'Русский', 'code': 'ru'},
    {'name': 'Japanese', 'native': '日本語', 'code': 'ja'},
    {'name': 'Korean', 'native': '한국어', 'code': 'ko'},
    {'name': 'Bengali', 'native': 'বাংলা', 'code': 'bn'},
    {'name': 'Telugu', 'native': 'తెలుగు', 'code': 'te'},
    {'name': 'Marathi', 'native': 'मराठी', 'code': 'mr'},
    {'name': 'Tamil', 'native': 'தமிழ்', 'code': 'ta'},
    {'name': 'Gujarati', 'native': 'ગુજરાતી', 'code': 'gu'},
    {'name': 'Urdu', 'native': 'اردو', 'code': 'ur'},
    {'name': 'Kannada', 'native': 'ਕನ್ನಡ', 'code': 'kn'},
    {'name': 'Odia', 'native': 'ଓଡ਼ੀਆ', 'code': 'or'},
    {'name': 'Malayalam', 'native': 'മലയാളം', 'code': 'ml'},
  ];

  late String _selectedCode;

  @override
  void initState() {
    super.initState();
    _selectedCode = LanguageNotifier.languageCode.value;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF0F0F0),
      appBar: NeuAppBar(
        title: StringHelper.selectLanguage,
        fontSize: 24,
        actions: const [],
        leading: buildCircleIcon(Icons.arrow_back, () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              LocalizationData.data[_selectedCode]?['pickSourceDesc'] ?? "Choose your preferred language.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14),
            ).animate().fadeIn(),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final lang = _languages[index];
                final isSelected = _selectedCode == lang['code'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedCode = lang['code']!);
                    },
                    child: NeuContainer(
                      padding: const EdgeInsets.all(16),
                      color: isSelected ? NeuColors.accent : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                      shadowOffset: isSelected ? 2 : 4,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : NeuColors.bg,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                            child: Text(
                              lang['native']![0],
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang['native']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: isSelected ? Colors.black : textColor,
                                  ),
                                ),
                                Text(
                                  lang['name']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.black54 : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 30).ms).slideX(begin: 0.1);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: NeuButton(
              onTap: () async {
                await LanguageNotifier.setLanguage(_selectedCode);
                if (mounted) Navigator.pop(context);
              },
              color: NeuColors.primary,
              child: Text(LocalizationData.data[_selectedCode]?['selectAndContinue'] ?? "SELECT & CONTINUE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}
