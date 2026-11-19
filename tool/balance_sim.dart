// Balance simulator: plays whole games headless through the real engines and prints what a player lives through.
// Run: flutter test tool/balance_sim.dart   (RUNS=20 TICKS=900 env vars change the size)
// It is a measuring tool, not a test: it asserts nothing.
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:villages_town/data/models/battle_plan.dart';
import 'package:villages_town/data/models/building.dart';
import 'package:villages_town/data/models/character_origin.dart';
import 'package:villages_town/data/models/encounter.dart';
import 'package:villages_town/data/models/geo_coordinate.dart';
import 'package:villages_town/data/models/unit.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/data/models/player_character.dart';
import 'package:villages_town/data/models/resource.dart';
import 'package:villages_town/data/models/trade_good.dart';
import 'package:villages_town/data/models/unit_type.dart';
import 'package:villages_town/data/models/village.dart';
import 'package:villages_town/engines/building_construction_engine.dart';
import 'package:villages_town/engines/game_manager.dart';
import 'package:villages_town/engines/recruitment_engine.dart';
import 'package:villages_town/engines/trade_engine.dart';

final int runs = int.tryParse(Platform.environment['RUNS'] ?? '') ?? 12;
final int maxTicks = int.tryParse(Platform.environment['TICKS'] ?? '') ?? 900;
final bool builder = (Platform.environment['BUILD'] ?? '1') == '1';
final bool trace = Platform.environment['TRACE'] == '1';

class RunStats {
  int ticks = 0;
  bool gameOver = false;
  int encounters = 0;
  final byType = <EncounterType, int>{};
  int fights = 0, wins = 0, flees = 0, tolls = 0, killed = 0;
  int trips = 0;
  int tradeProfit = 0;
  int recruited = 0;
  int deserted = 0;
  int built = 0;
  int cityBattles = 0;
  final snapshots = <int, String>{};
  int playerCitiesEnd = 0;
  int peakWarband = 0;
  String stage = '';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('balance', () async {
    final rng = Random(7);
    final all = <RunStats>[];
    for (var r = 0; r < runs; r++) {
      final nat = Nationality.getAll()[r % Nationality.getAll().length];
      final origin = CharacterOrigin.all()[r % CharacterOrigin.all().length];
      final s = _playOne(nat, origin, rng);
      all.add(s);
      // ignore: avoid_print
      print('run $r ${nat.id}/${origin.title}: ${s.ticks} ticks, ${s.trips} trips, ${s.stage}, '
          'earned ${GameManager.shared.playerCharacter?.totalGoldEarned}, won ${s.wins}/${s.fights}, cities ${s.playerCitiesEnd}');
    }
    _report(all);
  }, timeout: const Timeout(Duration(minutes: 30)), skip: Platform.environment['ONLY'] == 'fights');

  // Trade routes: the best one-hop profit per unit from each city, before any price moves.
  test('routes', () {
    final game = GameManager.shared..resetGame();
    game.setupGame(Nationality.getAll().first);
    final buf = StringBuffer('=== best one-hop margin per unit, per city ===\n');
    final margins = <int>[];
    for (final c in game.map.villages) {
      var best = 0;
      var what = '';
      for (final d in game.getNeighbors(c.id)) {
        for (final g in TradeGood.values) {
          final m = TradeEngine.sellPrice(g, d) - TradeEngine.buyPrice(g, c);
          if (m > best) {
            best = m;
            what = '${g.name}->${d.name}';
          }
        }
      }
      margins.add(best);
      buf.writeln('${c.name.padRight(16)} ${c.trait.name.padRight(16)} +$best $what');
    }
    margins.sort();
    buf.writeln('cities with no profitable hop: ${margins.where((m) => m == 0).length}/${margins.length}, median ${margins[margins.length ~/ 2]}');
    // ignore: avoid_print
    print(buf);
  });

