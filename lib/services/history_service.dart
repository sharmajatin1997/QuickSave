import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_info.dart';

class HistoryService {
  static const _key = 'downlodr_history';

  Future<List<HistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addItem(HistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getHistory();
    final updated = [item, ...current];
    await prefs.setString(
      _key,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
