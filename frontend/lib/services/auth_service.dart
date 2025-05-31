import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String tokenKey = 'auth_token';
  static const String teamIdKey = 'team_id';

  // 토큰과 팀 ID 저장
  Future<void> saveAuthData(String token, String teamId) async {
    await _secureStorage.write(key: tokenKey, value: token);
    await _secureStorage.write(key: teamIdKey, value: teamId);
  }

  // 토큰 가져오기
  Future<String?> getToken() async {
    return await _secureStorage.read(key: tokenKey);
  }

  // 팀 ID 가져오기
  Future<int?> getTeamId() async {
    final teamIdStr = await _secureStorage.read(key: teamIdKey);
    if (teamIdStr == null || teamIdStr.isEmpty) return null;
    return int.tryParse(teamIdStr) ?? 1; // 기본값 1 제공
  }

  // 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // 로그인 메소드는 ApiService를 필요로 할 때 외부에서 주입받습니다
  Future<bool> signIn(String email, String password, dynamic apiService) async {
    try {
      // API 호출하여 로그인 시도
      final response = await apiService.login(email, password);
      
      if (response != null && response['token'] != null) {
        // 토큰 저장
        await _secureStorage.write(
          key: tokenKey,
          value: response['token'],
        );
        
        // 팀 ID 저장
        if (response['teamId'] != null) {
          await _secureStorage.write(
            key: teamIdKey,
            value: response['teamId'].toString(),
          );
        }
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // 로그아웃
  Future<void> logout() async {
    await _secureStorage.delete(key: tokenKey);
    await _secureStorage.delete(key: teamIdKey);
  }
} 