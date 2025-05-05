import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String TOKEN_KEY = 'auth_token';
  static const String TEAM_ID_KEY = 'team_id';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Save token and team ID
  Future<void> saveAuthData(String token, int teamId) async {
    await _secureStorage.write(key: TOKEN_KEY, value: token);
    
    // Save team ID in SharedPreferences for easier access
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(TEAM_ID_KEY, teamId);
  }

  // Get token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: TOKEN_KEY);
  }

  // Get team ID
  Future<int?> getTeamId() async {
    print('AuthService: getTeamId 메서드 호출됨');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final teamId = prefs.getInt(TEAM_ID_KEY);
      print('AuthService: getTeamId 결과 - $teamId');
      return teamId;
    } catch (e) {
      print('AuthService: getTeamId 오류 - $e');
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    final teamId = await getTeamId();
    return token != null && teamId != null;
  }

  // Logout
  Future<void> logout() async {
    await _secureStorage.delete(key: TOKEN_KEY);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(TEAM_ID_KEY);
  }
} 