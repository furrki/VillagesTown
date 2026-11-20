import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The legacy SharedPreferences API has no public setter for its test backend.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/data/models/player_character.dart';
import 'package:villages_town/engines/game_loop.dart';
import 'package:villages_town/engines/game_manager.dart';
import 'package:villages_town/engines/save_engine.dart';
import 'package:villages_town/main.dart';
import 'package:villages_town/ui/screens/game_view_rts.dart';

class CampaignStore extends InMemorySharedPreferencesStore {
  CampaignStore() : super.empty();

  Future<bool> Function()? acceptWrite;
  final attemptedTurns = <int>[];

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    attemptedTurns.add(jsonDecode(value as String)['currentTurn'] as int);
    if (!(await acceptWrite?.call() ?? true)) return false;
    return super.setValue(valueType, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CampaignStore store;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = CampaignStore();
    SharedPreferencesStorePlatform.instance = store;
  });

  GameManager started() {
    final game = GameManager.shared..resetGame();
    game.setupGame(Nationality.ottomans);
    game.gameStarted = true;
    game.playerCharacter = PlayerCharacter(
      name: 'Test',
      currentCityId: game.map.villages.first.id,
    );
    return game;
  }

  test('immediate menu exit saves a city action', () async {
    final game = started();
    // Synchronize the treasury with the starting city stocks before spending.
    game.awardGold(1);
    expect(game.healWarband(25), isTrue);
    final gold = game.gold;
    await saveAndReturnToMenu(game);
    expect(game.gameStarted, isFalse);
    expect(await SaveEngine.loadGame(game), isTrue);
    expect(game.gold, gold);
    game.resetGame();
  });

  test('immediate menu exit saves travel progress', () async {
    final game = started();
    final pc = game.playerCharacter!;
    pc.state = PlayerState.traveling;
    pc.travelOriginId = game.map.villages.first.id;
    pc.travelDestinationId = game.map.villages[1].id;
    pc.travelProgress = 0.42;
    await saveAndReturnToMenu(game);
    expect(await SaveEngine.loadGame(game), isTrue);
    expect(game.playerCharacter!.state, PlayerState.traveling);
    expect(game.playerCharacter!.travelProgress, 0.42);
    game.resetGame();
  });

  test('failed menu exit leaves the running campaign intact', () async {
    final game = started();
    final character = game.playerCharacter;
    addTearDown(game.resetGame);
    store.acceptWrite = () async => false;

    await expectLater(saveAndReturnToMenu(game), throwsStateError);
    expect(game.gameStarted, isTrue);
    expect(game.playerCharacter, same(character));
    expect(await store.getAll(), isEmpty);
  });

  for (final source in ['city', 'travel', 'lifecycle']) {
    for (final throws in [false, true]) {
      testWidgets('$source save failure remains retryable (throws: $throws)', (
        tester,
      ) async {
        final game = started();
        final character = game.playerCharacter!;
        addTearDown(game.resetGame);
        store.acceptWrite = () async {
          if (throws) throw StateError('disk write failed');
          return false;
        };
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: CampaignSaveWarning(game: game)),
          ),
        );

        switch (source) {
          case 'city':
            game.gameLoop.pause();
            game.awardGold(1);
            expect(game.healWarband(25), isTrue);
            await tester.pump(const Duration(seconds: 2));
          case 'travel':
            game.gameLoop.speed = GameSpeed.normal;
            character.state = PlayerState.traveling;
            character.travelOriginId = game.map.villages.first.id;
            character.travelDestinationId = game.map.villages[1].id;
            character.travelTotalTicks = 100;
            // Avoid every encounter so the real travel tick always reaches its autosave.
            character.scoutingSkill = 35;
            game.gameLoop.tickCount = 10;
            game.onGameTickCallback();
          case 'lifecycle':
            handleCampaignSaveLifecycle(game, AppLifecycleState.paused);
        }
        await tester.pump();
        expect(store.attemptedTurns, hasLength(1));
        handleCampaignSaveLifecycle(game, AppLifecycleState.resumed);
        await tester.pump();
        expect(store.attemptedTurns, hasLength(2));
        expect(find.text('Could not save campaign'), findsOneWidget);
        expect(game.gameStarted, isTrue);
        expect(game.playerCharacter, same(character));

        game.currentTurn = 42;
        store.acceptWrite = null;
        await tester.tap(find.text('Retry'));
        await tester.pump();
        expect(find.text('Could not save campaign'), findsNothing);
        expect(store.attemptedTurns.last, 42);
        expect((await store.getAll()).keys, ['flutter.game_save_v1']);
        await (await SharedPreferences.getInstance()).reload();
        game.resetGame();
        expect(await SaveEngine.loadGame(game), isTrue);
        expect(game.currentTurn, 42);
        game.resetGame();
      });
    }
  }

  test(
    'queued saves wait for an older write and save the latest state',
    () async {
      final game = started();
      addTearDown(game.resetGame);
      final inFlight = Completer<bool>();
      final writing = Completer<void>();
      store.acceptWrite = () {
        if (writing.isCompleted) return Future.value(true);
        writing.complete();
        return inFlight.future;
      };
      game.currentTurn = 1;
      final oldSave = SaveEngine.saveGame(game);
      await writing.future;

      game.currentTurn = 2;
      final queuedSave = SaveEngine.saveGame(game);
      game.currentTurn = 3;
      final latestSave = SaveEngine.saveGame(game);
      await Future<void>.delayed(Duration.zero);
      expect(store.attemptedTurns, [1]);

      inFlight.complete(true);
      expect(await oldSave, isTrue);
      expect(await queuedSave, isTrue);
      expect(await latestSave, isTrue);
      expect(store.attemptedTurns, [1, 3]);
      expect((await store.getAll()).keys, ['flutter.game_save_v1']);
      await (await SharedPreferences.getInstance()).reload();
      game.resetGame();
      expect(await SaveEngine.loadGame(game), isTrue);
      expect(game.currentTurn, 3);
    },
  );
}
