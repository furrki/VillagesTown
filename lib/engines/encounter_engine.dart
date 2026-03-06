import 'dart:math';

import '../data/models/encounter.dart';

class EncounterEngine {
  static Encounter? rollEncounter(int playerStrength, int tickNumber, {int scoutingSkill = 1}) {
    // Higher scouting skill gives chance to avoid encounters entirely
    if (scoutingSkill > 1) {
      final avoidChance = (scoutingSkill - 1) * 0.03; // 3% per level above 1
      if (Random().nextDouble() < avoidChance) return null;
    }
    final encounter = Encounter.generate(playerStrength, tickNumber);
    if (encounter.type == EncounterType.nothing) return null;
    return encounter;
  }
}
