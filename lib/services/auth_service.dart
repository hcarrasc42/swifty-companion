import 'dart:convert';

import 'package:http/http.dart' as http;

/// Error al obtener el token de la API de 42.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// Obtiene un token con el flujo OAuth2 `client_credentials` y lo reutiliza
/// mientras no caduque.
class AuthService {
  AuthService({
    required this.clientId,
    required this.clientSecret,
    http.Client? client,
    DateTime Function()? now,
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  static final _tokenUrl = Uri.parse('https://api.intra.42.fr/oauth/token');

  /// Margen para no usar un token que caduca justo al enviarlo.
  static const _expiryMargin = Duration(seconds: 30);

  final String clientId;
  final String clientSecret;
  final http.Client _client;
  final DateTime Function() _now;

  String? _token;
  DateTime? _expiresAt;

  bool get _hasValidToken =>
      _token != null && _now().isBefore(_expiresAt!.subtract(_expiryMargin));

  /// Devuelve el token guardado si sigue vigente; si no, pide uno nuevo.
  Future<String> getToken() async {
    if (_hasValidToken) return _token!;
    return _requestToken();
  }

  Future<String> _requestToken() async {
    final http.Response response;
    try {
      response = await _client.post(
        _tokenUrl,
        body: {
          'grant_type': 'client_credentials',
          'client_id': clientId,
          'client_secret': clientSecret,
        },
      );
    } catch (_) {
      throw const AuthException('No se pudo conectar con la API de 42');
    }

    if (response.statusCode != 200) {
      throw AuthException(
        'La API rechazó las credenciales (HTTP ${response.statusCode})',
      );
    }

    final Object? body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> ||
        body['access_token'] is! String ||
        body['expires_in'] is! int) {
      throw const AuthException('Respuesta de token inesperada');
    }

    _token = body['access_token'] as String;
    _expiresAt = _now().add(Duration(seconds: body['expires_in'] as int));
    return _token!;
  }
}
