import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/user.dart';

class UserService {
  static const String _currentUserIdKey = 'current_user_id';
  static Box<User> get _userBox => Hive.box<User>('users');

  // 회원가입
  static Future<bool> register(String username, String password, String name) async {
    try {
      // 중복 사용자 확인
      final existingUser = await getUserByUsername(username);
      if (existingUser != null) {
        return false;
      }

      // 새 사용자 생성
      final user = User(
        username: username,
        password: password,
        name: name,
        createdAt: DateTime.now(),
      );

      // Hive에 저장하고 생성된 키를 ID로 사용
      final key = await _userBox.add(user);
      user.id = key;
      await user.save(); // ID 업데이트

      return true;
    } catch (e) {
      print('회원가입 오류: $e');
      return false;
    }
  }

  // 로그인
  static Future<bool> login(String username, String password) async {
    try {
      final user = await getUserByUsername(username);
      if (user != null && user.password == password) {
        // 현재 사용자 ID 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_currentUserIdKey, user.id!);
        return true;
      }
      return false;
    } catch (e) {
      print('로그인 오류: $e');
      return false;
    }
  }

  // 로그아웃
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
  }

  // 사용자명으로 사용자 찾기
  static Future<User?> getUserByUsername(String username) async {
    try {
      final users = _userBox.values.where((user) => user.username == username);
      return users.isNotEmpty ? users.first : null;
    } catch (e) {
      print('사용자 조회 오류: $e');
      return null;
    }
  }

  // 현재 사용자 정보 가져오기
  static Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(_currentUserIdKey);

      if (userId == null) return null;

      // Hive에서 ID로 사용자 찾기
      final user = _userBox.get(userId);
      return user;
    } catch (e) {
      print('현재 사용자 정보 조회 오류: $e');
      return null;
    }
  }

  // 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }
}