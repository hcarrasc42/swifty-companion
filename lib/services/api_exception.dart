import 'dart:async';

import 'package:http/http.dart' as http;

/// Tipos de fallo al hablar con la API de 42. La interfaz elige el icono y la
/// acción (reintentar o volver) según el tipo.
enum ApiError {
  network,
  timeout,
  credentials,
  unauthorized,
  notFound,
  rateLimited,
  server,
  badResponse,
}

/// Error de la API con un mensaje listo para mostrar al usuario.
class ApiException implements Exception {
  const ApiException(this.error, this.message);

  /// Error para un código HTTP sin tratamiento propio en el servicio.
  factory ApiException.fromStatus(int status) => switch (status) {
    429 => const ApiException(
      ApiError.rateLimited,
      'Demasiadas peticiones seguidas. Espera un momento.',
    ),
    >= 500 => ApiException(
      ApiError.server,
      'La API de 42 no está disponible (HTTP $status)',
    ),
    _ => ApiException(
      ApiError.badResponse,
      'Respuesta inesperada de la API (HTTP $status)',
    ),
  };

  final ApiError error;
  final String message;

  /// Errores pasajeros: tiene sentido volver a intentarlo.
  bool get canRetry => switch (error) {
    ApiError.network ||
    ApiError.timeout ||
    ApiError.unauthorized ||
    ApiError.rateLimited ||
    ApiError.server => true,
    ApiError.credentials || ApiError.notFound || ApiError.badResponse => false,
  };

  @override
  String toString() => 'ApiException(${error.name}): $message';
}

/// Tiempo máximo de espera de cada petición.
const apiTimeout = Duration(seconds: 10);

/// Lanza [request] con un tiempo máximo y convierte los fallos de conexión
/// en [ApiError.network] o [ApiError.timeout].
Future<http.Response> sendRequest(
  Future<http.Response> Function() request, {
  Duration timeout = apiTimeout,
}) async {
  try {
    return await request().timeout(timeout);
  } on TimeoutException {
    throw const ApiException(
      ApiError.timeout,
      'La API de 42 tardó demasiado en responder',
    );
  } catch (_) {
    throw const ApiException(
      ApiError.network,
      'Sin conexión con la API de 42. Revisa tu red.',
    );
  }
}
