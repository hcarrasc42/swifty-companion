import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/level_bar.dart';
import '../widgets/profile_header.dart';
import '../widgets/project_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.login, required this.users});

  final String login;
  final UserService users;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Se guarda el Future en el estado: si se creara dentro de build(), cada
  // reconstrucción volvería a llamar a la API.
  late final Future<User> _user = widget.users.fetchUser(widget.login);

  /// Cursus elegido en el selector. Mientras sea null se muestra el principal.
  int? _cursusId;

  @override
  Widget build(BuildContext context) {
    // El AppBar muestra solo la flecha de "atrás" porque esta pantalla se
    // abrió con Navigator.push: Flutter sabe que hay una ruta anterior.
    return Scaffold(
      appBar: AppBar(title: Text(widget.login)),
      body: FutureBuilder<User>(
        future: _user,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final error = snapshot.error;
            return Center(
              child: Text(error is UserException ? error.message : '$error'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildProfile(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildProfile(User user) {
    final cursus = _selectedCursus(user);
    // Cada proyecto indica a qué cursus pertenece; sin cursus se muestran todos.
    final projects = cursus == null
        ? user.projects
        : [
            for (final p in user.projects)
              if (p.cursusIds.contains(cursus.id)) p,
          ];
    final titleStyle = Theme.of(context).textTheme.titleMedium;

    // ListView porque el contenido (sobre todo los proyectos) no cabe en una
    // pantalla y hay que poder desplazarlo.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ProfileHeader(user: user, cursus: cursus),
            if (user.cursus.length > 1) ...[
              const SizedBox(height: 16),
              DropdownButton<int>(
                isExpanded: true,
                value: cursus!.id,
                items: [
                  for (final c in user.cursus)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (id) => setState(() => _cursusId = id),
              ),
            ],
            const SizedBox(height: 24),
            Text('Skills', style: titleStyle),
            const SizedBox(height: 8),
            if (cursus == null || cursus.skills.isEmpty)
              const Text('Sin skills en este cursus')
            else
              for (final skill in cursus.skills)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LevelBar(label: skill.name, level: skill.level),
                ),
            const SizedBox(height: 16),
            Text('Proyectos (${projects.length})', style: titleStyle),
            if (projects.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Sin proyectos en este cursus'),
              )
            else
              for (final project in projects) ProjectTile(project: project),
          ],
        ),
      ),
    );
  }

  Cursus? _selectedCursus(User user) {
    for (final c in user.cursus) {
      if (c.id == _cursusId) return c;
    }
    return user.mainCursus;
  }
}
