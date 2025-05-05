class Player {
  final int id;
  final String name;
  final int number;
  final String position;
  final int teamId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  int momCount;
  int assistCount;
  int goalCount;

  Player({
    required this.id,
    required this.name,
    required this.number,
    required this.position,
    required this.teamId,
    required this.createdAt,
    this.updatedAt,
    this.momCount = 0,
    this.assistCount = 0,
    this.goalCount = 0,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      number: json['number'],
      position: json['position'],
      teamId: json['team_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      momCount: json['mom_count'] ?? 0,
      assistCount: json['assist_count'] ?? 0,
      goalCount: json['goal_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'position': position,
      'team_id': teamId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
} 