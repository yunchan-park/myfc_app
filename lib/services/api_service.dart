import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:myfc_app/models/match.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/models/team.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  
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
  Future<Team> createTeam(String name, String description, String type, String password) async {
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
        final payload = parts[1].padRight(4 * ((parts[1].length + 3) ~/ 4), '=');
        try {
          final normalized = base64Url.normalize(payload);
          final decodedPayload = utf8.decode(base64Url.decode(normalized));
          final tokenData = jsonDecode(decodedPayload);
          
          // sub 필드에서 팀 ID 추출
          if (tokenData.containsKey('sub')) {
            responseData['team_id'] = int.tryParse(tokenData['sub']) ?? 0;
          }
        } catch (e) {
          print('Token decoding error: $e');
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

  Future<Team> updateTeam(int teamId, Map<String, dynamic> data, String? token) async {
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
  Future<Player> createPlayer(String name, int number, String position, int teamId, String? token) async {
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

  Future<List<Player>> getTeamPlayers(int teamId, String? token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/players/team/$teamId'),
        headers: _getAuthHeaders(token),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final players = data.map((json) => Player.fromJson(json)).toList();
        return players;
      } else {
        throw Exception('Failed to load players');
      }
    } catch (e) {
      throw Exception('Network error when loading players: $e');
    }
  }

  Future<Player> updatePlayer(int playerId, Map<String, dynamic> data, String? token) async {
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
  Future<Match> createMatch(
    DateTime date, 
    String opponent, 
    String score, 
    int teamId, 
    List<int> playerIds,
    String? token
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/matches/create'),
      headers: _getAuthHeaders(token),
      body: jsonEncode({
        'date': date.toIso8601String(),
        'opponent': opponent,
        'score': score,
        'team_id': teamId,
        'player_ids': playerIds
      }),
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
    final response = await http.get(
      Uri.parse('$baseUrl/matches/$matchId/detail'),
      headers: _getAuthHeaders(token),
    );

    if (response.statusCode == 200) {
      return Match.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load match detail: ${response.body}');
    }
  }

  Future<Match> updateMatch(int matchId, Map<String, dynamic> data, String? token) async {
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

  Future<void> deleteMatch(int matchId, String? token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/matches/$matchId'),
      headers: _getAuthHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete match: ${response.body}');
    }
  }

  Future<ModelGoal> addGoal(int matchId, int playerId, int? assistPlayerId, int quarter, String? token) async {
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
      return ModelGoal.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add goal: ${response.body}');
    }
  }
} 