/// Habilidad de un cursus con su nivel (p. ej. 7.65 = nivel 7, 65 %).
class Skill {
  const Skill({required this.name, required this.level});

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
    name: json['name'] as String,
    level: (json['level'] as num).toDouble(),
  );

  final String name;
  final double level;

  /// Porcentaje de progreso dentro del nivel actual (la parte decimal).
  int get percent => ((level - level.floor()) * 100).round();
}

/// Cursus de un usuario: nivel global y habilidades.
class Cursus {
  const Cursus({
    required this.id,
    required this.name,
    required this.level,
    required this.skills,
  });

  factory Cursus.fromJson(Map<String, dynamic> json) {
    final cursus = json['cursus'] as Map<String, dynamic>;
    return Cursus(
      id: cursus['id'] as int,
      name: cursus['name'] as String,
      level: (json['level'] as num).toDouble(),
      skills: [
        for (final s in json['skills'] as List<dynamic>? ?? const [])
          Skill.fromJson(s as Map<String, dynamic>),
      ],
    );
  }

  final int id;
  final String name;
  final double level;
  final List<Skill> skills;
}

/// Proyecto de un usuario, incluidos los suspendidos (`validated` false).
class ProjectUser {
  const ProjectUser({
    required this.name,
    required this.status,
    required this.cursusIds,
    this.finalMark,
    this.validated,
  });

  factory ProjectUser.fromJson(Map<String, dynamic> json) => ProjectUser(
    name: (json['project'] as Map<String, dynamic>)['name'] as String,
    status: json['status'] as String,
    cursusIds: [
      for (final id in json['cursus_ids'] as List<dynamic>? ?? const [])
        id as int,
    ],
    finalMark: json['final_mark'] as int?,
    validated: json['validated?'] as bool?,
  );

  final String name;

  /// `finished`, `in_progress`, `waiting_for_correction`...
  final String status;
  final List<int> cursusIds;

  /// Null mientras el proyecto no está corregido.
  final int? finalMark;

  /// Null mientras el proyecto no está corregido.
  final bool? validated;
}

/// Datos del perfil de 42 que usa la app (subconjunto de `/v2/users/:login`).
class User {
  const User({
    required this.login,
    required this.displayName,
    required this.email,
    required this.correctionPoints,
    required this.wallet,
    required this.cursus,
    required this.projects,
    this.imageUrl,
    this.location,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>?;
    return User(
      login: json['login'] as String,
      displayName: json['displayname'] as String? ?? json['login'] as String,
      email: json['email'] as String? ?? '',
      correctionPoints: json['correction_point'] as int? ?? 0,
      wallet: json['wallet'] as int? ?? 0,
      imageUrl: image?['link'] as String?,
      location: json['location'] as String?,
      cursus: [
        for (final c in json['cursus_users'] as List<dynamic>? ?? const [])
          Cursus.fromJson(c as Map<String, dynamic>),
      ],
      projects: [
        for (final p in json['projects_users'] as List<dynamic>? ?? const [])
          ProjectUser.fromJson(p as Map<String, dynamic>),
      ],
    );
  }

  final String login;
  final String displayName;
  final String email;
  final int correctionPoints;
  final int wallet;
  final String? imageUrl;

  /// Null si el usuario no está en ningún puesto del campus.
  final String? location;
  final List<Cursus> cursus;
  final List<ProjectUser> projects;

  /// Cursus principal: `42cursus` si existe, y si no el último de la lista.
  Cursus? get mainCursus {
    if (cursus.isEmpty) return null;
    return cursus.firstWhere((c) => c.id == 21, orElse: () => cursus.last);
  }
}
