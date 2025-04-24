import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:la_pause_clope/pages/nickname_page.dart';

import 'nickname_page_test.mocks.dart';

@GenerateMocks([NavigatorObserver])
void main() {
  late MockNavigatorObserver mockObserver;

  setUp(() {
    mockObserver = MockNavigatorObserver();
  });

  testWidgets('Navigue vers ClickerPage si un nom est saisi', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const NicknamePage(),
        navigatorObservers: [mockObserver],
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'TestUser');
    await tester.tap(find.text('Commençons le jeux !'));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    // Vérifie qu’une navigation a eu lieu
    verify(
      mockObserver.didReplace(
        newRoute: anyNamed('newRoute'),
        oldRoute: anyNamed('oldRoute'),
      ),
    ).called(1);
  });
}
