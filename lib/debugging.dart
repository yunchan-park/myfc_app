import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/services/storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 디버깅 스크립트
void main() async {
  print('===== 디버깅 스크립트 시작 =====');
  
  // Flutter Secure Storage 초기화
  const storage = FlutterSecureStorage();
  
  // 저장된 토큰 가져오기
  final token = await storage.read(key: 'auth_token');
  if (token == null) {
    print('저장된 토큰이 없습니다.');
    exit(1);
  }
  
  print('토큰: $token');
  
  // 팀 ID 가져오기
  final teamIdStr = await storage.read(key: 'team_id');
  if (teamIdStr == null) {
    print('저장된 팀 ID가 없습니다.');
    exit(1);
  }
  
  final teamId = int.parse(teamIdStr);
  print('팀 ID: $teamId');
  
  // API 기본 설정
  const baseUrl = 'http://localhost:8000';
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
  
  try {
    // 인증 테스트
    print('\n===== 인증 테스트 =====');
    final authResponse = await http.get(
      Uri.parse('$baseUrl/teams/$teamId'),
      headers: headers,
    );
    
    if (authResponse.statusCode == 200) {
      print('인증 성공');
      final teamData = jsonDecode(authResponse.body);
      print('팀 정보: ${teamData['name']}');
    } else {
      print('인증 실패: ${authResponse.statusCode} - ${authResponse.body}');
      exit(1);
    }
    
    // 선수 목록 가져오기
    print('\n===== 선수 목록 조회 =====');
    final playersResponse = await http.get(
      Uri.parse('$baseUrl/players/team/$teamId'),
      headers: headers,
    );
    
    if (playersResponse.statusCode != 200) {
      print('선수 목록 조회 실패: ${playersResponse.statusCode} - ${playersResponse.body}');
      exit(1);
    }
    
    final List<dynamic> players = jsonDecode(playersResponse.body);
    print('선수 수: ${players.length}');
    
    // 선수 정보 분석 및 디버깅
    print('\n===== 선수 정보 분석 =====');
    
    for (final player in players) {
      print('\n선수 ID: ${player['id']}');
      print('이름: ${player['name']}');
      print('번호: ${player['number']}');
      print('포지션: ${player['position']}');
      
      // 통계 정보 분석
      final hasGoalCount = player.containsKey('goal_count');
      final hasAssistCount = player.containsKey('assist_count');
      final hasMomCount = player.containsKey('mom_count');
      
      print('골 카운트 필드 존재: $hasGoalCount (값: ${player['goal_count'] ?? "없음"})');
      print('어시스트 카운트 필드 존재: $hasAssistCount (값: ${player['assist_count'] ?? "없음"})');
      print('MOM 카운트 필드 존재: $hasMomCount (값: ${player['mom_count'] ?? "없음"})');
      
      // 통계 업데이트 실행 
      if (player['id'] != null) {
        print('\n선수 통계 업데이트 시도 (ID: ${player['id']})');
        
        // 현재 통계 정보
        final currentGoals = player['goal_count'] is int ? player['goal_count'] : 0;
        final currentAssists = player['assist_count'] is int ? player['assist_count'] : 0;
        final currentMom = player['mom_count'] is int ? player['mom_count'] : 0;
        
        // 테스트용 통계 정보 (골 +1, 어시스트 +1, MOM +1)
        final updatedData = {
          'name': player['name'],
          'number': player['number'],
          'position': player['position'],
          'team_id': teamId,
          'goal_count': currentGoals + 1,
          'assist_count': currentAssists + 1, 
          'mom_count': currentMom + 1,
        };
        
        print('업데이트할 통계: $updatedData');
        
        final updateResponse = await http.put(
          Uri.parse('$baseUrl/players/${player['id']}'),
          headers: headers,
          body: jsonEncode(updatedData),
        );
        
        if (updateResponse.statusCode == 200) {
          print('통계 업데이트 성공');
          
          try {
            final updatedPlayer = jsonDecode(updateResponse.body);
            print('업데이트된 통계:');
            print('골: ${updatedPlayer['goal_count'] ?? "응답 없음"} (이전: $currentGoals)');
            print('어시스트: ${updatedPlayer['assist_count'] ?? "응답 없음"} (이전: $currentAssists)');
            print('MOM: ${updatedPlayer['mom_count'] ?? "응답 없음"} (이전: $currentMom)');
          } catch (e) {
            print('응답 파싱 실패: $e');
            print('원본 응답: ${updateResponse.body}');
          }
        } else {
          print('통계 업데이트 실패: ${updateResponse.statusCode} - ${updateResponse.body}');
        }
        
        // 첫 번째 선수만 업데이트하고 종료
        break;
      }
    }
    
    // 업데이트 후 선수 목록 다시 가져오기
    print('\n===== 업데이트 후 선수 목록 재확인 =====');
    final updatedPlayersResponse = await http.get(
      Uri.parse('$baseUrl/players/team/$teamId'),
      headers: headers,
    );
    
    if (updatedPlayersResponse.statusCode == 200) {
      final List<dynamic> updatedPlayers = jsonDecode(updatedPlayersResponse.body);
      print('선수 수: ${updatedPlayers.length}');
      
      for (final player in updatedPlayers) {
        print('\n선수 ID: ${player['id']}');
        print('이름: ${player['name']}');
        print('골: ${player['goal_count'] ?? "없음"}');
        print('어시스트: ${player['assist_count'] ?? "없음"}');
        print('MOM: ${player['mom_count'] ?? "없음"}');
      }
    } else {
      print('업데이트 후 선수 목록 조회 실패: ${updatedPlayersResponse.statusCode}');
    }
    
  } catch (e) {
    print('오류 발생: $e');
  }
  
  print('\n===== 디버깅 스크립트 종료 =====');
  exit(0);
} 