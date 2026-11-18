import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/army.dart';
import '../data/models/building.dart';
import '../data/models/difficulty.dart';
import '../data/models/game_modifier.dart';
import '../data/models/victory_condition.dart';
import '../data/models/geo_coordinate.dart';
import '../data/models/nationality.dart';
import '../data/models/player_character.dart';
import '../data/models/resource.dart';
import '../data/models/trade_good.dart';
import '../data/models/unit.dart';
import '../data/models/unit_type.dart';
import 'game_manager.dart';

class SaveEngine {
  static const _saveKey = 'game_save_v1';

  static Future<bool> hasSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_saveKey);
  }

  static Future<void> deleteSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }

  static Future<void> saveGame(GameManager game) async {
    if (!game.gameStarted || game.playerCharacter == null) return;

    final data = <String, dynamic>{
      'nationalityId': game.playerNationality?.id,
      'difficulty': game.difficulty?.name,
      'victoryType': game.selectedVictoryType?.name,
      'achievedVictoryType': game.achievedVictoryType?.name,
      'modifiers': game.activeModifiers.map((m) => m.name).toList(),
      'visionRangeKm': game.visionRangeKm,
      'currentTurn': game.currentTurn,
      'battlesWon': game.battlesWon.map((k, v) => MapEntry(k, v)),
      'battlesLost': game.battlesLost,
      'peakGold': game.peakGold,
      'peakVillageCount': game.peakVillageCount,
      'capitalVillageId': game.capitalVillageId,
      'playerCharacter': game.playerCharacter!.toJson(),
      'villages': _serializeVillages(game),
      'armies': _serializeArmies(game),
      'tickCount': game.gameLoop.tickCount,
      'discoveredVillageIds': game.discoveredVillageIDs.toList(),
      'marketPressure': game.marketPressure.map((id, city) => MapEntry(id, city.map((g, v) => MapEntry(g.name, v)))),
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saveKey, json.encode(data));
  }

  static Future<bool> loadGame(GameManager game) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw == null) return false;

    try {
      final data = json.decode(raw) as Map<String, dynamic>;
      return _restoreGame(game, data);
    } catch (e) {
      return false;
    }
  }

  static bool _restoreGame(GameManager game, Map<String, dynamic> data) {
    final natId = data['nationalityId'] as String?;
    if (natId == null) return false;

    Nationality? nationality;
    for (final n in Nationality.getAll()) {
      if (n.id == natId) { nationality = n; break; }
    }
    if (nationality == null) return false;

    // Rebuild the map from scratch with the saved nationality
    game.setupGame(nationality);
    game.difficulty = Difficulty.values.where((d) => d.name == data['difficulty']).firstOrNull ?? game.difficulty;
    game.selectedVictoryType = VictoryType.values.where((v) => v.name == data['victoryType']).firstOrNull ?? game.selectedVictoryType;
    game.achievedVictoryType = VictoryType.values.where((v) => v.name == data['achievedVictoryType']).firstOrNull ?? game.achievedVictoryType;
    if (data['modifiers'] is List) {
      game.activeModifiers = (data['modifiers'] as List).map((name) => GameModifier.values.where((m) => m.name == name).firstOrNull).whereType<GameModifier>().toSet();
    }
    game.visionRangeKm = (data['visionRangeKm'] as num?)?.toDouble() ?? game.visionRangeKm;

    // Restore turn state
    game.currentTurn = data['currentTurn'] as int? ?? 1;
    game.battlesLost = data['battlesLost'] as int? ?? 0;
    game.peakGold = data['peakGold'] as int? ?? 0;
    game.peakVillageCount = data['peakVillageCount'] as int? ?? 0;

    final battlesWonMap = data['battlesWon'] as Map<String, dynamic>?;
    if (battlesWonMap != null) {
      game.battlesWon = battlesWonMap.map((k, v) => MapEntry(k, v as int));
    }

    // Restore village states
    final villagesData = data['villages'] as List<dynamic>? ?? [];
    _restoreVillages(game, villagesData);

    // setupGame gave every city a new random id. Everything saved that points at a city
    // (army positions, the character's place and trips, missions) holds the old one.
    final ids = _newIdsBySavedId(game, villagesData);
    for (final id in data['discoveredVillageIds'] as List<dynamic>? ?? <dynamic>[]) {
      final mapped = ids['$id'] ?? '$id';
      if (game.getVillageById(mapped) != null) game.discoveredVillageIDs.add(mapped);
    }
    final pressure = _remapIds(data['marketPressure'], ids) as Map<String, dynamic>? ?? {};
    for (final city in pressure.entries) {
      for (final g in (city.value as Map<String, dynamic>).entries) {
        final good = TradeGood.values.where((t) => t.name == g.key).firstOrNull;
        if (good != null) game.marketPressure.putIfAbsent(city.key, () => {})[good] = (g.value as num).toDouble();
      }
    }

    // Clear auto-generated armies and restore saved ones
    game.armies.clear();
    _restoreArmies(game, _remapIds(data['armies'], ids) as List<dynamic>? ?? []);

    // Restore player character
    final pcJson = _remapIds(data['playerCharacter'], ids) as Map<String, dynamic>?;
    if (pcJson != null) {
      final pc = PlayerCharacter.fromJson(pcJson);
      game.playerCharacter = pc;
      if (game.playerWarband == null) pc.warbandId = _oldSaveWarband(game, pc)?.id;
    }
    final capital = data['capitalVillageId'] as String?;
    if (capital != null) game.capitalVillageId = ids[capital] ?? capital;

    // Mark game as started and wire callbacks
    game.gameStarted = true;
    game.syncGlobalResources();
    game.gameLoop.onTick = game.onGameTickCallback;
    game.gameLoop.onArrival = game.onPlayerArrivalCallback;
    game.gameLoop.tickCount = data['tickCount'] as int? ?? 0;
    if (game.playerCharacter?.state == PlayerState.traveling) game.gameLoop.start();

    game.refreshUI();
    return true;
  }

  /// A save from before the warband had an id: the old rule took the first player army where the
  /// character stood, which was often the city's own army. Take the smallest one there instead.
  static Army? _oldSaveWarband(GameManager game, PlayerCharacter pc) {
    final here = pc.currentCityId;
    final candidates = game.armies
        .where((a) => a.owner == 'player' && (here == null ? a.stationedAt == null : a.stationedAt == here))
        .toList()
      ..sort((a, b) => a.unitCount.compareTo(b.unitCount));
    return candidates.firstOrNull;
  }

  // --- Village Serialization ---

  /// Saved city id -> the id the same city (matched by name) has in the rebuilt map.
  /// A save from before ids were written has none, and its references stay as they were.
  static Map<String, String> _newIdsBySavedId(GameManager game, List<dynamic> villagesData) {
    final ids = <String, String>{};
    for (final vData in villagesData) {
      final map = vData as Map<String, dynamic>;
      final savedId = map['id'] as String?;
      final village = game.getVillage(map['name'] as String);
      if (savedId != null && village != null) ids[savedId] = village.id;
    }
    return ids;
  }

  /// [node] with every string that is a saved city id swapped for its new id, keys included.
  static dynamic _remapIds(dynamic node, Map<String, String> ids) {
    if (node is String) return ids[node] ?? node;
    if (node is List) return node.map((e) => _remapIds(e, ids)).toList();
    if (node is Map) {
      // JSON keys are strings; the result must stay a Map<String, dynamic> for the casts that follow.
      return <String, dynamic>{
        for (final e in node.entries) ids['${e.key}'] ?? '${e.key}': _remapIds(e.value, ids),
      };
    }
    return node;
  }

  static List<Map<String, dynamic>> _serializeVillages(GameManager game) {
    return game.map.villages.map((v) => {
      'id': v.id,
      'name': v.name,
      'owner': v.owner,
      'garrisonStrength': v.garrisonStrength,
      'garrisonMaxStrength': v.garrisonMaxStrength,
      'population': v.population,
      'happiness': v.happiness,
      'underSiege': v.underSiege,
      'resources': v.resources.map((k, val) => MapEntry(k.name, val)),
      'buildings': v.buildings.map((b) => {
        'name': b.name,
        'level': b.level,
      }).toList(),
    }).toList();
  }

  static void _restoreVillages(GameManager game, List<dynamic> villagesData) {
    for (final vData in villagesData) {
      final map = vData as Map<String, dynamic>;
      final name = map['name'] as String;
      final village = game.getVillage(name);
      if (village == null) continue;

      village.owner = map['owner'] as String? ?? village.owner;
      village.garrisonStrength = map['garrisonStrength'] as int? ?? village.garrisonStrength;
      village.garrisonMaxStrength = map['garrisonMaxStrength'] as int? ?? village.garrisonMaxStrength;
      village.population = map['population'] as int? ?? village.population;
      village.happiness = map['happiness'] as int? ?? village.happiness;
      village.underSiege = map['underSiege'] as bool? ?? false;

      // Restore resources
      final resMap = map['resources'] as Map<String, dynamic>?;
      if (resMap != null) {
        village.resources.clear();
        for (final entry in resMap.entries) {
          final res = Resource.values.where((r) => r.name == entry.key).firstOrNull;
          if (res != null) village.resources[res] = entry.value as int;
        }
      }

      // Restore buildings (match by name, update level)
      final buildingsData = map['buildings'] as List<dynamic>?;
      if (buildingsData != null) {
        // Build lookup from saved data
        final savedLevels = <String, int>{};
        for (final bData in buildingsData) {
          final bMap = bData as Map<String, dynamic>;
          savedLevels[bMap['name'] as String] = bMap['level'] as int? ?? 1;
        }

        // Update existing buildings or add missing ones
        final existingNames = village.buildings.map((b) => b.name).toSet();
        for (final b in village.buildings) {
          if (savedLevels.containsKey(b.name)) {
            b.level = savedLevels[b.name]!;
          }
        }
        // Add buildings that exist in save but not in village
        for (final entry in savedLevels.entries) {
          if (!existingNames.contains(entry.key)) {
            final template = _getBuildingTemplate(entry.key);
            if (template != null) {
              village.buildings.add(template.copyWith(level: entry.value));
            }
          }
        }
      }
    }
  }

  static Building? _getBuildingTemplate(String name) {
    final templates = [
      Building.farm, Building.lumberMill, Building.ironMine,
      Building.market, Building.barracks, Building.archeryRange,
      Building.stables, Building.fortress,
    ];
    for (final t in templates) {
      if (t.name == name) return t;
    }
    return null;
  }

  // --- Army Serialization ---

  static List<Map<String, dynamic>> _serializeArmies(GameManager game) {
    return game.armies.map((a) => {
      'id': a.id,
      'name': a.name,
      'owner': a.owner,
      'stationedAt': a.stationedAt,
      'destination': a.destination,
      'turnsUntilArrival': a.turnsUntilArrival,
      'origin': a.origin,
      'state': a.state.name,
      'siegeTurns': a.siegeTurns,
      'units': a.units.map((u) => _serializeUnit(u)).toList(),
    }).toList();
  }

  static Map<String, dynamic> _serializeUnit(Unit u) => {
    'id': u.id,
    'unitType': u.unitType.name,
    'owner': u.owner,
    'currentHP': u.currentHP,
    'maxHP': u.maxHP,
    'attack': u.attack,
    'defense': u.defense,
    'level': u.level,
    'experience': u.experience,
    'morale': u.morale,
    'bonusAttack': u.bonusAttack,
    'bonusDefense': u.bonusDefense,
  };

  static void _restoreArmies(GameManager game, List<dynamic> armiesData) {
    for (final aData in armiesData) {
      final map = aData as Map<String, dynamic>;
      final unitsData = map['units'] as List<dynamic>? ?? [];

      final units = <Unit>[];
      for (final uData in unitsData) {
        final uMap = uData as Map<String, dynamic>;
        final unitType = UnitType.values.where((t) => t.name == uMap['unitType']).firstOrNull;
        if (unitType == null) continue;

        units.add(Unit(
          id: uMap['id'] as String?,
          name: unitType.stats.name,
          unitType: unitType,
          attack: uMap['attack'] as int? ?? unitType.stats.attack,
          defense: uMap['defense'] as int? ?? unitType.stats.defense,
          maxHP: uMap['maxHP'] as int? ?? unitType.stats.hp,
          currentHP: uMap['currentHP'] as int? ?? unitType.stats.hp,
          movement: unitType.stats.movement,
          movementRemaining: unitType.stats.movement,
          level: uMap['level'] as int? ?? 1,
          experience: uMap['experience'] as int? ?? 0,
          morale: uMap['morale'] as int? ?? 100,
          owner: uMap['owner'] as String? ?? 'player',
          coordinates: const GeoCoordinate(0, 0),
          bonusAttack: uMap['bonusAttack'] as int? ?? 0,
          bonusDefense: uMap['bonusDefense'] as int? ?? 0,
        ));
      }

      if (units.isEmpty) continue;

      final stateStr = map['state'] as String? ?? 'stationed';
      final army = Army(
        id: map['id'] as String?,
        name: map['name'] as String? ?? 'Army',
        units: units,
        owner: map['owner'] as String? ?? 'player',
        stationedAt: map['stationedAt'] as String?,
        destination: map['destination'] as String?,
        turnsUntilArrival: map['turnsUntilArrival'] as int? ?? 0,
        origin: map['origin'] as String?,
        state: ArmyState.values.firstWhere(
          (s) => s.name == stateStr,
          orElse: () => ArmyState.stationed,
        ),
        siegeTurns: map['siegeTurns'] as int? ?? 0,
      );
      game.armies.add(army);
    }
  }
}
