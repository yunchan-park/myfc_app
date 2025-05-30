import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myfc_app/models/team.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/models/match.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const String teamCacheKey = 'team_cache_key';
  static const String playersCacheKey = 'players_cache_key';
  static const String matchesCacheKey = 'matches_cache_key';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    webOptions: WebOptions(
      dbName: 'myfc_app_secure_storage',
      publicKey: 'myfc_app_public_key',
    ),
  );

  Future<void> cacheTeam(Team team) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final teamJson = jsonEncode(team.toJson());
      await prefs.setString(teamCacheKey, teamJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error caching team: $e');
      }
    }
  }

  Future<Team?> getCachedTeam() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final teamJson = prefs.getString(teamCacheKey);
      
      if (teamJson != null) {
        final teamMap = jsonDecode(teamJson) as Map<String, dynamic>;
        return Team.fromJson(teamMap);
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached team: $e');
      }
      return null;
    }
  }

  Future<void> cachePlayers(List<Player> players) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final List<Map<String, dynamic>> playersJson = players.map((player) => player.toJson()).toList();
      
      final String playersJsonString = jsonEncode(playersJson);
      
      await prefs.setString('cached_players', playersJsonString);
      
      print('선수 데이터 캐싱 성공: ${players.length}명');
    } catch (e) {
      print('선수 데이터 캐싱 중 오류: $e');
    }
  }

  Future<List<Player>> getCachedPlayers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final String? playersJsonString = prefs.getString('cached_players');
      
      if (playersJsonString == null || playersJsonString.isEmpty) {
        print('캐시된 선수 데이터 없음');
        return [];
      }
      
      final List<dynamic> playersJson = jsonDecode(playersJsonString);
      
      final List<Player> players = playersJson.map((json) => Player.fromJson(json)).toList();
      
      print('캐시된 선수 데이터 로드 성공: ${players.length}명');
      
      return players;
    } catch (e) {
      print('캐시된 선수 데이터 로드 중 오류: $e');
      return [];
    }
  }

  Future<void> cacheMatches(List<Match> matches) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final matchesJson = jsonEncode(matches.map((match) => match.toJson()).toList());
      await prefs.setString(matchesCacheKey, matchesJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error caching matches: $e');
      }
    }
  }

  Future<List<Match>> getCachedMatches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final matchesJson = prefs.getString(matchesCacheKey);
      
      if (matchesJson != null) {
        final matchesList = jsonDecode(matchesJson) as List;
        return matchesList.map((json) => Match.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached matches: $e');
      }
      return [];
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(teamCacheKey);
      await prefs.remove(playersCacheKey);
      await prefs.remove(matchesCacheKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cache: $e');
      }
    }
  }

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }
  
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }
  
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }
  
  Future<void> saveTeamId(String teamId) async {
    await _secureStorage.write(key: 'team_id', value: teamId);
  }
  
  Future<String?> getTeamId() async {
    return await _secureStorage.read(key: 'team_id');
  }

  Future<void> clearCachedPlayers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_players');
      print('캐시된 선수 데이터 삭제됨');
    } catch (e) {
      print('캐시된 선수 데이터 삭제 중 오류: $e');
    }
  }
} 