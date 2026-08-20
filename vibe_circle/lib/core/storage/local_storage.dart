import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage._();
  static final LocalStorage instance = LocalStorage._();

  static const _accessKey = 'vibecircle.access_token';
  static const _refreshKey = 'vibecircle.refresh_token';
  static const _darkModeKey = 'vibecircle.dark_mode';
  static const _purposeKey = 'vibecircle.selected_purpose';
  static const _currentUserIdKey = 'vibecircle.current_user_id';
  static const _anonymousModeKey = 'vibecircle.anonymous_mode';

  late final Box _box;
  late final SharedPreferences _prefs;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('vibecircle_local_storage');
    _prefs = await SharedPreferences.getInstance();
  }

  // Token Operations (Hive)
  Future<String?> getAccessToken() async {
    try {
      return _box.get(_accessKey) as String?;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return _box.get(_refreshKey) as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTokens(String access, String refresh) async {
    await _box.put(_accessKey, access);
    await _box.put(_refreshKey, refresh);
  }

  Future<void> clearTokens() async {
    await _box.delete(_accessKey);
    await _box.delete(_refreshKey);
  }

  // General Settings (SharedPreferences)
  bool getDarkMode() {
    return _prefs.getBool(_darkModeKey) ?? true;
  }

  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool(_darkModeKey, value);
  }

  String getSelectedPurpose() {
    return _prefs.getString(_purposeKey) ?? 'Talk';
  }

  Future<void> setSelectedPurpose(String value) async {
    await _prefs.setString(_purposeKey, value);
  }

  String? getCurrentUserId() {
    return _prefs.getString(_currentUserIdKey);
  }

  Future<void> setCurrentUserId(String? value) async {
    if (value == null) {
      await _prefs.remove(_currentUserIdKey);
    } else {
      await _prefs.setString(_currentUserIdKey, value);
    }
  }

  bool getAnonymousMode() {
    return _prefs.getBool(_anonymousModeKey) ?? false;
  }

  Future<void> setAnonymousMode(bool value) async {
    await _prefs.setBool(_anonymousModeKey, value);
  }

  Future<void> clearAll() async {
    await clearTokens();
    await _prefs.remove(_currentUserIdKey);
    await _prefs.remove(_purposeKey);
    await _prefs.remove(_anonymousModeKey);
  }
}
