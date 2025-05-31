import 'dart:convert';
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
      final jsonString = jsonEncode(team.toJson());
      await _secureStorage.write(key: 'team_cache', value: jsonString);
    } catch (e) {
      // 캐싱 오류는 무시
    }
  }

  Future<Team?> getCachedTeam() async {
    try {
      final jsonString = await _secureStorage.read(key: 'team_cache');
      if (jsonString != null) {
        final Map<String, dynamic> json = jsonDecode(jsonString);
        return Team.fromJson(json);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> cachePlayers(List<Player> players) async {
    try {
      final jsonString = jsonEncode(players.map((p) => p.toJson()).toList());
      await _secureStorage.write(key: 'players_cache', value: jsonString);
    } catch (e) {
      // 캐싱 오류는 무시
    }
  }

  Future<List<Player>> getCachedPlayers() async {
    try {
      final jsonString = await _secureStorage.read(key: 'players_cache');
      if (jsonString == null) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      return jsonList.map((json) => Player.fromJson(json)).toList();
      
    } catch (e) {
      return [];
    }
  }

  Future<void> cacheMatches(List<Match> matches) async {
    try {
      final jsonString = jsonEncode(matches.map((m) => m.toJson()).toList());
      await _secureStorage.write(key: 'matches_cache', value: jsonString);
    } catch (e) {
      // 캐싱 오류는 무시
    }
  }

  Future<List<Match>> getCachedMatches() async {
    try {
      final jsonString = await _secureStorage.read(key: 'matches_cache');
      if (jsonString != null) {
        final List<dynamic> json = jsonDecode(jsonString);
        return json.map((item) => Match.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> clearCache() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      // 캐시 삭제 오류는 무시
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
      await _secureStorage.delete(key: 'players_cache');
    } catch (e) {
      // 선수 제거 오류는 무시
    }
  }

  Future<void> updatePlayerStats(int playerId, Map<String, dynamic> stats) async {
    try {
      final players = await getCachedPlayers();
      final updatedPlayers = players.map((player) {
        if (player.id == playerId) {
          return Player(
            id: player.id,
            name: stats['name'] ?? player.name,
            number: stats['number'] ?? player.number,
            position: stats['position'] ?? player.position,
            teamId: player.teamId,
            goalCount: stats['goal_count'] ?? player.goalCount,
            assistCount: stats['assist_count'] ?? player.assistCount,
            momCount: stats['mom_count'] ?? player.momCount,
          );
        }
        return player;
      }).toList();
      
      await cachePlayers(updatedPlayers);
    } catch (e) {
      // 통계 업데이트 오류는 무시
    }
  }

  Future<void> removePlayerFromCache(int playerId) async {
    try {
      final players = await getCachedPlayers();
      final updatedPlayers = players.where((player) => player.id != playerId).toList();
      await cachePlayers(updatedPlayers);
    } catch (e) {
      // 선수 제거 오류는 무시
    }
  }
} 