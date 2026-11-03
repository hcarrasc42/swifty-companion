import 'package:flutter/material.dart';

import '../models/user.dart';

/// Nombre, "Nivel 7 · 65 %" y una barra con el progreso dentro del nivel.
/// La usan tanto el nivel del cursus como cada skill.
class LevelBar extends StatelessWidget {
  const LevelBar({super.key, required this.label, required this.level});

  final String label;
  final double level;

  @override
  Widget build(BuildContext context) {
    final percent = levelPercent(level);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Expanded ocupa el ancho sobrante, así un nombre largo se corta
            // con "..." en vez de empujar el nivel fuera de la pantalla.
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Text('Nivel ${level.floor()} · $percent %'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percent / 100,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}
