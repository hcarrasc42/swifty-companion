import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/error_view.dart';
import '../widgets/level_bar.dart';
import '../widgets/profile_header.dart';
import '../widgets/project_tile.dart';

/// Ancho a partir del cual el perfil pasa a dos columnas. Es el límite que
/// usa Material 3 entre pantalla "compacta" (móvil en vertical) y "mediana".
const wideLayoutBreakpoint = 600.0;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.login, required this.users});

  final String login;
  final UserService users;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

/// Lo que necesita la pantalla: el usuario y las cabeceras para su foto.
typedef _Profile = ({User user, Map<String, String> imageHeaders});

class _ProfileScreenState extends State<ProfileScreen> {
  // Se guarda el Future en el estado: si se creara dentro de build(), cada
  // reconstrucción volvería a llamar a la API. Solo cambia al reintentar.
  late Future<_Profile> _profile = _load();

  /// Cursus elegido en el selector. Mientras sea null se muestra el principal.
  int? _cursusId;

  @override
  Widget build(BuildContext context) {
    // El AppBar muestra solo la flecha de "atrás" porque esta pantalla se
    // abrió con Navigator.push: Flutter sabe que hay una ruta anterior.
    return Scaffold(
      appBar: AppBar(title: Text(widget.login)),
      body: FutureBuilder<_Profile>(
        future: _profile,
        builder: (context, snapshot) {
          // Primero el estado de carga: al reintentar, el snapshot conserva el
          // error anterior hasta que termina la nueva petición.
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(error: snapshot.error, onRetry: _retry);
          }
          final profile = snapshot.data!;
          return _buildProfile(profile.user, profile.imageHeaders);
        },
      ),
    );
  }

  Future<_Profile> _load() async {
    final user = await widget.users.fetchUser(widget.login);
    // Justo después de fetchUser el token está guardado y vigente, así que
    // esto no hace otra petición. Si aun así fallara, el perfil se muestra
    // igual: la foto se queda en la inicial.
    Map<String, String> headers;
    try {
      headers = await widget.users.imageHeaders();
    } catch (_) {
      headers = const {};
    }
    return (user: user, imageHeaders: headers);
  }

  void _retry() {
    // Con llaves y no con `=>`: setState no admite un callback que devuelva
    // un Future, y la flecha devolvería el valor de la asignación.
    setState(() {
      _profile = _load();
    });
  }

  Widget _buildProfile(User user, Map<String, String> imageHeaders) {
    final cursus = _selectedCursus(user);
    // Cada proyecto indica a qué cursus pertenece; sin cursus se muestran todos.
    final projects = cursus == null
        ? user.projects
        : [
            for (final p in user.projects)
              if (p.cursusIds.contains(cursus.id)) p,
          ];
    final summary = _summarySection(user, cursus, imageHeaders);
    final projectList = _projectsSection(projects);

    // SafeArea: en horizontal, el notch o la barra de gestos tapan los lados.
    // LayoutBuilder da el ancho disponible real (no el de toda la pantalla),
    // y con él se elige el layout.
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // ListView porque el contenido (sobre todo los proyectos) no cabe
          // en una pantalla y hay que poder desplazarlo.
          if (constraints.maxWidth < wideLayoutBreakpoint) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...summary,
                    const SizedBox(height: 16),
                    ...projectList,
                  ],
                ),
              ),
            );
          }
          // Pantalla ancha (tablet, o móvil en horizontal): dos columnas que
          // se reparten el ancho con Expanded, cada una con su propio scroll.
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: summary,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: projectList,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Cabecera, selector de cursus y skills.
  List<Widget> _summarySection(
    User user,
    Cursus? cursus,
    Map<String, String> imageHeaders,
  ) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    return [
      ProfileHeader(user: user, cursus: cursus, imageHeaders: imageHeaders),
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
    ];
  }

  List<Widget> _projectsSection(List<ProjectUser> projects) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    return [
      Text('Proyectos (${projects.length})', style: titleStyle),
      if (projects.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Sin proyectos en este cursus'),
        )
      else
        for (final project in projects) ProjectTile(project: project),
    ];
  }

  Cursus? _selectedCursus(User user) {
    for (final c in user.cursus) {
      if (c.id == _cursusId) return c;
    }
    return user.mainCursus;
  }
}
