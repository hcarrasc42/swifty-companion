import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swifty_companion/main.dart';

import 'fake_user_service.dart';

void main() {
  testWidgets('muestra error si el login está vacío', (tester) async {
    await tester.pumpWidget(MyApp(users: FakeUserService()));

    await tester.tap(find.text('Buscar'));
    await tester.pump();

    expect(find.text('Escribe un login'), findsOneWidget);
  });

  testWidgets('muestra error si el login tiene caracteres inválidos', (
    tester,
  ) async {
    await tester.pumpWidget(MyApp(users: FakeUserService()));

    await tester.enterText(find.byType(TextField), 'hola mundo!');
    await tester.tap(find.text('Buscar'));
    await tester.pump();

    expect(find.text('Solo letras, números, "-" y "_"'), findsOneWidget);
  });

  testWidgets('móvil en horizontal con el teclado abierto: sin overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(740, 360);
    tester.view.devicePixelRatio = 1;
    // El teclado ocupa la parte de abajo: quedan ~100 px para el formulario.
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MyApp(users: FakeUserService()));
    await tester.pumpAndSettle();

    // Con scroll, el botón se alcanza aunque no quepa a la vista.
    await tester.ensureVisible(find.text('Buscar'));
    expect(find.text('Buscar'), findsOneWidget);
  });

  testWidgets('navega al perfil con el login y vuelve atrás', (tester) async {
    await tester.pumpWidget(MyApp(users: FakeUserService()));

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
