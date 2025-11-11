import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // String operations
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  // Int operations
  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  // Bool operations
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // Double operations
  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  // List<String> operations
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  // Object operations (using JSON)
  Future<bool> setObject(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    return await setString(key, jsonString);
  }

  Map<String, dynamic>? getObject(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  // List of objects
  Future<bool> setObjectList(
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    final jsonString = jsonEncode(value);
    return await setString(key, jsonString);
  }

  List<Map<String, dynamic>>? getObjectList(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((e) => e as Map<String, dynamic>).toList();
  }

  // Remove operations
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  // Clear all
  Future<bool> clear() async {
    return await _prefs.clear();
  }

  // Check if key exists
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  // Get all keys
  Set<String> getKeys() {
    return _prefs.getKeys();
  }

  // Storage Keys Constants
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyFontSize = 'font_size';
  static const String keyLineHeight = 'line_height';
  static const String keyFontFamily = 'font_family';
  static const String keyIsFirstTime = 'is_first_time';
  static const String keyRecentSearches = 'recent_searches';
  static const String keyReadingSettings = 'reading_settings';
  static const String keyNotificationEnabled = 'notification_enabled';
}
