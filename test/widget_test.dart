import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:villages_town/data/models/encounter.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/data/models/player_character.dart';
import 'package:villages_town/engines/game_manager.dart';
import 'package:villages_town/main.dart';
import 'package:villages_town/providers/game_provider.dart';
import 'package:villages_town/ui/panels/travel_panel.dart';
import 'package:villages_town/ui/screens/game_screen.dart';
import 'package:villages_town/ui/screens/game_view_desktop.dart';
import 'package:villages_town/ui/screens/game_view_rts.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('creation back controls preserve the name and allow starting', (tester) async {
    final provider = GameProvider();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const VillagesTownApp(),
    ));
    await tester.pumpAndSettle();

    Future<void> startNaming() async {
      await tester.tap(find.text('OTTOMANS'));
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
    expect(provider.gameManager.gameStarted, isTrue);
    await tester.pumpWidget(const SizedBox());
    provider.dispose();
    provider.gameManager.resetGame();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('native mobile keeps the character campaign when the phone rotates', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(430, 850);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final game = GameManager.shared..resetGame();
    game.setupGame(Nationality.ottomans);
    game.gameStarted = true;
    final origin = game.getPlayerVillages('player').first;
    game.playerCharacter = PlayerCharacter(name: 'Test', currentCityId: origin.id);
    final destination = game.getNeighbors(origin.id).first;
    expect(game.startTravel(destination.id), isTrue);

    final provider = GameProvider();
    Widget view() => ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: GameScreen()),
        );

    await tester.pumpWidget(view());
    await tester.pump();
    expect(find.byType(RtsGameView), findsOneWidget);
    expect(find.byType(DesktopGameView), findsNothing);
    expect(find.byType(TravelPanel), findsOneWidget);
    final state = tester.state(find.byType(RtsGameView));

    tester.view.physicalSize = const Size(850, 430);
    await tester.pump();
    expect(find.byType(RtsGameView), findsOneWidget);
    expect(find.byType(DesktopGameView), findsNothing);
    expect(tester.state(find.byType(RtsGameView)), same(state));
    expect(find.byType(TravelPanel), findsOneWidget);

    game.currentEncounter = const Encounter(
      type: EncounterType.merchant,
      narrative: 'A grain merchant waves you down.',
      choices: [
        EncounterChoice(
          label: 'Buy grain',
          outcome: EncounterChoiceOutcome.gainCargo,
          resultText: 'Bought grain',
        ),
      ],
    );
    game.notifyListeners();
    await tester.pump();
    expect(find.byType(TravelPanel), findsOneWidget);
    expect(find.text('A grain merchant waves you down.'), findsOneWidget);
    expect(find.text('Buy grain'), findsOneWidget);

    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pump();
    expect(find.byType(DesktopGameView), findsOneWidget);
    expect(find.byType(RtsGameView), findsNothing);

    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
    provider.dispose();
    game.resetGame();
    await tester.pump(const Duration(seconds: 5));
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
