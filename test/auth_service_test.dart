import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swifty_companion/services/api_exception.dart';
import 'package:swifty_companion/services/auth_service.dart';

import 'matchers.dart';

http.Response _ok(String token, {int expiresIn = 7200}) => http.Response(
  jsonEncode({'access_token': token, 'expires_in': expiresIn}),
  200,
);

void main() {
  test('pide el token con client_credentials', () async {
    late http.Request sent;
    final auth = AuthService(
      clientId: 'id',
      clientSecret: 'secret',
      client: MockClient((request) async {
        sent = request;
        return _ok('abc');
      }),
    );

    expect(await auth.getToken(), 'abc');
    expect(sent.url.toString(), 'https://api.intra.42.fr/oauth/token');
    expect(sent.bodyFields, {
      'grant_type': 'client_credentials',
      'client_id': 'id',
      'client_secret': 'secret',
    });
  });

  test('reutiliza el token mientras no caduca', () async {
    var calls = 0;
    final auth = AuthService(
      clientId: 'id',
      clientSecret: 'secret',
      client: MockClient((_) async => _ok('tok${++calls}')),
    );

    expect(await auth.getToken(), 'tok1');
    expect(await auth.getToken(), 'tok1');
    expect(calls, 1);
  });

  test('pide otro token cuando el anterior caduca', () async {
    var calls = 0;
    var now = DateTime(2026);
    final auth = AuthService(
      clientId: 'id',
      clientSecret: 'secret',
      now: () => now,
      client: MockClient((_) async => _ok('tok${++calls}', expiresIn: 100)),
    );

    expect(await auth.getToken(), 'tok1');
    now = now.add(const Duration(seconds: 200));
    expect(await auth.getToken(), 'tok2');
  });

  test('maxLifetime acorta la vida del token', () async {
    var calls = 0;
    var now = DateTime(2026);
    final auth = AuthService(
      clientId: 'id',
      clientSecret: 'secret',
      now: () => now,
      maxLifetime: const Duration(seconds: 60),
      client: MockClient((_) async => _ok('tok${++calls}')),
    );

    expect(await auth.getToken(), 'tok1');
    // 60 s de vida menos el margen de 30 s: a los 31 s ya se renueva,
    // aunque la API dijera 7200.
    now = now.add(const Duration(seconds: 31));
    expect(await auth.getToken(), 'tok2');
  });

  test('debugUseInvalidToken guarda un token sin pedirlo', () async {
    var calls = 0;
    final auth = AuthService(
      clientId: 'id',
      clientSecret: 'secret',
      client: MockClient((_) async => _ok('tok${++calls}')),
    );

    auth.debugUseInvalidToken();

    expect(await auth.getToken(), 'token-invalido');
    expect(calls, 0);
  });

  test('credenciales rechazadas lanzan ApiError.credentials', () async {
    final auth = AuthService(
      clientId: 'id',
      clientSecret: 'mal',
      client: MockClient((_) async => http.Response('{}', 401)),
    );

    expect(auth.getToken(), throwsApiError(ApiError.credentials));
  });

  test('sin credenciales no llama a la API', () async {
    var calls = 0;
    final auth = AuthService(
      clientId: '',
      clientSecret: '',
      client: MockClient((_) async {
        calls++;
        return _ok('tok');
      }),
    );

    await expectLater(auth.getToken(), throwsApiError(ApiError.credentials));
    expect(calls, 0);
  });

  test('sin red lanza ApiError.network', () async {
    final auth = AuthService(
      clientId: 'id',
      clientSecret: 'secret',
      client: MockClient((_) async => throw http.ClientException('sin red')),
    );

    expect(auth.getToken(), throwsApiError(ApiError.network));
  });

  test('si la API no responde a tiempo lanza ApiError.timeout', () async {
    final auth = AuthService(
      clientId: 'id',
      clientSecret: 'secret',
      timeout: const Duration(milliseconds: 10),
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return _ok('tok');
      }),
    );

    expect(auth.getToken(), throwsApiError(ApiError.timeout));
  });

  test('error del servidor lanza ApiError.server', () async {
    final auth = AuthService(
      clientId: 'id',
      clientSecret: 'secret',
      client: MockClient((_) async => http.Response('', 503)),
    );

    expect(auth.getToken(), throwsApiError(ApiError.server));
  });

  test('respuesta sin access_token lanza ApiError.badResponse', () async {
    final auth = AuthService(
      clientId: 'id',
      clientSecret: 'secret',
      client: MockClient((_) async => http.Response('{"foo":1}', 200)),
    );

    expect(auth.getToken(), throwsApiError(ApiError.badResponse));
  });

  test('respuesta en HTML lanza ApiError.badResponse', () async {
    final auth = AuthService(
      clientId: 'id',
      clientSecret: 'secret',
      client: MockClient((_) async => http.Response('<html></html>', 200)),
    );

    expect(auth.getToken(), throwsApiError(ApiError.badResponse));
  });

  test('invalidate descarta el token guardado', () async {
    var calls = 0;
    final auth = AuthService(
      clientId: 'id',
      clientSecret: 'secret',
      client: MockClient((_) async => _ok('tok${++calls}')),
    );

    expect(await auth.getToken(), 'tok1');
    auth.invalidate();
    expect(await auth.getToken(), 'tok2');
  });
}
