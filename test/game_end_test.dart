import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/data/models/player_character.dart';
import 'package:villages_town/data/models/victory_condition.dart';
import 'package:villages_town/engines/game_manager.dart';
import 'package:villages_town/engines/progression_engine.dart';
import 'package:villages_town/providers/game_provider.dart';
import 'package:villages_town/ui/screens/game_view_rts.dart';

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
  });
}
