// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pause_clope/pages/nickname_page.dart';

void main() {
  testWidgets('NicknamePage affiche le champ et le bouton', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: NicknamePage()));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Commençons le jeux !'), findsOneWidget);
    expect(find.text('Entrez votre nom de joueur'), findsOneWidget);
  });

  testWidgets('Navigue vers ClickerPage si un nom est saisi', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: NicknamePage()));

    // Entrer un pseudo
    await tester.enterText(find.byType(TextField), 'TestUser');

    // Lancer le bouton
    await tester.tap(find.text('Commençons le jeux !'));
    await tester.pump(); // lancement animations
    await tester.pump(
      const Duration(milliseconds: 1300),
    ); // laisser les animations se finir

    // Vérifie qu’on a navigué vers une autre page
    expect(
      find.byType(NicknamePage),
      findsNothing,
    ); // n’est plus sur NicknamePage
  });
}
