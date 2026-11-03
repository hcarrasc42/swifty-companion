import 'package:flutter/material.dart';

import '../models/user.dart';

/// Un proyecto con su resultado: aprobado (verde), suspendido (rojo) o
/// pendiente de corregir (gris, con el estado).
class ProjectTile extends StatelessWidget {
  const ProjectTile({super.key, required this.project});

  final ProjectUser project;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mark = '${project.finalMark ?? '-'}';
    // `validated` es null mientras el proyecto no está corregido.
    final (icon, color, trailing) = switch (project.validated) {
      true => (Icons.check_circle, Colors.green, mark),
      false => (Icons.cancel, colors.error, mark),
      null => (Icons.schedule, colors.outline, _statusLabel(project.status)),
    };
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(project.name),
      trailing: Text(
        trailing,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  static String _statusLabel(String status) => switch (status) {
    'in_progress' => 'En curso',
    'waiting_for_correction' => 'Por corregir',
    'searching_a_group' || 'creating_group' => 'Buscando grupo',
    'finished' => 'Terminado',
    _ => status,
  };
}
