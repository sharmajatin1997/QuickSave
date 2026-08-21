import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:my_downloader/utils/language_notifier.dart';
import '../utils/string_helper.dart';
import '../widgets/neubrutal.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF0F0F0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with Neubrutalism Container and Animation
            NeuContainer(
              padding: const EdgeInsets.all(12),
              color: NeuColors.white,
              borderRadius: 30,
              shadowOffset: 8,
              child: Image.asset(
                'assets/app_logo.png',
                width: 150,
                height: 150,
              ),
            )
            .animate()
            .scale(
              duration: 800.ms,
              curve: Curves.elasticOut,
            )
            .shimmer(delay: 1000.ms, duration: 1500.ms),
            
            const SizedBox(height: 40),
            
            // App Name with Animation
            Text(
              StringHelper.appName,
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -2,
              ),
            )
            .animate()
            .fadeIn(delay: 400.ms, duration: 600.ms)
            .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack),
            
            const SizedBox(height: 10),
            
            // Subtitle
            Text(
              _getLocalizedSubtitle(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.withValues(alpha: 0.8),
                letterSpacing: 4,
              ),
            )
            .animate()
            .fadeIn(delay: 800.ms)
            .blur(begin: const Offset(10, 10), end: Offset.zero),
          ],
        ),
      ),
    );
  }

  String _getLocalizedSubtitle() {
    final code = LanguageNotifier.languageCode.value;
    if (code == 'hi') return "डाउनलोड • एडिट • शेयर";
    if (code == 'pa') return "ਡਾਊਨਲੋਡ • ਐਡਿਟ • ਸ਼ੇਅਰ";
    return "DOWNLOAD • EDIT • SHARE";
  }
}
