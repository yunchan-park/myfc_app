import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myfc_app/models/team.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/models/match.dart';

class StorageService {
  static const String teamCacheKey = 'team_cache_key';
  static const String playersCacheKey = 'players_cache_key';
  static const String matchesCacheKey = 'matches_cache_key';

  // Save team to cache
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

  // Get cached team
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

  // Save players to cache
  Future<void> cachePlayers(List<Player> players) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playersJson = jsonEncode(players.map((player) => player.toJson()).toList());
      await prefs.setString(playersCacheKey, playersJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error caching players: $e');
      }
    }
  }

  // Get cached players
  Future<List<Player>> getCachedPlayers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playersJson = prefs.getString(playersCacheKey);
      
      if (playersJson != null) {
        final playersList = jsonDecode(playersJson) as List;
        return playersList.map((json) => Player.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached players: $e');
      }
      return [];
    }
  }

  // Save matches to cache
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

  // Get cached matches
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

  // Clear all cache
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
} 