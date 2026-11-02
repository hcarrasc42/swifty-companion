import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swifty_companion/main.dart';
import 'package:swifty_companion/models/user.dart';
import 'package:swifty_companion/services/auth_service.dart';
import 'package:swifty_companion/services/user_service.dart';

/// Servicio falso: devuelve un usuario sin tocar la red.
class _FakeUserService extends UserService {
  _FakeUserService()
    : super(
        auth: AuthService(clientId: '', clientSecret: ''),
      );

  @override
  Future<User> fetchUser(String login) async => User(
    login: login,
    displayName: 'Perfil de $login',
    email: '',
    correctionPoints: 0,
    wallet: 0,
    cursus: const [],
    projects: const [],
  );
}

void main() {
  testWidgets('muestra error si el login está vacío', (tester) async {
    await tester.pumpWidget(MyApp(users: _FakeUserService()));

    await tester.tap(find.text('Buscar'));
    await tester.pump();

    expect(find.text('Escribe un login'), findsOneWidget);
  });

  testWidgets('muestra error si el login tiene caracteres inválidos', (
    tester,
  ) async {
    await tester.pumpWidget(MyApp(users: _FakeUserService()));

    await tester.enterText(find.byType(TextField), 'hola mundo!');
    await tester.tap(find.text('Buscar'));
    await tester.pump();

    expect(find.text('Solo letras, números, "-" y "_"'), findsOneWidget);
  });

  testWidgets('navega al perfil con el login y vuelve atrás', (tester) async {
    await tester.pumpWidget(MyApp(users: _FakeUserService()));

    await tester.enterText(find.byType(TextField), '  Hcarrasc ');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    expect(find.text('Perfil de hcarrasc'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Perfil de hcarrasc'), findsNothing);
    expect(find.text('Buscar'), findsOneWidget);
  });
}
