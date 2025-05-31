class TeamAnalyticsOverview {
  final int totalMatches;
  final int wins;
  final int draws;
  final int losses;
  final double winRate;
  final double avgGoalsScored;
  final double avgGoalsConceded;
  final Map<String, int> highestScoringMatch;
  final Map<String, int> mostConcededMatch;

  TeamAnalyticsOverview({
    required this.totalMatches,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.winRate,
    required this.avgGoalsScored,
    required this.avgGoalsConceded,
    required this.highestScoringMatch,
    required this.mostConcededMatch,
  });

  factory TeamAnalyticsOverview.fromJson(Map<String, dynamic> json) {
    return TeamAnalyticsOverview(
      totalMatches: json['total_matches'] ?? 0,
      wins: json['wins'] ?? 0,
      draws: json['draws'] ?? 0,
      losses: json['losses'] ?? 0,
      winRate: (json['win_rate'] ?? 0.0).toDouble(),
      avgGoalsScored: (json['avg_goals_scored'] ?? 0.0).toDouble(),
      avgGoalsConceded: (json['avg_goals_conceded'] ?? 0.0).toDouble(),
      highestScoringMatch: Map<String, int>.from(json['highest_scoring_match'] ?? {}),
      mostConcededMatch: Map<String, int>.from(json['most_conceded_match'] ?? {}),
    );
  }
}

class GoalRangeData {
  final String goals;
  final int matches;
  final int wins;
  final double winRate;

  GoalRangeData({
    required this.goals,
    required this.matches,
    required this.wins,
    required this.winRate,
  });

  factory GoalRangeData.fromJson(Map<String, dynamic> json) {
    return GoalRangeData(
      goals: json['goals'] ?? '',
      matches: json['matches'] ?? 0,
      wins: json['wins'] ?? 0,
      winRate: (json['win_rate'] ?? 0.0).toDouble(),
    );
  }
}

class GoalsWinCorrelation {
  final List<GoalRangeData> goalRanges;
  final int optimalGoals;
  final double avgGoalsForWin;

  GoalsWinCorrelation({
    required this.goalRanges,
    required this.optimalGoals,
    required this.avgGoalsForWin,
  });

  factory GoalsWinCorrelation.fromJson(Map<String, dynamic> json) {
    return GoalsWinCorrelation(
      goalRanges: (json['goal_ranges'] as List<dynamic>?)
          ?.map((e) => GoalRangeData.fromJson(e))
          .toList() ?? [],
      optimalGoals: json['optimal_goals'] ?? 0,
      avgGoalsForWin: (json['avg_goals_for_win'] ?? 0.0).toDouble(),
    );
  }
}

class ConcededRangeData {
  final String conceded;
  final int matches;
  final int losses;
  final double lossRate;

  ConcededRangeData({
    required this.conceded,
    required this.matches,
    required this.losses,
    required this.lossRate,
  });

  factory ConcededRangeData.fromJson(Map<String, dynamic> json) {
    return ConcededRangeData(
      conceded: json['conceded'] ?? '',
      matches: json['matches'] ?? 0,
      losses: json['losses'] ?? 0,
      lossRate: (json['loss_rate'] ?? 0.0).toDouble(),
    );
  }
}

class ConcededLossCorrelation {
  final List<ConcededRangeData> concededRanges;
  final int dangerThreshold;
  final double avgConcededForLoss;

  ConcededLossCorrelation({
    required this.concededRanges,
    required this.dangerThreshold,
    required this.avgConcededForLoss,
  });

  factory ConcededLossCorrelation.fromJson(Map<String, dynamic> json) {
    return ConcededLossCorrelation(
      concededRanges: (json['conceded_ranges'] as List<dynamic>?)
          ?.map((e) => ConcededRangeData.fromJson(e))
          .toList() ?? [],
      dangerThreshold: json['danger_threshold'] ?? 3,
      avgConcededForLoss: (json['avg_conceded_for_loss'] ?? 0.0).toDouble(),
    );
  }
}

class PlayerContribution {
  final int id;
  final String name;
  final int matchesPlayed;
  final int wins;
  final double winRate;
  final int goals;
  final int assists;
  final int momCount;
  final double contributionScore;
  final double avgGoalsPerMatch;

  PlayerContribution({
    required this.id,
    required this.name,
    required this.matchesPlayed,
    required this.wins,
    required this.winRate,
    required this.goals,
    required this.assists,
    required this.momCount,
    required this.contributionScore,
    required this.avgGoalsPerMatch,
  });

  factory PlayerContribution.fromJson(Map<String, dynamic> json) {
    return PlayerContribution(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      matchesPlayed: json['matches_played'] ?? 0,
      wins: json['wins'] ?? 0,
      winRate: (json['win_rate'] ?? 0.0).toDouble(),
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      momCount: json['mom_count'] ?? 0,
      contributionScore: (json['contribution_score'] ?? 0.0).toDouble(),
      avgGoalsPerMatch: (json['avg_goals_per_match'] ?? 0.0).toDouble(),
    );
  }
}

class PlayerContributionsResponse {
  final List<PlayerContribution> players;
  final Map<String, String> topContributor;
  final Map<String, String> mostReliable;

  PlayerContributionsResponse({
    required this.players,
    required this.topContributor,
    required this.mostReliable,
  });

  factory PlayerContributionsResponse.fromJson(Map<String, dynamic> json) {
    return PlayerContributionsResponse(
      players: (json['players'] as List<dynamic>?)
          ?.map((e) => PlayerContribution.fromJson(e))
          .toList() ?? [],
      topContributor: Map<String, String>.from(json['top_contributor'] ?? {}),
      mostReliable: Map<String, String>.from(json['most_reliable'] ?? {}),
    );
  }
} 