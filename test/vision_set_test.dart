import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:villages_town/data/models/army.dart';
import 'package:villages_town/data/models/geo_coordinate.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/data/models/unit.dart';
import 'package:villages_town/data/models/unit_type.dart';
import 'package:villages_town/engines/game_manager.dart';

GameManager freshGame() {
  final game = GameManager.shared..resetGame();
  game.setupGame(Nationality.ottomans);
  game.initializeGame(characterName: 'Test');
  game.map.villages.firstWhere((v) => v.owner == 'neutral').owner = 'player';
  return game;
}

Army stationArmy(GameManager game, String villageId, UnitType type, {String owner = 'player'}) {
  final army = Army(
    name: 'Guard',
    owner: owner,
    stationedAt: villageId,
    units: [Unit.create(type, owner, const GeoCoordinate(0, 0))],
  );
  game.armies.add(army);
  return army;
}

void expectSameVisibility(GameManager game, String playerId) {
  final inVision = game.villageIdsInVisionRange(playerId);
  for (final village in game.map.villages) {
    final savedIds = Set<String>.from(game.discoveredVillageIDs);
    final savedCache = Map<String, DiscoveredVillageInfo>.from(game.discoveredVillageCache);

    final oldVisible = game.isVillageVisible(village, playerId);
    final oldIds = Set<String>.from(game.discoveredVillageIDs);
    final oldCache = Map<String, DiscoveredVillageInfo>.from(game.discoveredVillageCache);

    game.discoveredVillageIDs = savedIds;
    game.discoveredVillageCache = savedCache;

    final newVisible = game.isVillageVisibleInVision(village, playerId, inVision);

    expect(newVisible, oldVisible, reason: village.name);
    expect(game.discoveredVillageIDs, oldIds, reason: village.name);
    expect(game.discoveredVillageCache.keys.toSet(), oldCache.keys.toSet(), reason: village.name);
    for (final entry in oldCache.entries) {
      final now = game.discoveredVillageCache[entry.key]!;
      expect(now.owner, entry.value.owner, reason: village.name);
      expect(now.garrisonEstimate, entry.value.garrisonEstimate, reason: village.name);
      expect(now.turnSeen, entry.value.turnSeen, reason: village.name);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the vision set matches isVillageInVisionRange for every village', () {
    final game = freshGame();

    final inVision = game.villageIdsInVisionRange('player');
    for (final village in game.map.villages) {
      expect(
        inVision.contains(village.id),
        game.isVillageInVisionRange(village, 'player'),
        reason: village.name,
      );
    }
  });

  test('set-based visibility matches the per-village path including armies and cavalry', () {
    final game = freshGame();
    final owned = game.getPlayerVillages('player').first;
    final far = game.map.villages
        .where((v) => v.owner != 'player')
        .reduce((a, b) => GeoCoordinate.distanceKm(owned.coordinates, a.coordinates) >
                GeoCoordinate.distanceKm(owned.coordinates, b.coordinates)
            ? a
            : b);

    expectSameVisibility(game, 'player');

    stationArmy(game, owned.id, UnitType.militia);
    expectSameVisibility(game, 'player');
    expect(game.isVillageVisibleInVision(far, 'player', game.villageIdsInVisionRange('player')),
        game.isVillageVisible(far, 'player'));

    stationArmy(game, owned.id, UnitType.lightCavalry);
    final withCavalry = game.villageIdsInVisionRange('player');
    expectSameVisibility(game, 'player');
    for (final village in game.map.villages) {
      expect(
        withCavalry.contains(village.id),
        game.isVillageInVisionRange(village, 'player'),
        reason: village.name,
      );
    }

    final discovered = game.map.villages.firstWhere((v) => v.owner != 'player');
    game.discoveredVillageIDs.add(discovered.id);
    game.discoveredVillageCache[discovered.id] =
        const DiscoveredVillageInfo(owner: 'neutral', garrisonEstimate: 5, turnSeen: 1);
    game.visionRangeKm = 0;
    game.armies.clear();
    expectSameVisibility(game, 'player');
    expect(game.isVillageVisibleInVision(discovered, 'player', game.villageIdsInVisionRange('player')),
        isTrue);
  });

  test('ownership and army changes update the set-based result', () {
    final game = freshGame();
    final owned = game.getPlayerVillages('player').first;
    final outside = game.map.villages.firstWhere(
      (v) =>
          v.owner != 'player' &&
          GeoCoordinate.distanceKm(owned.coordinates, v.coordinates) > game.visionRangeKm + 250,
    );
    final inVision = game.villageIdsInVisionRange('player');
    expect(inVision.contains(outside.id), isFalse);
    expect(game.isVillageVisibleInVision(outside, 'player', inVision), isFalse);

    outside.owner = 'player';
    final afterOwnership = game.villageIdsInVisionRange('player');
    expect(afterOwnership.contains(outside.id), isTrue);
    expect(game.isVillageVisibleInVision(outside, 'player', afterOwnership), isTrue);

    outside.owner = 'enemy';
    final enemyOwned = game.villageIdsInVisionRange('player');
    expect(enemyOwned.contains(outside.id), isFalse);
    expect(
      game.isVillageVisibleInVision(outside, 'player', enemyOwned),
      game.discoveredVillageIDs.contains(outside.id),
    );

    final watchtower = game.map.villages.firstWhere(
      (v) => v.owner != 'player' && !enemyOwned.contains(v.id),
    );
    stationArmy(game, watchtower.id, UnitType.militia);
    final withArmy = game.villageIdsInVisionRange('player');
    for (final village in game.map.villages) {
      if (village.owner == 'player') continue;
      if (GeoCoordinate.distanceKm(watchtower.coordinates, village.coordinates) <= game.visionRangeKm) {
        expect(withArmy.contains(village.id), isTrue, reason: village.name);
      }
    }
    expect(withArmy.difference(enemyOwned), isNotEmpty);
    game.armies.clear();
    expect(game.villageIdsInVisionRange('player'), enemyOwned);
  });
}
