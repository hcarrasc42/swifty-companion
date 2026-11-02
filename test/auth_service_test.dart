import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swifty_companion/services/auth_service.dart';

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

  test('credenciales rechazadas lanzan AuthException', () async {
    final auth = AuthService(
      clientId: 'id',
      clientSecret: 'mal',
      client: MockClient((_) async => http.Response('{}', 401)),
    );

    expect(auth.getToken(), throwsA(isA<AuthException>()));
  });

  test('sin red lanza AuthException', () async {
    final auth = AuthService(
      clientId: 'id',
      clientSecret: 'secret',
      client: MockClient((_) async => throw http.ClientException('sin red')),
    );

    expect(auth.getToken(), throwsA(isA<AuthException>()));
  });

  test('respuesta sin access_token lanza AuthException', () async {
    final auth = AuthService(
      clientId: 'id',
      clientSecret: 'secret',
      client: MockClient((_) async => http.Response('{"foo":1}', 200)),
    );

    expect(auth.getToken(), throwsA(isA<AuthException>()));
  });
}
