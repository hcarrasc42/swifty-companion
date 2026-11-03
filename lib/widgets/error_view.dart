import 'package:flutter/material.dart';

import '../services/api_exception.dart';

/// Icono, mensaje y una acción para un error al cargar datos: "Reintentar"
/// si el fallo es pasajero, "Volver" si repetir no cambiaría nada.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = this.error;
    // Un error que no es ApiException es un fallo de la app, no de la API:
    // se muestra un mensaje genérico en vez del detalle técnico.
    final (message, canRetry) = error is ApiException
        ? (error.message, error.canRetry)
        : ('Ha ocurrido un error inesperado', true);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon(error), size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                message,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (canRetry)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _icon(Object? error) {
    if (error is! ApiException) return Icons.error_outline;
    return switch (error.error) {
      ApiError.network => Icons.wifi_off,
      ApiError.timeout => Icons.hourglass_empty,
      ApiError.credentials || ApiError.unauthorized => Icons.lock_outline,
      ApiError.notFound => Icons.person_off_outlined,
      ApiError.rateLimited => Icons.speed,
      ApiError.server || ApiError.badResponse => Icons.cloud_off,
    };
  }
}
