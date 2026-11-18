import 'dart:math';

import '../data/models/encounter.dart';

class EncounterEngine {
  /// Encounters a trip brings on average, however long it is. Rolling per tick made a long road
  /// a string of ambushes: 1.7 per trip in the balance sim, where the design wants about one in three
  /// trips to meet bandits.
  static const encountersPerTrip = 0.45;

  /// Long roads still feel more dangerous than short ones.
  static const minChancePerTick = 0.03;

  static Encounter? rollEncounter(int playerStrength, int tickNumber, {required int tripTicks, int scoutingSkill = 1}) {
    final rng = Random();
    // The arrival tick never rolls, so a trip of N ticks rolls N - 1 times.
    final chance = max(encountersPerTrip / max(1, tripTicks - 1), minChancePerTick);
    if (rng.nextDouble() >= chance) return null;
    // Higher scouting skill gives chance to avoid encounters entirely
    if (scoutingSkill > 1 && rng.nextDouble() < (scoutingSkill - 1) * 0.03) return null;
    return Encounter.generate(playerStrength, tickNumber);
  }
}