  // Road fights in isolation: warband shapes against band sizes, per battle plan.
  test('matchups', () {
    final game = GameManager.shared..resetGame();
    game.setupGame(Nationality.getAll().first);
    Unit u(UnitType t, [String owner = 'player']) => Unit.create(t, owner, const GeoCoordinate(0, 0));
    final shapes = <String, List<UnitType> Function()>{
      'start 3m+1s': () => [UnitType.militia, UnitType.militia, UnitType.militia, UnitType.spearman],
      '6 m/s': () => [for (var i = 0; i < 3; i++) UnitType.militia, for (var i = 0; i < 3; i++) UnitType.spearman],
      '10 inf': () => [for (var i = 0; i < 3; i++) UnitType.militia, for (var i = 0; i < 4; i++) UnitType.spearman, for (var i = 0; i < 3; i++) UnitType.swordsman],
      '10 +arch': () => [for (var i = 0; i < 4; i++) UnitType.spearman, for (var i = 0; i < 3; i++) UnitType.swordsman, for (var i = 0; i < 3; i++) UnitType.archer],
      '10 +cav': () => [for (var i = 0; i < 4; i++) UnitType.spearman, for (var i = 0; i < 3; i++) UnitType.swordsman, for (var i = 0; i < 3; i++) UnitType.lightCavalry],
    };
    final buf = StringBuffer('=== road fights: win% / men lost per fight (A aggressive, D defensive, G gambit) ===\n');
    const trials = 30;
    for (final shape in shapes.entries) {
      for (final bandits in [3, 5, 7, 9, 12]) {
        final cells = <String>[];
        for (final plan in BattlePlan.values) {
          var wins = 0, lost = 0;
          final sw = Stopwatch()..start();
          for (var t = 0; t < trials; t++) {
            final army = game.createArmy([for (final ty in shape.value()) u(ty)], game.map.villages.first.id, 'player');
            game.playerCharacter = PlayerCharacter(warbandId: army.id);
            final enc = Encounter(
              type: EncounterType.bandits,
              narrative: '',
              enemyUnits: [for (var i = 0; i < bandits; i++) u(UnitType.militia, 'bandits')],
              goldReward: 0,
            );
            final r = game.resolveEncounterBattle(enc, plan)!;
            if (r.won) wins++;
            lost += r.killed;
            game.removeArmy(army.id);
          }
          sw.stop();
          cells.add('${plan.name[0].toUpperCase()} ${(100 * wins / trials).round()}%/${(lost / trials).toStringAsFixed(1)}');
          if (shape.key.startsWith('10') && bandits == 12 && plan == BattlePlan.aggressive) {
            cells.add('(${(sw.elapsedMicroseconds / trials / 1000).toStringAsFixed(1)}ms)');
          }
        }
        final ratio = GameManager.fightingPower([for (final ty in shape.value()) u(ty)]) /
            GameManager.fightingPower([for (var i = 0; i < bandits; i++) u(UnitType.militia, 'bandits')]);
        buf.writeln('${shape.key.padRight(12)} vs ${'$bandits'.padLeft(2)} (power ${ratio.toStringAsFixed(2)}): ${cells.join('  ')}');
      }
    }
    // ignore: avoid_print
    print(buf);
  });
}

void _tick(GameManager game) {
  game.gameLoop.pause();
  game.gameLoop.tickCount = game.gameLoop.tickCount + 1;
  game.gameLoop.onTick?.call();
  game.gameLoop.pause();
}

