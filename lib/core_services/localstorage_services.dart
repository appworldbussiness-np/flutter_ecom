import 'package:shared_preferences/shared_preferences.dart';

enum LocalStorageKey { darktheme }

class LocalStorageService {
  static final _instance = LocalStorageService._();

  // instance for shared preferences
  final _prefs = SharedPreferencesAsync();

  // private constructor
  LocalStorageService._();

  // factory constructor
  factory LocalStorageService() => _instance;

  Future<void> setdarktheme(bool value) async {
    await _prefs.setBool(LocalStorageKey.darktheme.name, value);
  }

  Future<bool> getdarktheme() async {
    return await _prefs.getBool(LocalStorageKey.darktheme.name) ?? false;
  }
}
