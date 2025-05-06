import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 테스트 스크립트
void main() async {
  print('==== 선수 통계 업데이트 테스트 스크립트 시작 ====');
  
  const String baseUrl = 'http://localhost:8000';
  
  try {
    // 1. 앱에서 사용하는 실제 토큰 가져오기
    print('\n1. 저장된 토큰 가져오기:');
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    final String? token = await secureStorage.read(key: 'auth_token');
    
    if (token == null || token.isEmpty) {
      print('저장된 토큰이 없습니다. 앱에서 로그인을 먼저 진행해주세요.');
      exit(1);
    }
    
    print('토큰 가져오기 성공!');
    
    // 2. 인증 헤더 설정
    final authHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    
    // 3. 팀 ID 가져오기
    print('\n2. 팀 ID 가져오기:');
    final String? teamIdStr = await secureStorage.read(key: 'team_id');
    if (teamIdStr == null || teamIdStr.isEmpty) {
      print('저장된 팀 ID가 없습니다.');
      exit(1);
    }
    
    final int teamId = int.parse(teamIdStr);
    print('팀 ID: $teamId');
    
    // 4. 팀 선수 목록 요청
    print('\n3. 팀 선수 목록 API 호출:');
    final playersResponse = await http.get(
      Uri.parse('$baseUrl/players/team/$teamId'),
      headers: authHeaders,
    );
    
    print('응답 상태 코드: ${playersResponse.statusCode}');
    
    if (playersResponse.statusCode == 200) {
      final List<dynamic> playersData = jsonDecode(playersResponse.body);
      
      print('총 선수 수: ${playersData.length}');
      
      if (playersData.isNotEmpty) {
        // 첫 번째 선수의 통계 확인
        final firstPlayer = playersData[0];
        final int playerId = firstPlayer['id'];
        
        print('\n4. 선수 정보:');
        print('ID: $playerId');
        print('이름: ${firstPlayer['name']}');
        print('번호: ${firstPlayer['number']}');
        print('포지션: ${firstPlayer['position']}');
        print('현재 골 수: ${firstPlayer['goal_count'] ?? 0}');
        print('현재 어시스트 수: ${firstPlayer['assist_count'] ?? 0}');
        print('현재 MOM 수: ${firstPlayer['mom_count'] ?? 0}');
        
        // 5. 선수 통계 업데이트
        print('\n5. 선수 통계 업데이트 시도:');
        final updateData = {
          'name': firstPlayer['name'],
          'number': firstPlayer['number'],
          'position': firstPlayer['position'],
          'team_id': teamId,
          'goal_count': (firstPlayer['goal_count'] ?? 0) + 1,
          'assist_count': (firstPlayer['assist_count'] ?? 0) + 1,
          'mom_count': (firstPlayer['mom_count'] ?? 0) + 1
        };
        
        print('업데이트할 데이터: $updateData');
        
        final updateResponse = await http.put(
          Uri.parse('$baseUrl/players/$playerId'),
          headers: authHeaders,
          body: jsonEncode(updateData),
        );
        
        print('응답 상태 코드: ${updateResponse.statusCode}');
        
        if (updateResponse.statusCode == 200) {
          print('응답 본문: ${updateResponse.body}');
          final updatedPlayer = jsonDecode(updateResponse.body);
          
          print('\n6. 업데이트된 선수 정보:');
          print('이름: ${updatedPlayer['name']}');
          print('번호: ${updatedPlayer['number']}');
          print('포지션: ${updatedPlayer['position']}');
          print('업데이트된 골 수: ${updatedPlayer['goal_count'] ?? 0}');
          print('업데이트된 어시스트 수: ${updatedPlayer['assist_count'] ?? 0}');
          print('업데이트된 MOM 수: ${updatedPlayer['mom_count'] ?? 0}');
          
          print('\n통계 업데이트 성공!');
        } else {
          print('통계 업데이트 실패! 응답: ${updateResponse.body}');
        }
      } else {
        print('선수 데이터가 비어 있습니다.');
      }
    } else {
      print('선수 목록 가져오기 실패! 응답: ${playersResponse.body}');
    }
  } catch (e) {
    print('오류 발생: $e');
  }
  
  print('\n==== 선수 통계 업데이트 테스트 스크립트 종료 ====');
  exit(0);
} 