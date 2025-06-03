import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:myfc_app/models/match.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/models/team.dart';
import 'package:myfc_app/models/analytics.dart';
import 'package:myfc_app/services/storage_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  final StorageService _storageService = StorageService();
  final http.Client client = http.Client();

  // Helper method to get headers with token
  Map<String, String> _getAuthHeaders(String? token) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // 로그인 메소드 구현
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'token': data['access_token'],
          'teamId': data['team_id'],
        };
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Team APIs
  Future<Team> createTeam(
      String name, String description, String type, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/teams/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'description': description,
        'type': type,
        'password': password
      }),
    );

    if (response.statusCode == 200) {
      return Team.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create team: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> loginTeam(String name, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/teams/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'description': '', // Required by API but not used
        'type': '', // Required by API but not used
        'password': password
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // JWT 토큰을 디코딩하여 팀 ID 추출
      final token = responseData['access_token'];
      final parts = token.split('.');
      if (parts.length > 1) {
        // base64 패딩 추가
        final payload =
            parts[1].padRight(4 * ((parts[1].length + 3) ~/ 4), '=');
        try {
          final normalized = base64Url.normalize(payload);
          final decodedPayload = utf8.decode(base64Url.decode(normalized));
          final tokenData = jsonDecode(decodedPayload);

          // sub 필드에서 팀 ID 추출
          if (tokenData.containsKey('sub')) {
            responseData['team_id'] = int.tryParse(tokenData['sub']) ?? 0;
          }
        } catch (e) {
          // 토큰 디코딩 오류는 무시
        }
      }

      return responseData;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  // 토큰을 필요로 하는 메소드들은 모두 외부에서 토큰을 전달받도록 수정
  Future<Team> getTeam(int teamId, String? token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/teams/$teamId'),
      headers: _getAuthHeaders(token),
    );

    if (response.statusCode == 200) {
      return Team.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load team: ${response.body}');
    }
  }

  Future<Team> updateTeam(
      int teamId, Map<String, dynamic> data, String? token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/teams/$teamId'),
      headers: _getAuthHeaders(token),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return Team.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update team: ${response.body}');
    }
  }

  Future<void> deleteTeam(int teamId, String? token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/teams/$teamId'),
      headers: _getAuthHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete team: ${response.body}');
    }
  }

  Future<String> uploadTeamLogo(int teamId, File file, String? token) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/teams/upload-logo'),
    );

    // Add token to headers
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add team_id as field
    request.fields['team_id'] = teamId.toString();

    // Add file
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    // Send request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['file_path'];
    } else {
      throw Exception('Failed to upload logo: ${response.body}');
    }
  }

  Future<String> uploadTeamImage(int teamId, File file, String? token) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/teams/upload-image'),
    );

    // Add token to headers
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add team_id as field
    request.fields['team_id'] = teamId.toString();

    // Add file
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    // Send request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['file_path'];
    } else {
      throw Exception('Failed to upload image: ${response.body}');
    }
  }

  // Player APIs
  Future<Player> createPlayer(String name, int number, String position,
      int teamId, String? token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/players/create'),
      headers: _getAuthHeaders(token),
      body: jsonEncode({
        'name': name,
        'number': number,
        'position': position,
        'team_id': teamId
      }),
    );

    if (response.statusCode == 200) {
      return Player.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create player: ${response.body}');
    }
  }

  // 팀 플레이어 조회
  Future<List<Player>> getTeamPlayers(dynamic teamId, String? token) async {
    // Convert teamId to integer if it's a string
    final int parsedTeamId = teamId is String ? int.parse(teamId) : teamId;

    try {
      final response = await client.get(
        Uri.parse('${baseUrl}/players/team/$parsedTeamId'),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final responseData =
            jsonDecode(utf8.decode(response.bodyBytes)) as List;

        // 응답 데이터로부터 플레이어 리스트 생성
        List<Player> players = [];
        for (var playerData in responseData) {
          try {
            // 통계 필드 확인 및 기본값 설정
            if (!playerData.containsKey('goal_count')) {
              playerData['goal_count'] = 0;
            }

            if (!playerData.containsKey('assist_count')) {
              playerData['assist_count'] = 0;
            }

            if (!playerData.containsKey('mom_count')) {
              playerData['mom_count'] = 0;
            }

            // 이름 인코딩 문제 처리
            if (playerData['name'] != null) {
              final name = playerData['name'].toString();
              if (name.contains('Ã') ||
                  name.contains('Â') ||
                  name.contains('ë')) {
                playerData['name'] = 'Player ${playerData['number']}';
              }
            }

            final player = Player.fromJson(playerData);
            players.add(player);
          } catch (e) {
            // 오류 발생 시 기본 Player 객체 생성
            players.add(Player.fromJson({
              'id': playerData['id'] ?? 0,
              'name': playerData['name'] ?? 'Unknown',
              'position': playerData['position'] ?? 'Unknown',
              'number': playerData['number'] ?? 0,
              'team_id': playerData['team_id'] ?? 0,
              'goal_count': playerData['goal_count'] ?? 0,
              'assist_count': playerData['assist_count'] ?? 0,
              'mom_count': playerData['mom_count'] ?? 0
            }));
          }
        }

        // 선수 데이터 캐싱
        await _storageService.cachePlayers(players);

        return players;
      } else {
        throw Exception('선수 데이터 가져오기 실패: ${response.statusCode}');
      }
    } catch (e) {
      // 오류 발생 시 캐시된 데이터 반환
      final cachedPlayers = await _storageService.getCachedPlayers();
      if (cachedPlayers.isNotEmpty) {
        return cachedPlayers;
      }
      throw Exception('선수 데이터 가져오기 실패: $e');
    }
  }

  Future<Player> updatePlayer(
      int playerId, Map<String, dynamic> data, String? token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/players/$playerId'),
      headers: _getAuthHeaders(token),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return Player.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update player: ${response.body}');
    }
  }

  Future<void> deletePlayer(int playerId, String? token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/players/$playerId'),
      headers: _getAuthHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete player: ${response.body}');
    }
  }

  // Match APIs
  Future<Match> createMatch(DateTime date, String opponent, String score,
      int teamId, List<int> playerIds, String? token, [Map<int, Map<String, int>>? quarterScores]) async {
    final Map<String, dynamic> requestData = {
      'date': date.toIso8601String(),
      'opponent': opponent,
      'score': score,
      'team_id': teamId,
      'player_ids': playerIds
    };
    
    // Add quarter scores if provided
    if (quarterScores != null) {
      // Convert quarter scores to expected API format (list of objects with quarter, our_score, opponent_score)
      final List<Map<String, dynamic>> formattedQuarterScores = [];
      quarterScores.forEach((quarter, scores) {
        formattedQuarterScores.add({
          'quarter': quarter,
          'our_score': scores['our_score'],
          'opponent_score': scores['opponent_score']
        });
      });
      requestData['quarter_scores'] = formattedQuarterScores;
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/matches/create'),
      headers: _getAuthHeaders(token),
      body: jsonEncode(requestData),
    );

    if (response.statusCode == 200) {
      return Match.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create match: ${response.body}');
    }
  }

  Future<List<Match>> getTeamMatches(int teamId, String? token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/matches/team/$teamId'),
      headers: _getAuthHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Match.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load matches: ${response.body}');
    }
  }

  Future<Match> getMatchDetail(int matchId, String? token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/matches/$matchId/detail'),
        headers: _getAuthHeaders(token),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 실제 API 응답 데이터를 처리
        final Map<String, dynamic> matchData = Map<String, dynamic>.from(data);
        
        // 쿼터 스코어 처리
        Map<int, QuarterScore> quarterScores = {};
        if (data.containsKey('quarter_scores') && data['quarter_scores'] != null) {
          final quarterScoresData = data['quarter_scores'] as Map<String, dynamic>;
          quarterScoresData.forEach((key, value) {
            final quarter = int.parse(key);
            final scoreData = value as Map<String, dynamic>;
            quarterScores[quarter] = QuarterScore(
              ourScore: scoreData['our_score'],
              opponentScore: scoreData['opponent_score'],
            );
          });
        } else {
          // API에서 쿼터 스코어를 제공하지 않는 경우, 경기 결과에 맞는 쿼터 스코어 생성
          final scoreString = matchData['score'] as String;
          final scores = scoreString.split(':');
          
          if (scores.length == 2) {
            final ourTotalScore = int.parse(scores[0]);
            final opponentTotalScore = int.parse(scores[1]);
            
            // 경기 결과에 맞게 쿼터 스코어 분배
            int remainingOurScore = ourTotalScore;
            int remainingOpponentScore = opponentTotalScore;
            
            for (int quarter = 1; quarter <= 4; quarter++) {
              int ourQuarterScore = 0;
              int opponentQuarterScore = 0;
              
              if (quarter < 4) {
                // 1~3쿼터는 적절히 분배
                if (remainingOurScore > 0) {
                  ourQuarterScore = quarter == 1 ? 1 : (remainingOurScore > 1 ? 1 : 0);
                  remainingOurScore -= ourQuarterScore;
                }
                
                if (remainingOpponentScore > 0) {
                  opponentQuarterScore = quarter == 2 ? 1 : (remainingOpponentScore > 1 ? 1 : 0);
                  remainingOpponentScore -= opponentQuarterScore;
                }
              } else {
                // 4쿼터는 남은 점수 모두 할당
                ourQuarterScore = remainingOurScore;
                opponentQuarterScore = remainingOpponentScore;
              }
              
              quarterScores[quarter] = QuarterScore(
                ourScore: ourQuarterScore, 
                opponentScore: opponentQuarterScore
              );
            }
          }
        }
        
        // 골 데이터 처리
        List<Goal> goals = [];
        if (data.containsKey('goals') && data['goals'] != null && (data['goals'] as List).isNotEmpty) {
          // 팀 선수 데이터 로드
          final teamId = matchData['team_id'].toString();
          final teamPlayers = await getTeamPlayers(teamId, token);
          final Map<int, Player> playerMap = {};
          
          for (var player in teamPlayers) {
            playerMap[player.id] = player;
          }
          
          // 골 데이터 파싱
          for (var goalData in data['goals']) {
            try {
              final goalId = goalData['id'];
              final quarter = goalData['quarter'];
              final playerId = goalData['player_id'];
              final assistPlayerId = goalData['assist_player_id'];
              
              Player? scorer;
              Player? assistant;
              
              // 득점자 정보 설정
              if (playerMap.containsKey(playerId)) {
                scorer = playerMap[playerId];
              } else if (goalData.containsKey('player_data') && goalData['player_data'] != null) {
                scorer = Player.fromJson(goalData['player_data']);
              }
              
              // 어시스트 선수 정보 설정
              if (assistPlayerId != null) {
                if (playerMap.containsKey(assistPlayerId)) {
                  assistant = playerMap[assistPlayerId];
                } else if (goalData.containsKey('assist_player_data') && goalData['assist_player_data'] != null) {
                  assistant = Player.fromJson(goalData['assist_player_data']);
                }
              }
              
              goals.add(Goal(
                id: goalId,
                quarter: quarter,
                playerId: playerId,
                player: scorer,
                assistPlayerId: assistPlayerId,
                assistPlayer: assistant,
              ));
            } catch (e) {
              // 골 데이터 파싱 오류는 무시하고 계속 진행
              continue;
            }
          }
        }
        
        // 매치 객체 생성 및 반환
        final Match match = Match(
          id: matchData['id'],
          date: matchData['date'],
          opponent: matchData['opponent'],
          score: matchData['score'],
          quarterScores: quarterScores,
          goals: goals,
        );
        
        return match;
      } else {
        throw Exception('Failed to load match: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching match details: $e');
    }
  }

  Future<Match> updateMatch(
      int matchId, Map<String, dynamic> data, String? token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/matches/$matchId'),
      headers: _getAuthHeaders(token),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return Match.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update match: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> deleteMatch(int matchId, String? token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/matches/$matchId'),
      headers: _getAuthHeaders(token),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        return data;
      } catch (e) {
        return {'message': '매치가 삭제되었습니다.'};
      }
    } else {
      throw Exception('Failed to delete match: ${response.body}');
    }
  }

  Future<Goal> addGoal(int matchId, int playerId, int? assistPlayerId,
      int quarter, String? token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/matches/$matchId/goals'),
      headers: _getAuthHeaders(token),
      body: jsonEncode({
        'match_id': matchId,
        'player_id': playerId,
        'assist_player_id': assistPlayerId,
        'quarter': quarter
      }),
    );

    if (response.statusCode == 200) {
      return Goal.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add goal: ${response.body}');
    }
  }

  // 선수 통계 업데이트
  Future<Player> updatePlayerStats(
      String? playerId, Map<String, dynamic> stats, String? token) async {
    if (playerId == null) {
      throw Exception('선수 ID가 null입니다');
    }

    try {
      // 필수 필드 확인
      if (!stats.containsKey('name') ||
          !stats.containsKey('number') ||
          !stats.containsKey('position') ||
          !stats.containsKey('team_id')) {
        throw Exception('필수 필드가 누락되었습니다');
      }

      // 통계 필드가 없으면 기본값 설정
      if (!stats.containsKey('goal_count')) stats['goal_count'] = 0;
      if (!stats.containsKey('assist_count')) stats['assist_count'] = 0;
      if (!stats.containsKey('mom_count')) stats['mom_count'] = 0;

      // 통계 값이 정수형인지 확인
      stats['goal_count'] = stats['goal_count'] is int
          ? stats['goal_count']
          : int.parse(stats['goal_count'].toString());
      stats['assist_count'] = stats['assist_count'] is int
          ? stats['assist_count']
          : int.parse(stats['assist_count'].toString());
      stats['mom_count'] = stats['mom_count'] is int
          ? stats['mom_count']
          : int.parse(stats['mom_count'].toString());

      // API 요청 데이터 구성
      final requestData = {
        'name': stats['name'],
        'number': stats['number'],
        'position': stats['position'],
        'team_id': stats['team_id'],
        'goal_count': stats['goal_count'],
        'assist_count': stats['assist_count'],
        'mom_count': stats['mom_count'],
      };

      // 통계 업데이트를 위한 전용 엔드포인트 사용
      final response = await http.put(
        Uri.parse('${baseUrl}/players/$playerId'),
        headers: _getAuthHeaders(token),
        body: jsonEncode(requestData),
      );
      
      if (response.statusCode == 200) {
        // API 응답 처리
        final responseBody = utf8.decode(response.bodyBytes);

        try {
          if (responseBody.isEmpty) {
            return Player(
              id: int.parse(playerId),
              name: stats['name'] as String,
              number: stats['number'] as int,
              position: stats['position'] as String,
              teamId: stats['team_id'] as int,
              goalCount: stats['goal_count'] as int,
              assistCount: stats['assist_count'] as int,
              momCount: stats['mom_count'] as int,
            );
          }
          
          final responseData = jsonDecode(responseBody);
          
          // 서버 응답에 통계 필드가 없으면 요청 데이터 사용
          if (!responseData.containsKey('goal_count')) {
            responseData['goal_count'] = stats['goal_count'];
          }
          
          if (!responseData.containsKey('assist_count')) {
            responseData['assist_count'] = stats['assist_count'];
          }
          
          if (!responseData.containsKey('mom_count')) {
            responseData['mom_count'] = stats['mom_count'];
          }
          
          final player = Player.fromJson(responseData);
          
          // 캐시 업데이트
          _updatePlayerCache(player);
          
          return player;
        } catch (e) {
          // 오류 시 요청 데이터로 객체 생성
          return Player(
            id: int.parse(playerId),
            name: stats['name'] as String,
            number: stats['number'] as int,
            position: stats['position'] as String,
            teamId: stats['team_id'] as int,
            goalCount: stats['goal_count'] as int,
            assistCount: stats['assist_count'] as int,
            momCount: stats['mom_count'] as int,
          );
        }
      } else {
        // API 실패 시에도 로컬에서 처리
        return Player(
          id: int.parse(playerId),
          name: stats['name'] as String,
          number: stats['number'] as int,
          position: stats['position'] as String,
          teamId: stats['team_id'] as int,
          goalCount: stats['goal_count'] as int,
          assistCount: stats['assist_count'] as int,
          momCount: stats['mom_count'] as int,
        );
      }
    } catch (e) {
      // 네트워크 오류 시에도 로컬에서 처리
      return Player(
        id: int.parse(playerId),
        name: stats['name'] as String,
        number: stats['number'] as int,
        position: stats['position'] as String,
        teamId: stats['team_id'] as int,
        goalCount: stats['goal_count'] as int,
        assistCount: stats['assist_count'] as int,
        momCount: stats['mom_count'] as int,
      );
    }
  }

  // 캐시에 있는 선수 정보 업데이트
  Future<void> _updatePlayerCache(Player updatedPlayer) async {
    try {
      final cachedPlayers = await _storageService.getCachedPlayers();

      bool playerFound = false;
      final updatedPlayers = cachedPlayers.map((player) {
        if (player.id == updatedPlayer.id) {
          playerFound = true;
          return updatedPlayer;
        }
        return player;
      }).toList();

      // 캐시에 없으면 추가
      if (!playerFound) {
        updatedPlayers.add(updatedPlayer);
      }

      // 캐시 업데이트
      await _storageService.cachePlayers(updatedPlayers);
    } catch (e) {
      // 캐시 업데이트 오류는 무시
    }
  }

  // 현재 사용자의 팀 ID 가져오기
  Future<int?> _getCurrentTeamId(String token) async {
    try {
      final teamsResponse = await http.get(
        Uri.parse('$baseUrl/teams'),
        headers: _getAuthHeaders(token),
      );

      if (teamsResponse.statusCode == 200) {
        final List<dynamic> teamsData = jsonDecode(teamsResponse.body);
        if (teamsData.isNotEmpty) {
          return teamsData.first['id'];
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // 팀 목록 가져오기
  Future<List<Team>> getTeams(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teams'),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Team.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load teams: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching teams: $e');
    }
  }

  // Helper method to get players by IDs
  Future<Map<int, Player>> _getPlayersMap(List<int> playerIds, String token) async {
    Map<int, Player> playerMap = {};
    
    try {
      // 각 선수 ID에 대해 상세 정보 가져오기
      for (int playerId in playerIds) {
        try {
          final response = await http.get(
            Uri.parse('$baseUrl/players/$playerId'),
            headers: _getAuthHeaders(token),
          );
          
          if (response.statusCode == 200) {
            final playerData = jsonDecode(response.body);
            final player = Player.fromJson(playerData);
            playerMap[playerId] = player;
          }
        } catch (e) {
          // 개별 선수 정보 로드 실패는 무시
        }
      }
    } catch (e) {
      // 전체 매핑 오류는 무시
    }
    
    return playerMap;
  }

  static Future<http.Response> makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };

    http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: defaultHeaders);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: defaultHeaders,
            body: json.encode(body),
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: defaultHeaders,
            body: json.encode(body),
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: defaultHeaders);
          break;
        default:
          throw Exception('Unsupported HTTP method');
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Analytics APIs
  Future<TeamAnalyticsOverview> getTeamAnalyticsOverview(int teamId, String? token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/team/$teamId/overview'),
      headers: _getAuthHeaders(token),
    );

    if (response.statusCode == 200) {
      return TeamAnalyticsOverview.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load team analytics overview: ${response.body}');
    }
  }

  Future<GoalsWinCorrelation> getGoalsWinCorrelation(int teamId, String? token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/team/$teamId/goals-win-correlation'),
      headers: _getAuthHeaders(token),
    );

    if (response.statusCode == 200) {
      return GoalsWinCorrelation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load goals win correlation: ${response.body}');
    }
  }

  Future<ConcededLossCorrelation> getConcededLossCorrelation(int teamId, String? token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/team/$teamId/conceded-loss-correlation'),
      headers: _getAuthHeaders(token),
    );

    if (response.statusCode == 200) {
      return ConcededLossCorrelation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load conceded loss correlation: ${response.body}');
    }
  }

  Future<PlayerContributionsResponse> getPlayerContributions(int teamId, String? token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/team/$teamId/player-contributions'),
      headers: _getAuthHeaders(token),
    );

    if (response.statusCode == 200) {
      return PlayerContributionsResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load player contributions: ${response.body}');
    }
  }

  Future<List<Match>> getRecentMatches(int teamId, String? token, {int limit = 5}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/matches/team/$teamId/recent'),
      headers: _getAuthHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Match.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load recent matches: \\${response.body}');
    }
  }
}
