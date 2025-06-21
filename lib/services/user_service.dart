import 'package:shared_preferences/shared_preferences.dart';
import '../model/user.dart';
import 'database_service.dart';

class UserService {
  // DatabaseService 인스턴스 생성
  final DatabaseService _dbService = DatabaseService();
  static const String _currentUserIdKey = 'current_user_id';

  // 회원가입
  Future<bool> register(String username, String password, String name) async {
    try {
      // DB 조회 로직을 DatabaseService에 위임
      final existingUser = _dbService.getUserByUsername(username);
      if (existingUser != null) {
        return false; // 이미 존재하는 사용자
      }

      final user = User(
        username: username,
        password: password,
        name: name,
        createdAt: DateTime.now(),
      );

      // DB 추가 로직을 DatabaseService에 위임
      await _dbService.addUser(user);
      return true;
    } catch (e) {
      print('회원가입 오류: $e');
      return false;
    }
  }

  // 로그인
  Future<bool> login(String username, String password) async {
    try {
      // DB 조회 로직을 DatabaseService에 위임
      final user = _dbService.getUserByUsername(username);
      if (user != null && user.password == password) {
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
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
  }

  // 현재 사용자 정보 가져오기
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(_currentUserIdKey);
      if (userId == null) return null;

      // DB 조회 로직을 DatabaseService에 위임
      return _dbService.getUser(userId);
    } catch (e) {
      print('현재 사용자 정보 조회 오류: $e');
      return null;
    }
  }

  // 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }
}