import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/widgets/match_card.dart';
import 'package:myfc_app/widgets/quarter_score_widget.dart';

class Match {
  final int id;
  final DateTime date;
  final String opponent;
  final String score;
  final int teamId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Player>? players;
  final List<ModelGoal>? goals;
  final Map<int, QuarterScore>? quarterScores;

  Match({
    required this.id,
    required this.date,
    required this.opponent,
    required this.score,
    required this.teamId,
    required this.createdAt,
    this.updatedAt,
    this.players,
    this.goals,
    this.quarterScores,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    List<Player>? playerList;
    List<ModelGoal>? goalList;
    Map<int, QuarterScore>? quarterMap;

    if (json['players'] != null) {
      playerList = (json['players'] as List)
          .map((player) => Player.fromJson(player))
          .toList();
    }

    if (json['goals'] != null) {
      goalList = (json['goals'] as List)
          .map((goal) => ModelGoal.fromJson(goal))
          .toList();
    }

    if (json['quarter_scores'] != null) {
      quarterMap = {};
      (json['quarter_scores'] as Map<String, dynamic>).forEach((key, value) {
        quarterMap![int.parse(key)] = QuarterScore.fromJson(value);
      });
    }

    return Match(
      id: json['id'],
      date: DateTime.parse(json['date']),
      opponent: json['opponent'],
      score: json['score'],
      teamId: json['team_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      players: playerList,
      goals: goalList,
      quarterScores: quarterMap,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'date': date.toIso8601String(),
      'opponent': opponent,
      'score': score,
      'team_id': teamId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };

    if (players != null) {
      data['player_ids'] = players!.map((player) => player.id).toList();
    }

    return data;
  }

  String getResult() {
    if (score.isEmpty) return '무';
    
    final scores = score.split(':');
    if (scores.length != 2) return '무';
    
    final ourScore = int.tryParse(scores[0]) ?? 0;
    final theirScore = int.tryParse(scores[1]) ?? 0;
    
    if (ourScore > theirScore) return '승';
    if (ourScore < theirScore) return '패';
    return '무';
  }

  MatchResult getResultEnum() {
    if (score.isEmpty) return MatchResult.draw;
    
    final scores = score.split(':');
    if (scores.length != 2) return MatchResult.draw;
    
    final ourScore = int.tryParse(scores[0]) ?? 0;
    final theirScore = int.tryParse(scores[1]) ?? 0;
    
    if (ourScore > theirScore) return MatchResult.win;
    if (ourScore < theirScore) return MatchResult.lose;
    return MatchResult.draw;
  }
  
  int get ourScore {
    if (score.isEmpty) return 0;
    final scores = score.split(':');
    if (scores.length != 2) return 0;
    return int.tryParse(scores[0]) ?? 0;
  }
  
  int get opponentScore {
    if (score.isEmpty) return 0;
    final scores = score.split(':');
    if (scores.length != 2) return 0;
    return int.tryParse(scores[1]) ?? 0;
  }
}

class ModelGoal {
  final int id;
  final int matchId;
  final int playerId;
  final int? assistPlayerId;
  final int quarter;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Player? player;
  final Player? assistPlayer;

  ModelGoal({
    required this.id,
    required this.matchId,
    required this.playerId,
    this.assistPlayerId,
    required this.quarter,
    required this.createdAt,
    this.updatedAt,
    this.player,
    this.assistPlayer,
  });

  factory ModelGoal.fromJson(Map<String, dynamic> json) {
    return ModelGoal(
      id: json['id'],
      matchId: json['match_id'],
      playerId: json['player_id'],
      assistPlayerId: json['assist_player_id'],
      quarter: json['quarter'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      player: json['player'] != null ? Player.fromJson(json['player']) : null,
      assistPlayer: json['assist_player'] != null
          ? Player.fromJson(json['assist_player'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'match_id': matchId,
      'player_id': playerId,
      'assist_player_id': assistPlayerId,
      'quarter': quarter,
    };
  }
}

// QuarterScore 클래스 제거 - widgets/quarter_score_widget.dart에서 임포트하여 사용 