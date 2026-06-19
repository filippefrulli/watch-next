import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotInterestedService {
  static const _key = 'not_interested_titles';
  static const _maxSize = 50;

  static Future<List<String>> getTitles() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    return List<String>.from(jsonDecode(json));
  }

  static Future<bool> contains(String title) async {
    final titles = await getTitles();
    return titles.contains(title);
  }

  static Future<void> addTitle(String title) async {
    final prefs = await SharedPreferences.getInstance();
    final titles = await getTitles();
    titles.add(title);
    if (titles.length > _maxSize) titles.removeAt(0);
    await prefs.setString(_key, jsonEncode(titles));
  }

  /// Removes a title so it can be recommended again (undo).
  static Future<void> removeTitle(String title) async {
    final prefs = await SharedPreferences.getInstance();
    final titles = await getTitles();
    titles.removeWhere((t) => t == title);
    await prefs.setString(_key, jsonEncode(titles));
  }
}
