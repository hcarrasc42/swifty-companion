import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swifty_companion/models/user.dart';
import 'package:swifty_companion/screens/profile_screen.dart';
import 'package:swifty_companion/services/api_exception.dart';

import 'fake_user_service.dart';

const _user = User(
  login: 'jdoe',
  displayName: 'John Doe',
  email: 'jdoe@student.42.fr',
  correctionPoints: 5,
  wallet: 120,
  cursus: [
    Cursus(
      id: 9,
      name: 'C Piscine',
      level: 9.5,
      skills: [Skill(name: 'Unix', level: 4.2)],
    ),
    Cursus(
      id: 21,
      name: '42cursus',
      level: 7.65,
      skills: [Skill(name: 'Algorithms & AI', level: 5.3)],
    ),
  ],
  projects: [
    ProjectUser(
      name: 'Libft',
      status: 'finished',
      cursusIds: [21],
      finalMark: 125,
      validated: true,
    ),
    ProjectUser(
      name: 'push_swap',
      status: 'finished',
      cursusIds: [21],
      finalMark: 0,
      validated: false,
    ),
    ProjectUser(name: 'minishell', status: 'in_progress', cursusIds: [21]),
    ProjectUser(
      name: 'C Piscine Shell 00',
      status: 'finished',
      cursusIds: [9],
      finalMark: 100,
      validated: true,
    ),
  ],
);

Future<void> _pumpProfile(WidgetTester tester) async {
  // Pantalla alta para que el ListView construya todo el contenido.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: ProfileScreen(login: 'jdoe', users: FakeUserService(_user)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra los datos, el nivel y las skills del cursus principal', (
    tester,
  ) async {
    await _pumpProfile(tester);

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('jdoe@student.42.fr'), findsOneWidget);
    expect(find.text('Fuera del campus'), findsOneWidget);
    expect(find.text('120 ₳'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Nivel 7 · 65 %'), findsOneWidget);
    expect(find.text('Algorithms & AI'), findsOneWidget);
    expect(find.text('Nivel 5 · 30 %'), findsOneWidget);
    expect(find.text('Unix'), findsNothing);
  });

  testWidgets('muestra los proyectos del cursus, suspendidos incluidos', (
    tester,
  ) async {
    await _pumpProfile(tester);

    expect(find.text('Proyectos (3)'), findsOneWidget);
    expect(find.text('Libft'), findsOneWidget);
    expect(find.text('125'), findsOneWidget);
    expect(find.text('push_swap'), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(find.text('En curso'), findsOneWidget);
    expect(find.text('C Piscine Shell 00'), findsNothing);
  });

  testWidgets('login inexistente: mensaje y botón para volver', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          login: 'nadie',
          users: FakeUserService(null, [
            const ApiException(ApiError.notFound, 'No existe "nadie"'),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No existe "nadie"'), findsOneWidget);
    expect(find.text('Volver'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('sin red: reintentar vuelve a cargar el perfil', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          login: 'jdoe',
          users: FakeUserService(_user, [
            const ApiException(ApiError.network, 'Sin conexión'),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Sin conexión'), findsNothing);
    expect(find.text('John Doe'), findsOneWidget);
  });

  testWidgets('un error que no es de la API muestra un mensaje genérico', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          login: 'jdoe',
          users: FakeUserService(null, [StateError('detalle interno')]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ha ocurrido un error inesperado'), findsOneWidget);
    expect(find.textContaining('detalle interno'), findsNothing);
  });

  testWidgets('cambia de cursus con el selector', (tester) async {
    await _pumpProfile(tester);

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('C Piscine').last);
    await tester.pumpAndSettle();

    expect(find.text('Nivel 9 · 50 %'), findsOneWidget);
    expect(find.text('Unix'), findsOneWidget);
    expect(find.text('Proyectos (1)'), findsOneWidget);
    expect(find.text('C Piscine Shell 00'), findsOneWidget);
    expect(find.text('Libft'), findsNothing);
  });
}
