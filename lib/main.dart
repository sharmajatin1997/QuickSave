import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/home_screen.dart';
import 'screens/format_screen.dart';
import 'screens/history_screen.dart';
import 'models/video_info.dart';

import 'screens/tools_screen.dart';
import 'screens/platform_download_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/trim_video_screen.dart';
import 'screens/convert_format_screen.dart';
import 'screens/remove_watermark_screen.dart';
import 'screens/remove_audio_screen.dart';
import 'screens/extract_mp3_screen.dart';
import 'screens/add_watermark_screen.dart';
import 'screens/compress_screen.dart';
import 'screens/content_detail_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/language_screen.dart';
import 'utils/string_helper.dart';
import 'utils/theme_notifier.dart';
import 'utils/language_notifier.dart';
import 'widgets/responsive_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageNotifier.init();
  runApp(const QuickSaveApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    
    // ShellRoute for Responsive Tablet Layout
    ShellRoute(
      builder: (context, state, child) => ResponsiveLayout(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/format',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return FormatScreen(
              url: extra['url'] as String,
              info: extra['info'] as VideoInfo,
            );
          },
        ),
        GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
        GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        GoRoute(path: '/language', builder: (context, state) => const LanguageScreen()),
        GoRoute(path: '/tools', builder: (context, state) => const ToolsScreen()),
        GoRoute(path: '/trim', builder: (context, state) => const TrimVideoScreen()),
        GoRoute(path: '/convert', builder: (context, state) => const ConvertFormatScreen()),
        GoRoute(path: '/remove-watermark', builder: (context, state) => const RemoveWatermarkScreen()),
        GoRoute(path: '/remove-audio', builder: (context, state) => const RemoveAudioScreen()),
        GoRoute(path: '/extract-mp3', builder: (context, state) => const ExtractMp3Screen()),
        GoRoute(path: '/add-watermark', builder: (context, state) => const AddWatermarkScreen()),
        GoRoute(path: '/compress', builder: (context, state) => const CompressScreen()),
        GoRoute(path: '/faq', builder: (context, state) => const FAQDetailScreen()),
        GoRoute(
          path: '/terms', 
          builder: (context, state) => ContentDetailScreen(title: StringHelper.terms, content: StringHelper.termsContent)
        ),
        GoRoute(
          path: '/privacy', 
          builder: (context, state) => ContentDetailScreen(title: StringHelper.privacy, content: StringHelper.privacyContent)
        ),
        GoRoute(
          path: '/platform',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return PlatformDownloadScreen(
              platformName: extra['name'] as String,
              platformIcon: extra['icon'] as IconData,
              platformColor: extra['color'] as Color,
            );
          },
        ),
      ],
    ),
  ],
);

class QuickSaveApp extends StatelessWidget {
  const QuickSaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeNotifier.themeMode,
      builder: (context, themeMode, child) {
        return ValueListenableBuilder<String>(
          valueListenable: LanguageNotifier.languageCode,
          builder: (context, langCode, child) {
            return MaterialApp.router(
              title: StringHelper.appName,
              debugShowCheckedModeBanner: false,
              routerConfig: _router,
              themeMode: themeMode,
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                fontFamily: 'Lexend', // Consistent professional font
                scaffoldBackgroundColor: const Color(0xFFF0F0F0),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF00E5FF),
                  brightness: Brightness.light,
                ),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  titleTextStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                fontFamily: 'Lexend',
                scaffoldBackgroundColor: const Color(0xFF121212) ,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF00E5FF),
                  brightness: Brightness.dark,
                  surface: const Color(0xFF1E1E1E),
                ),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  titleTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
