import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Obtiene un token con el flujo OAuth2 `client_credentials` y lo reutiliza
/// mientras no caduque.
class AuthService {
  AuthService({
    required this.clientId,
    required this.clientSecret,
    http.Client? client,
    DateTime Function()? now,
    this.timeout = apiTimeout,
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  static final _tokenUrl = Uri.parse('https://api.intra.42.fr/oauth/token');

  /// Margen para no usar un token que caduca justo al enviarlo.
  static const _expiryMargin = Duration(seconds: 30);

  final String clientId;
  final String clientSecret;
  final Duration timeout;
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

  /// Descarta el token guardado: la API lo rechazó aunque no había caducado.
  void invalidate() {
    _token = null;
    _expiresAt = null;
  }

  Future<String> _requestToken() async {
    if (clientId.isEmpty || clientSecret.isEmpty) {
      throw const ApiException(
        ApiError.credentials,
        'Faltan FT_UID o FT_SECRET en el archivo .env',
      );
    }

    final response = await sendRequest(
      () => _client.post(
        _tokenUrl,
        body: {
          'grant_type': 'client_credentials',
          'client_id': clientId,
          'client_secret': clientSecret,
        },
      ),
      timeout: timeout,
    );

    // 42 responde 401 (`invalid_client`) si el UID o el secret no son válidos,
    // por ejemplo cuando el secret se ha regenerado en la intra.
    if (response.statusCode == 400 || response.statusCode == 401) {
      throw const ApiException(
        ApiError.credentials,
        'La API rechazó las credenciales de la app. Revisa el .env.',
      );
    }
    if (response.statusCode != 200) {
      throw ApiException.fromStatus(response.statusCode);
    }

    // Un proxy o Cloudflare pueden devolver HTML: jsonDecode fallaría.
    final Object? body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      throw const ApiException(
        ApiError.badResponse,
        'Respuesta de token inesperada',
      );
    }
    if (body is! Map<String, dynamic> ||
        body['access_token'] is! String ||
        body['expires_in'] is! int) {
      throw const ApiException(
        ApiError.badResponse,
        'Respuesta de token inesperada',
      );
    }

    _token = body['access_token'] as String;
    _expiresAt = _now().add(Duration(seconds: body['expires_in'] as int));
    return _token!;
  }
}