RunStats _playOne(Nationality nat, CharacterOrigin origin, Random rng) {
  final s = RunStats();
  final game = GameManager.shared..resetGame();
  game.setupGame(nat);
  game.initializeGame(characterName: 'Sim', origin: origin);
  game.gameLoop.pause();
  final pc = game.playerCharacter!;
  final paid = <TradeGood, int>{};
  int lastWarband = game.playerWarband?.unitCount ?? 0;

  while (s.ticks < maxTicks && !game.isGameOver) {
    // Player-involved city battles: the UI plays them out in full.
    for (final b in game.pendingBattles.toList()) {
      s.cityBattles++;
      game.finalizeBattle(b, b.rounds.length, false);
    }
    if (pc.state == PlayerState.atCity) {
      final city = game.playerCurrentCity!;
      _cityTurn(game, pc, city, paid, s, rng);
      final dests = game.travelDestinations;
      if (dests.isEmpty) break;
      final dest = _pickDestination(game, pc, city, dests, rng);
      _buyFor(game, pc, city, dest, paid, s);
      if (trace) {
        // ignore: avoid_print
        final t = game.getGlobalResources('player');
        print('t${s.ticks} turn ${game.currentTurn} realm ${game.getPlayerVillages('player').length} treasury g${t[Resource.gold]} f${t[Resource.food]} '
            'garrison ${game.armies.where((a) => a.owner == 'player' && a.id != pc.warbandId).fold<int>(0, (n, a) => n + a.unitCount)} | '
            'at ${city.name}(${city.owner}) -> ${dest.name} gold ${pc.gold} wb ${game.playerWarband?.unitCount} '
            'cargo ${pc.cargo.map((k, v) => MapEntry(k.name, v))} won ${pc.battlesWon} lost ${game.battlesLost}');
      }
      if (!game.startTravel(dest.id)) break;
      game.gameLoop.pause();
      s.trips++;
      lastWarband = game.playerWarband?.unitCount ?? 0;
      continue;
    }
    _tick(game);
    s.ticks++;
    final wb = game.playerWarband?.unitCount ?? 0;
    if (wb < lastWarband && game.currentEncounter == null) s.deserted += lastWarband - wb;
    if (trace && wb < lastWarband - 1) {
      // ignore: avoid_print
      print('  !! warband $lastWarband -> $wb at tick ${s.ticks}, gold ${pc.gold}, events: ${game.turnEvents.map((e) => e.toString()).take(6).join(' | ')}');
    }
    lastWarband = wb;
    s.peakWarband = max(s.peakWarband, wb);
    final enc = game.currentEncounter;
    if (enc != null) {
      s.encounters++;
      s.byType[enc.type] = (s.byType[enc.type] ?? 0) + 1;
      _handleEncounter(game, pc, enc, s);
      game.gameLoop.pause();
      lastWarband = game.playerWarband?.unitCount ?? 0;
    }
    if (s.ticks % 150 == 0) {
      s.snapshots[s.ticks] = _snapshot(game, pc);
    }
  }
  s.gameOver = game.isGameOver;
  s.playerCitiesEnd = game.getPlayerVillages('player').length;
  s.stage = pc.stageTitle;
  s.snapshots[-1] = _snapshot(game, pc);
  game.gameLoop.pause();
  return s;
}

String _snapshot(GameManager game, PlayerCharacter pc) {
  final owners = <String, int>{};
  for (final v in game.map.villages) {
    owners[v.owner] = (owners[v.owner] ?? 0) + 1;
  }
  final treasury = game.getGlobalResources('player');
  final aiGold = game.players.where((p) => !p.isHuman).map((p) => game.getGlobalResources(p.id)[Resource.gold] ?? 0).fold(0, max);
  final armyUnits = <String, int>{};
  for (final a in game.armies) {
    armyUnits[a.owner] = (armyUnits[a.owner] ?? 0) + a.unitCount;
  }
  return 'turn ${game.currentTurn} gold ${pc.gold} wb ${game.playerWarband?.unitCount ?? 0} '
      'stage ${pc.stageTitle} won ${pc.battlesWon} | cities $owners | treasury g${treasury[Resource.gold] ?? 0} '
      'f${treasury[Resource.food] ?? 0} w${treasury[Resource.wood] ?? 0} i${treasury[Resource.iron] ?? 0} '
      '| richest AI g$aiGold | units $armyUnits';
}

void _cityTurn(GameManager game, PlayerCharacter pc, Village city, Map<TradeGood, int> paid, RunStats s, Random rng) {
  // Sell what pays.
  for (final good in TradeGood.values) {
    final have = pc.cargoOf(good);
    if (have == 0) continue;
    final price = TradeEngine.sellPrice(good, city);
    if (price >= (paid[good] ?? 0)) {
      final earned = TradeEngine.sell(good, have, pc, city);
      s.tradeProfit += earned - (paid[good] ?? 0) * have;
      paid.remove(good);
    }
  }
  // Heal.
  final wb = game.playerWarband;
  if (wb != null) {
    final wounded = wb.units.where((u) => u.currentHP < u.maxHP).toList();
    if (wounded.isNotEmpty && pc.gold >= wounded.length * 5 + 60) {
      for (final u in wounded) {
        u.currentHP = u.maxHP;
      }
      pc.gold -= wounded.length * 5;
    }
  }
  // Recruit: keep a reserve worth ~4 upkeep cycles.
  final avail = RecruitmentEngine().getAvailableUnits(city);
  for (final t in [UnitType.knight, UnitType.lightCavalry, UnitType.swordsman, UnitType.crossbowman, UnitType.archer, UnitType.spearman, UnitType.militia]) {
    if (!avail.contains(t)) continue;
    final size = game.playerWarband?.unitCount ?? 0;
    // A sensible player keeps trade money: about one full load of a mid-priced good.
    final reserve = (size + 1) * 2 * 4 + 200;
    final cost = t.stats.cost[Resource.gold] ?? 0;
    final byTreasury = city.owner == 'player' && game.gold >= cost + 300;
    if (size < pc.maxWarbandSize && (byTreasury || pc.gold >= cost + reserve)) {
      if (game.recruitToWarband(t, city)) s.recruited++;
      break;
    }
  }
  // Build in own cities with the treasury.
  if (builder && city.owner == 'player') {
    final engine = BuildingConstructionEngine();
    for (final b in [Building.market, Building.farm, Building.archeryRange, Building.stables, Building.fortress]) {
      final (can, _) = engine.canBuild(b, city);
      if (can && engine.buildBuilding(b, city)) {
        s.built++;
        break;
      }
    }
  }
}

