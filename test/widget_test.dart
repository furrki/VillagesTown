import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:villages_town/main.dart';
import 'package:villages_town/providers/game_provider.dart';

void main() {
  testWidgets('creation back controls preserve the name and allow starting', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = GameProvider();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const VillagesTownApp(),
    ));
    await tester.pumpAndSettle();

    Future<void> startNaming() async {
      await tester.tap(find.text('Ottomans'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('START CONQUEST'));
      await tester.tap(find.text('START CONQUEST'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    }

    await startNaming();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('CHOOSE YOUR EMPIRE'), findsOneWidget);
    await startNaming();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('CHOOSE YOUR EMPIRE'), findsOneWidget);
    await startNaming();
    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.pumpAndSettle();
    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    expect(find.text('YOUR STORY'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Alex');
    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Alex');
    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exiled Noble'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BEGIN JOURNEY'));
    await tester.pump();
    expect(provider.gameManager.gameStarted, isTrue);
  });

  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GameProvider(),
        child: const VillagesTownApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('CHOOSE YOUR EMPIRE'), findsOneWidget);
  });
}
