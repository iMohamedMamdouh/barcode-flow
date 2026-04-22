import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalStorageService {
  AuthLocalStorageService(this._prefs);

  static const String _usernameKey = 'auth_username';
  static const String _passwordKey = 'auth_password';
  static const String _isLoggedInKey = 'auth_is_logged_in';

  final SharedPreferences _prefs;

  Future<void> saveCredentials({
    required String username,
    required String password,
  }) async {
    await _prefs.setString(_usernameKey, username);
    await _prefs.setString(_passwordKey, password);
    await _prefs.setBool(_isLoggedInKey, true);
  }

  String? get username => _prefs.getString(_usernameKey);
  String? get password => _prefs.getString(_passwordKey);

  bool get isLoggedIn => _prefs.getBool(_isLoggedInKey) ?? false;

  Future<void> clearSession() async {
    await _prefs.remove(_usernameKey);
    await _prefs.remove(_passwordKey);
    await _prefs.remove(_isLoggedInKey);
  }
}