Village _pickDestination(GameManager game, PlayerCharacter pc, Village city, List<Village> dests, Random rng) {
  Village best = dests[rng.nextInt(dests.length)];
  double bestScore = -1e9;
  for (final d in dests) {
    var score = rng.nextDouble() * 5;
    for (final good in TradeGood.values) {
      final margin = TradeEngine.sellPrice(good, d) - TradeEngine.buyPrice(good, city);
      score = max(score, margin.toDouble() + rng.nextDouble() * 5);
    }
    if (score > bestScore) {
      bestScore = score;
      best = d;
    }
  }
  return best;
}

void _buyFor(GameManager game, PlayerCharacter pc, Village city, Village dest, Map<TradeGood, int> paid, RunStats s) {
  TradeGood? best;
  var bestMargin = 0;
  for (final good in TradeGood.values) {
    final margin = TradeEngine.sellPrice(good, dest) - TradeEngine.buyPrice(good, city);
    if (margin > bestMargin) {
      bestMargin = margin;
      best = good;
    }
  }
  if (best == null) return;
  final price = TradeEngine.buyPrice(best, city);
  final size = game.playerWarband?.unitCount ?? 0;
  final reserve = size * 2 * 3 + 30;
  var n = 0;
  while (pc.gold - price >= reserve && TradeEngine.buy(best, 1, pc, city)) {
    n++;
  }
  if (n > 0) {
    final had = (paid[best] ?? 0);
    paid[best] = had == 0 ? price : max(had, price);
  }
}

void _handleEncounter(GameManager game, PlayerCharacter pc, Encounter enc, RunStats s) {
  final skills = {
    'combat': pc.combatSkill,
    'leadership': pc.leadershipSkill,
    'tactics': pc.tacticsSkill,
    'trade': pc.tradeSkill,
    'scouting': pc.scoutingSkill,
  };
  final wb = game.playerWarband?.units ?? const [];
  final mine = GameManager.fightingPower(wb);
  final theirs = GameManager.fightingPower(enc.enemyUnits ?? const []);
  EncounterChoice? pick;
  bool fight = false;
  final choices = enc.choices.where((c) => c.isAvailable(skills)).toList();
  EncounterChoice? of(EncounterChoiceOutcome o) => choices.where((c) => c.outcome == o).firstOrNull;
  switch (enc.type) {
    case EncounterType.bandits:
    case EncounterType.patrol:
      final dismiss = of(EncounterChoiceOutcome.dismiss);
      final toll = of(EncounterChoiceOutcome.payGold);
      // Plays like a sensible player reading the odds label: take the loot when strong,
      // talk or pay when weak, fight a close one, run from a hopeless one.
      final ratio = mine / max(1, theirs);
      if (ratio >= 1.0) {
        fight = true;
      } else if (dismiss != null) {
        pick = dismiss;
      } else if (toll != null && pc.gold >= (toll.goldAmount ?? 0)) {
        pick = toll;
        s.tolls++;
      } else if (ratio >= 0.5) {
        fight = true;
      } else {
        pick = of(EncounterChoiceOutcome.flee);
        s.flees++;
      }
    case EncounterType.deserters:
      pick = of(EncounterChoiceOutcome.recruitUnit) ?? of(EncounterChoiceOutcome.dismiss);
    case EncounterType.woundedSoldier:
      pick = of(EncounterChoiceOutcome.recruitUnit) ?? of(EncounterChoiceOutcome.dismiss);
    default:
      pick = of(EncounterChoiceOutcome.dismiss) ?? choices.lastOrNull;
  }
  if (fight) {
    s.fights++;
    final plan = BattlePlan.bestFor(mine / max(1, theirs));
    final hp = wb.fold<int>(0, (n, u) => n + u.currentHP);
    final maxHp = wb.fold<int>(0, (n, u) => n + u.maxHP);
    final mix = <String, int>{};
    for (final u in wb) {
      mix[u.unitType.name] = (mix[u.unitType.name] ?? 0) + 1;
    }
    final before = wb.length;
    final r = game.resolveEncounterBattle(enc, plan);
    if (trace) {
      // ignore: avoid_print
      print('  fight ${enc.enemyUnits?.length} ${enc.type.name} vs $before $mix hp $hp/$maxHp ratio ${(mine / max(1, theirs)).toStringAsFixed(2)} '
          '${plan.name} -> ${r?.won} killed ${r?.killed} left ${game.playerWarband?.unitCount ?? 0}');
    }
    if (r?.won ?? false) s.wins++;
    s.killed += r?.killed ?? 0;
    game.dismissEncounter();
    return;
  }
  if (pick != null) {
    final res = game.resolveEncounterChoice(enc, pick);
    if (res == null) game.dismissEncounter();
  } else {
    game.dismissEncounter();
  }
}

