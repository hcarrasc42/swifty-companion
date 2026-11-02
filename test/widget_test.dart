import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swifty_companion/main.dart';

void main() {
  testWidgets('muestra error si el login está vacío', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Buscar'));
    await tester.pump();

    expect(find.text('Escribe un login'), findsOneWidget);
  });

  testWidgets('muestra error si el login tiene caracteres inválidos', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.enterText(find.byType(TextField), 'hola mundo!');
    await tester.tap(find.text('Buscar'));
    await tester.pump();

    expect(find.text('Solo letras, números, "-" y "_"'), findsOneWidget);
  });
}
