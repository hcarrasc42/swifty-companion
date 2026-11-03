import 'dart:convert';

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
    final token = await auth.getToken();

    final response = await sendRequest(
      () => _client.get(
        Uri.parse('$_baseUrl/${Uri.encodeComponent(login)}'),
        headers: {'Authorization': 'Bearer $token'},
      ),
      timeout: timeout,
    );

    switch (response.statusCode) {
      case 200:
        break;
      case 401:
        // El token ya no vale (revocado o caducado antes de tiempo). Se
        // descarta para que el siguiente intento pida uno nuevo.
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
}
