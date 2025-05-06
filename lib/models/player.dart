class Player {
  final int id;
  final String name;
  final String position;
  final int number;
  final int teamId;
  final int goalCount;
  final int assistCount;
  final int momCount;

  Player({
    required this.id,
    required this.name,
    required this.position,
    required this.number,
    required this.teamId,
    this.goalCount = 0,
    this.assistCount = 0,
    this.momCount = 0,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'] ?? 'Unknown',
      position: json['position'] ?? 'Unknown',
      number: json['number'] ?? 0,
      teamId: json['team_id'] is String ? int.parse(json['team_id']) : json['team_id'],
      goalCount: json['goal_count'] ?? 0,
      assistCount: json['assist_count'] ?? 0,
      momCount: json['mom_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'number': number,
      'team_id': teamId,
      'goal_count': goalCount,
      'assist_count': assistCount,
      'mom_count': momCount,
    };
  }

  Player copyWith({
    int? id,
    String? name,
    String? position,
    int? number,
    int? teamId,
    int? goalCount,
    int? assistCount,
    int? momCount,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      number: number ?? this.number,
      teamId: teamId ?? this.teamId,
      goalCount: goalCount ?? this.goalCount,
      assistCount: assistCount ?? this.assistCount,
      momCount: momCount ?? this.momCount,
    );
  }
}