void _report(List<RunStats> all) {
  double avg(num Function(RunStats) f) => all.map(f).fold<num>(0, (a, b) => a + b) / all.length;
  final buf = StringBuffer();
  buf.writeln('=== ${all.length} runs, up to $maxTicks ticks, build=${builder ? 'on' : 'off'} ===');
  buf.writeln('game over: ${all.where((s) => s.gameOver).length}/${all.length}, avg ticks lived ${avg((s) => s.ticks).toStringAsFixed(0)}');
  buf.writeln('trips ${avg((s) => s.trips).toStringAsFixed(1)}, encounters ${avg((s) => s.encounters).toStringAsFixed(1)} '
      '(${(avg((s) => s.encounters) / max(1, avg((s) => s.trips))).toStringAsFixed(2)} per trip)');
  final types = <EncounterType, double>{};
  for (final t in EncounterType.values) {
    types[t] = avg((s) => s.byType[t] ?? 0);
  }
  buf.writeln('by type ${types.entries.where((e) => e.value > 0).map((e) => '${e.key.name} ${e.value.toStringAsFixed(1)}').join(', ')}');
  buf.writeln('fights ${avg((s) => s.fights).toStringAsFixed(1)}, won ${avg((s) => s.wins).toStringAsFixed(1)} '
      '(${(100 * avg((s) => s.wins) / max(0.001, avg((s) => s.fights))).toStringAsFixed(0)}%), tolls ${avg((s) => s.tolls).toStringAsFixed(1)}, flees ${avg((s) => s.flees).toStringAsFixed(1)}');
  buf.writeln('trade profit ${avg((s) => s.tradeProfit).toStringAsFixed(0)}, recruited ${avg((s) => s.recruited).toStringAsFixed(1)}, '
      'lost to upkeep ${avg((s) => s.deserted).toStringAsFixed(1)}, peak warband ${avg((s) => s.peakWarband).toStringAsFixed(1)}, built ${avg((s) => s.built).toStringAsFixed(1)}, city battles ${avg((s) => s.cityBattles).toStringAsFixed(1)}');
  buf.writeln('player cities at end ${avg((s) => s.playerCitiesEnd).toStringAsFixed(1)}, stages ${all.map((s) => s.stage).join(',')}');
  for (final t in [150, 300, 450, 600, 750, 900]) {
    final lines = all.map((s) => s.snapshots[t]).whereType<String>().toList();
    if (lines.isEmpty) continue;
    buf.writeln('-- t=$t (${lines.length} alive) e.g. ${lines.first}');
  }
  buf.writeln('-- end e.g. ${all.first.snapshots[-1]}');
  // ignore: avoid_print
  print(buf);
}
