import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/data/models/player_character.dart';
import 'package:villages_town/data/models/victory_condition.dart';
import 'package:villages_town/engines/game_manager.dart';
import 'package:villages_town/engines/progression_engine.dart';
import 'package:villages_town/engines/save_engine.dart';
import 'package:villages_town/providers/game_provider.dart';
import 'package:villages_town/ui/screens/game_view_rts.dart';

class RejectingStore extends InMemorySharedPreferencesStore {
  RejectingStore(this.target, this.throwsError) : super.empty();
  final String target;
  final bool throwsError;
  bool rejected = false;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final match = switch (target) {
      'snapshot' => key.endsWith('game_save_v1') && !value.toString().contains('"gameEndRecorded":true'),
      'marker' => key.endsWith('game_save_v1') && value.toString().contains('"gameEndRecorded":true'),
      'record' => key.endsWith('game_records'),
      _ => key.endsWith('unlocked_achievements'),
    };
    if (match && !rejected) {
      rejected = true;
      if (throwsError) throw StateError('rejected');
      return false;
    }
    return super.setValue(valueType, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('phone victory records the game once across mounts', (tester) async {
    final game = GameManager.shared..resetGame();
    game.setupGame(Nationality.ottomans);
    game.gameStarted = true;
    game.playerCharacter = PlayerCharacter(name: 'Test', currentCityId: game.map.villages.first.id);
    game.achievedVictoryType = VictoryType.economic;
    Widget view() => ChangeNotifierProvider(create: (_) => GameProvider(), child: const MaterialApp(home: RtsGameView()));
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    expect(await ProgressionEngine.getGameRecords(), hasLength(1));
    expect(await ProgressionEngine.getUnlockedAchievements(), contains('economicVictor'));
    await tester.pumpWidget(const SizedBox());
    game.resetGame();
    await tester.pump(const Duration(seconds: 5));
  });

  for (final target in ['snapshot', 'record', 'achievements', 'marker']) {
    for (final throwsError in [false, true]) {
      testWidgets('$target rejects ${throwsError ? "with error" : "with false"} and retries', (tester) async {
        final store = RejectingStore(target, throwsError);
        SharedPreferencesStorePlatform.instance = store;
        await (await SharedPreferences.getInstance()).reload();
        final game = GameManager.shared..resetGame();
        game.setupGame(Nationality.ottomans);
        game.gameStarted = true;
        game.playerCharacter = PlayerCharacter(name: 'Test', currentCityId: game.map.villages.first.id);
        game.achievedVictoryType = VictoryType.economic;
        final id = game.campaignId;
        Widget view() => ChangeNotifierProvider(create: (_) => GameProvider(), child: const MaterialApp(home: RtsGameView()));
        await tester.pumpWidget(view());
        expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Play Again')).onPressed, isNull);
        await tester.pumpAndSettle();
        expect(find.text('Couldn’t save this result.'), findsOneWidget);
        expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Play Again')).onPressed, isNull);
        if (target == 'marker') {
          await tester.pumpWidget(const SizedBox());
          await (await SharedPreferences.getInstance()).reload();
          expect(await SaveEngine.loadGame(game), isTrue);
          expect(game.campaignId, id);
          expect(game.gameEndRecorded, isFalse);
          await tester.pumpWidget(view());
        } else {
          await tester.tap(find.text('Try Again'));
        }
        await tester.pumpAndSettle();
        expect(game.gameEndRecorded, isTrue);
        expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Play Again')).onPressed, isNotNull);
        expect((await ProgressionEngine.getGameRecords()).where((r) => r.campaignId == id), hasLength(1));
        expect(await ProgressionEngine.getUnlockedAchievements(), contains('economicVictor'));
        await tester.pumpWidget(const SizedBox());
        game.resetGame();
        await tester.pump(const Duration(seconds: 5));
      });
    }
  }
}
