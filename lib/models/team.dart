class Team {
  final int id;
  final String name;
  final String description;
  final String type;
  final String? logoUrl;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Team({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.logoUrl,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: json['type'],
      logoUrl: json['logo_url'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'logo_url': logoUrl,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
} 