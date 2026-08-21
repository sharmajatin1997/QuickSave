import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageNotifier {
  static const String _key = 'app_language';
  static ValueNotifier<String> languageCode = ValueNotifier('en');

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_key);
    if (savedLang != null) {
      languageCode.value = savedLang;
    }
  }

  static Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    languageCode.value = code;
  }
}
