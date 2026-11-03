import 'package:flutter/material.dart';

import '../models/user.dart';
import 'level_bar.dart';

/// Foto, nombre y datos básicos del usuario.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.user, this.cursus});

  final User user;

  /// Cursus seleccionado, del que se muestra el nivel. Null si no tiene.
  final Cursus? cursus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = user.imageUrl;
    return Column(
      children: [
        // La inicial queda debajo de la foto: se ve mientras carga, si el
        // usuario no tiene foto o si la descarga falla.
        CircleAvatar(
          radius: 56,
          foregroundImage: image == null ? null : NetworkImage(image),
          onForegroundImageError: image == null ? null : (error, stack) {},
          child: Text(
            user.login[0].toUpperCase(),
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          user.displayName,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        Text(user.login, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        if (cursus != null) ...[
          LevelBar(label: cursus!.name, level: cursus!.level),
          const SizedBox(height: 8),
        ],
        Card(
          child: Column(
            children: [
              _InfoTile(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user.email.isEmpty ? 'No disponible' : user.email,
              ),
              _InfoTile(
                icon: Icons.place_outlined,
                label: 'Ubicación',
                value: user.location ?? 'Fuera del campus',
              ),
              _InfoTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Wallet',
                value: '${user.wallet} ₳',
              ),
              _InfoTile(
                icon: Icons.fact_check_outlined,
                label: 'Puntos de corrección',
                value: '${user.correctionPoints}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
