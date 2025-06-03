import 'package:myfc_app/models/player.dart';

enum MatchResult {
  win,
  lose,
  draw
}

class Match {
  final int id;
  final String date;
  final String opponent;
  final String score;
  final Map<int, QuarterScore>? quarterScores;
  final List<Goal>? goals;

  Match({
    required this.id,
    required this.date,
    required this.opponent,
    required this.score,
    this.quarterScores,
    this.goals,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    Map<int, QuarterScore>? quarters;
    List<Goal>? goals;

    if (json.containsKey('quarter_scores') && json['quarter_scores'] != null) {
      quarters = {};
      Map<String, dynamic> quarterData = json['quarter_scores'];
      quarterData.forEach((key, value) {
        int quarter = int.tryParse(key) ?? 0;
        quarters![quarter] = QuarterScore.fromJson(value);
      });
    }

    if (json.containsKey('goals') && json['goals'] != null) {
      goals = [];
      List<dynamic> goalsData = json['goals'];
      for (var goalJson in goalsData) {
        goals.add(Goal.fromJson(goalJson));
      }
    }

    // 디버그를 위한 로그 출력
    print('매치 데이터 파싱:');
    print('ID: ${json['id']}');
    print('날짜: ${json['date']}');
    print('상대: ${json['opponent']}');
    print('점수: ${json['score']}');
    print('쿼터 스코어: $quarters');
    print('득점 기록: $goals');

    return Match(
      id: json['id'],
      date: json['date'],
      opponent: json['opponent'],
      score: json['score'],
      quarterScores: quarters,
      goals: goals,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> quarterData = {};
    
    if (quarterScores != null) {
      quarterScores!.forEach((quarter, score) {
        quarterData[quarter.toString()] = score.toJson();
      });
    }
    
    List<Map<String, dynamic>>? goalsData;
    
    if (goals != null) {
      goalsData = goals!.map((goal) => goal.toJson()).toList();
    }
    
    return {
      'id': id,
      'date': date,
      'opponent': opponent,
      'score': score,
      'quarter_scores': quarterScores != null ? quarterData : null,
      'goals': goals != null ? goalsData : null,
    };
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

class QuarterScore {
  final int ourScore;
  final int opponentScore;

  QuarterScore({
    required this.ourScore,
    required this.opponentScore,
  });

  factory QuarterScore.fromJson(Map<String, dynamic> json) {
    return QuarterScore(
      ourScore: json['our_score'],
      opponentScore: json['opponent_score'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'our_score': ourScore,
      'opponent_score': opponentScore,
    };
  }
}

class Goal {
  final int id;
  final int quarter;
  final int playerId;
  final int? assistPlayerId;
  final Player? player;  // 득점자 선수 객체
  final Player? assistPlayer;  // 어시스트 선수 객체
  final String? scorerName;  // 득점자 이름 스냅샷
  final String? assistName;  // 어시스트 이름 스냅샷

  Goal({
    required this.id,
    required this.quarter,
    required this.playerId,
    this.assistPlayerId,
    this.player,
    this.assistPlayer,
    this.scorerName,
    this.assistName,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    // 디버그를 위한 로그 출력
    print('골 데이터 파싱:');
    print('ID: ${json['id']}');
    print('쿼터: ${json['quarter']}');
    print('득점자 ID: ${json['player_id']}');
    print('어시스트 ID: ${json['assist_player_id']}');
    
    Player? player;
    Player? assistPlayer;
    
    // player_data가 있으면 Player 객체 생성
    if (json.containsKey('player_data') && json['player_data'] != null) {
      player = Player.fromJson(json['player_data']);
      print('득점자 이름: ${player.name}');
    }
    
    // assist_player_data가 있으면 Player 객체 생성
    if (json.containsKey('assist_player_data') && json['assist_player_data'] != null) {
      assistPlayer = Player.fromJson(json['assist_player_data']);
      print('어시스트 선수 이름: ${assistPlayer.name}');
    }
    
    return Goal(
      id: json['id'],
      quarter: json['quarter'],
      playerId: json['player_id'],
      assistPlayerId: json['assist_player_id'],
      player: player,
      assistPlayer: assistPlayer,
      scorerName: json['scorer_name'],
      assistName: json['assist_name'],
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {
      'id': id,
      'quarter': quarter,
      'player_id': playerId,
    };
    
    if (assistPlayerId != null) {
      data['assist_player_id'] = assistPlayerId;
    }
    
    // Player 객체를 JSON으로 변환하지 않음 (API 요청에는 필요하지 않을 수 있음)
    
    return data;
  }
} 