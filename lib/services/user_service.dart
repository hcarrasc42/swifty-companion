import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import 'api_exception.dart';
import 'auth_service.dart';

/// Consulta `/v2/users/:login` con el token de [AuthService].
class UserService {
  UserService({
    required this.auth,
    http.Client? client,
    this.timeout = apiTimeout,
  }) : _client = client ?? http.Client();

  static const _baseUrl = 'https://api.intra.42.fr/v2/users';

  final AuthService auth;
  final Duration timeout;
  final http.Client _client;

  /// Lanza [ApiException] si falla cualquier paso, también al pedir el token.
  Future<User> fetchUser(String login) async {
    var response = await _get(login);

    // 401: el token ya no vale aunque no había caducado (revocado, o la API
    // lo invalidó antes de tiempo). Se pide uno nuevo y se repite la
    // petición una sola vez: si la API rechazara todos los tokens, repetir
    // sin límite sería un bucle infinito.
    if (response.statusCode == 401) {
      if (kDebugMode) debugPrint('[users] 401: se pide otro token y se repite');
      auth.invalidate();
      response = await _get(login);
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 401:
        // También rechazó el token nuevo. Se descarta igualmente para que
        // "Reintentar" empiece con otro.
        auth.invalidate();
        throw const ApiException(
          ApiError.unauthorized,
          'La sesión con la API caducó. Vuelve a intentarlo.',
        );
      case 404:
        throw ApiException(
          ApiError.notFound,
          'No existe ningún estudiante con el login "$login"',
        );
      default:
        throw ApiException.fromStatus(response.statusCode);
    }

    // Cualquier fallo al leer el JSON (no es JSON, falta un campo, tipo
    // distinto) se trata igual: la respuesta no tiene la forma esperada.
    try {
      return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (_) {
      throw const ApiException(
        ApiError.badResponse,
        'Respuesta de usuario inesperada',
      );
    }
  }

  /// Cabeceras para descargar la foto de perfil. El CDN de 42
  /// (`cdn.intra.42.fr`) responde 403 si la petición no lleva el token de la
  /// API. Es el mismo token guardado: no se pide uno nuevo.
  Future<Map<String, String>> imageHeaders() async => {
    'Authorization': 'Bearer ${await auth.getToken()}',
  };

  /// Una petición con el token vigente (o uno nuevo si caducó).
  Future<http.Response> _get(String login) async {
    final token = await auth.getToken();
    return sendRequest(
      () => _client.get(
        Uri.parse('$_baseUrl/${Uri.encodeComponent(login)}'),
        headers: {'Authorization': 'Bearer $token'},
      ),
      timeout: timeout,
    );
  }
}
