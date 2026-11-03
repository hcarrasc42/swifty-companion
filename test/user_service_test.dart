import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:swifty_companion/services/api_exception.dart';
import 'package:swifty_companion/services/auth_service.dart';
import 'package:swifty_companion/services/user_service.dart';

import 'matchers.dart';

const _userJson = {
  'login': 'jdoe',
  'displayname': 'John Doe',
  'email': 'jdoe@student.42.fr',
  'correction_point': 5,
  'wallet': 100,
  'location': null,
  'image': {'link': 'https://cdn.intra.42.fr/users/jdoe.jpeg'},
  'cursus_users': [
    {
      'level': 7.65,
      'cursus': {'id': 9, 'name': 'C Piscine'},
      'skills': [],
    },
    {
      'level': 11.25,
      'cursus': {'id': 21, 'name': '42cursus'},
      'skills': [
        {'name': 'Rigor', 'level': 7.65},
      ],
    },
  ],
  'projects_users': [
    {
      'final_mark': 125,
      'status': 'finished',
      'validated?': true,
      'cursus_ids': [21],
      'project': {'name': 'libft'},
    },
    {
      'final_mark': 0,
      'status': 'finished',
      'validated?': false,
      'cursus_ids': [21],
      'project': {'name': 'minishell'},
    },
    {
      'final_mark': null,
      'status': 'in_progress',
      'validated?': null,
      'cursus_ids': [21],
      'project': {'name': 'philosophers'},
    },
  ],
};

UserService _service(http.Response Function(http.Request) handler) {
  final client = MockClient((request) async => handler(request));
  return UserService(
    auth: AuthService(
      clientId: 'id',
      clientSecret: 'secret',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'access_token': 'tok', 'expires_in': 7200}),
          200,
        ),
      ),
    ),
    client: client,
  );
}

void main() {
  test('pide /v2/users/:login con el token y construye el modelo', () async {
    late http.Request sent;
    final users = _service((request) {
      sent = request;
      return http.Response(jsonEncode(_userJson), 200);
    });

    final user = await users.fetchUser('jdoe');

    expect(sent.url.toString(), 'https://api.intra.42.fr/v2/users/jdoe');
    expect(sent.headers['Authorization'], 'Bearer tok');
    expect(user.displayName, 'John Doe');
    expect(user.location, isNull);
    expect(user.mainCursus!.name, '42cursus');
    expect(user.mainCursus!.skills.single.percent, 65);
    expect(user.projects.map((p) => p.validated), [true, false, null]);
    expect(user.projects.last.finalMark, isNull);
  });

  test('404 lanza ApiError.notFound', () async {
    final users = _service((_) => http.Response('{}', 404));

    expect(users.fetchUser('nadie'), throwsApiError(ApiError.notFound));
  });

  test('401 lanza ApiError.unauthorized y pide otro token después', () async {
    var tokens = 0;
    var status = 401;
    final users = UserService(
      auth: AuthService(
        clientId: 'id',
        clientSecret: 'secret',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'access_token': 'tok${++tokens}', 'expires_in': 7200}),
            200,
          ),
        ),
      ),
      client: MockClient(
        (_) async => http.Response(jsonEncode(_userJson), status),
      ),
    );

    await expectLater(
      users.fetchUser('jdoe'),
      throwsApiError(ApiError.unauthorized),
    );
    status = 200;
    await users.fetchUser('jdoe');
    expect(tokens, 2);
  });

  test('429 lanza ApiError.rateLimited', () async {
    final users = _service((_) => http.Response('{}', 429));

    expect(users.fetchUser('jdoe'), throwsApiError(ApiError.rateLimited));
  });

  test('5xx lanza ApiError.server', () async {
    final users = _service((_) => http.Response('{}', 500));

    expect(users.fetchUser('jdoe'), throwsApiError(ApiError.server));
  });

  test('sin red lanza ApiError.network', () async {
    final users = _service((_) => throw http.ClientException('sin red'));

    expect(users.fetchUser('jdoe'), throwsApiError(ApiError.network));
  });

  test('JSON inesperado lanza ApiError.badResponse', () async {
    final users = _service((_) => http.Response('[1, 2]', 200));

    expect(users.fetchUser('jdoe'), throwsApiError(ApiError.badResponse));
  });

  test('JSON sin campos obligatorios lanza ApiError.badResponse', () async {
    final users = _service((_) => http.Response('{"login": 42}', 200));

    expect(users.fetchUser('jdoe'), throwsApiError(ApiError.badResponse));
  });

  test('un fallo del token llega como ApiException', () async {
    final users = UserService(
      auth: AuthService(
        clientId: 'id',
        clientSecret: 'mal',
        client: MockClient((_) async => http.Response('{}', 401)),
      ),
      client: MockClient((_) async => http.Response('{}', 200)),
    );

    expect(users.fetchUser('jdoe'), throwsApiError(ApiError.credentials));
  });
}
