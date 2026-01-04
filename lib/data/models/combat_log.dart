
class BattleRound {
  final List<int> attackerRolls;
  final List<int> defenderRolls;
  final int attackerBonus;
  final int defenderBonus;
  final int attackerLosses;
  final int defenderLosses;
  final String narration;

  BattleRound({
    required this.attackerRolls,
    required this.defenderRolls,
    this.attackerBonus = 0,
    this.defenderBonus = 0,
    required this.attackerLosses,
    required this.defenderLosses,
    required this.narration,
  });
}

class BattleRecord {
  final String id;
  final String attackerName;
  final String defenderName;
  final String attackerId; // New
  final String defenderId; // New
  final String? originVillageId; // New
  final String locationName;
  final List<BattleRound> rounds;
  final bool attackerWon;
  final int initialAttackerCount;
  final int initialDefenderCount;
  final DateTime timestamp;
  bool isPending; // New (mutable to mark as done)

  BattleRecord({
    required this.id,
    required this.attackerName,
    required this.defenderName,
    required this.attackerId,
    required this.defenderId,
    this.originVillageId,
    required this.locationName,
    required this.rounds,
    required this.attackerWon,
    required this.initialAttackerCount,
    required this.initialDefenderCount,
    DateTime? timestamp,
    this.isPending = true,
  }) : timestamp = timestamp ?? DateTime.now();
  
  int get totalAttackerLosses => rounds.fold(0, (sum, r) => sum + r.attackerLosses);
  int get totalDefenderLosses => rounds.fold(0, (sum, r) => sum + r.defenderLosses);
}
