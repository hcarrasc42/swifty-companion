import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user.dart';
import 'auth_service.dart';

/// Error al consultar un usuario; `notFound` distingue "no existe" del resto.
class UserException implements Exception {
  const UserException(this.message, {this.notFound = false});

  final String message;
  final bool notFound;

  @override
  String toString() => 'UserException: $message';
}

/// Consulta `/v2/users/:login` con el token de [AuthService].
class UserService {
  UserService({required this.auth, http.Client? client})
    : _client = client ?? http.Client();

  static const _baseUrl = 'https://api.intra.42.fr/v2/users';

  final AuthService auth;
  final http.Client _client;

  Future<User> fetchUser(String login) async {
    final token = await auth.getToken();

    final http.Response response;
    try {
      response = await _client.get(
        Uri.parse('$_baseUrl/${Uri.encodeComponent(login)}'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (_) {
      throw const UserException('No se pudo conectar con la API de 42');
    }

    if (response.statusCode == 404) {
      throw const UserException('No existe ese login', notFound: true);
    }
    if (response.statusCode != 200) {
      throw UserException('Error de la API (HTTP ${response.statusCode})');
    }

    try {
      return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (_) {
      throw const UserException('Respuesta de usuario inesperada');
    }
  }
}
