import 'package:flutter/material.dart';
import '../models/match.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class MatchViewModel extends ChangeNotifier {
  List<Match> matches = [];
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Future<void> fetchMatches() async {
    try {
      final token = await _authService.getToken();
      final teamId = await _authService.getTeamId();
      if (token == null || teamId == null) {
        matches = [];
        notifyListeners();
        return;
      }
      final fetchedMatches = await _apiService.getTeamMatches(teamId, token);
      matches = fetchedMatches;
    } catch (e) {
      print('경기 목록 불러오기 실패: $e');
      matches = [];
    }
    notifyListeners();
  }

  void addMatch(Match match) {
    matches.add(match);
    notifyListeners();
  }
} 