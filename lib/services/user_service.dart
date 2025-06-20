import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _currentUserKey = 'current_user';
  static const String _usersKey = 'users';

  // 현재 로그인된 사용자 정보 저장
  static Future<void> saveCurrentUser(String username, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_currentUserKey, '$username|$name');
  }

  // 현재 사용자 정보 가져오기
  static Future<Map<String, String>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

    if (!isLoggedIn) return null;

    final userInfo = prefs.getString(_currentUserKey);
    if (userInfo == null) return null;

    final parts = userInfo.split('|');
    if (parts.length != 2) return null;

    return {
      'username': parts[0],
      'name': parts[1],
    };
  }

  // 로그아웃
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_currentUserKey);
  }

  // 회원가입
  static Future<bool> register(String username, String password, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final users = prefs.getStringList(_usersKey) ?? [];

    // 중복 사용자 확인
    for (String userInfo in users) {
      final parts = userInfo.split('|');
      if (parts.length >= 3 && parts[0] == username) {
        return false; // 이미 존재하는 사용자
      }
    }

    // 새 사용자 추가
    users.add('$username|$password|$name');
    await prefs.setStringList(_usersKey, users);
    return true;
  }

  // 로그인
  static Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final users = prefs.getStringList(_usersKey) ?? [];

    for (String userInfo in users) {
      final parts = userInfo.split('|');
      if (parts.length >= 3 && parts[0] == username && parts[1] == password) {
        await saveCurrentUser(username, parts[2]);
        return true;
      }
    }

    return false;
  }

  // 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }
}