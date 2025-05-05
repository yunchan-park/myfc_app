import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myfc_app/models/team.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/models/match.dart';

class StorageService {
  static const String TEAM_CACHE_KEY = 'team_cache';
  static const String PLAYERS_CACHE_KEY = 'players_cache';
  static const String MATCHES_CACHE_KEY = 'matches_cache';

  // Save team to cache
  Future<void> cacheTeam(Team team) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(TEAM_CACHE_KEY, jsonEncode(team.toJson()));
  }

  // Get cached team
  Future<Team?> getCachedTeam() async {
    final prefs = await SharedPreferences.getInstance();
    final teamJson = prefs.getString(TEAM_CACHE_KEY);
    
    if (teamJson != null) {
      try {
        return Team.fromJson(jsonDecode(teamJson));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Save players to cache
  Future<void> cachePlayers(List<Player> players) async {
    final prefs = await SharedPreferences.getInstance();
    final playersJson = players.map((player) => player.toJson()).toList();
    await prefs.setString(PLAYERS_CACHE_KEY, jsonEncode(playersJson));
  }

  // Get cached players
  Future<List<Player>?> getCachedPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final playersJson = prefs.getString(PLAYERS_CACHE_KEY);
    
    if (playersJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(playersJson);
        return decoded.map((json) => Player.fromJson(json)).toList();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Save matches to cache
  Future<void> cacheMatches(List<Match> matches) async {
    final prefs = await SharedPreferences.getInstance();
    final matchesJson = matches.map((match) => match.toJson()).toList();
    await prefs.setString(MATCHES_CACHE_KEY, jsonEncode(matchesJson));
  }

  // Get cached matches
  Future<List<Match>?> getCachedMatches() async {
    final prefs = await SharedPreferences.getInstance();
    final matchesJson = prefs.getString(MATCHES_CACHE_KEY);
    
    if (matchesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(matchesJson);
        return decoded.map((json) => Match.fromJson(json)).toList();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Clear all cache
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(TEAM_CACHE_KEY);
    await prefs.remove(PLAYERS_CACHE_KEY);
    await prefs.remove(MATCHES_CACHE_KEY);
  }
} 