import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/achievement.dart';
import '../data/models/game_event.dart';
import '../data/models/game_record.dart';
import '../data/models/nationality.dart';
import '../data/models/victory_condition.dart';
import 'game_manager.dart';
import 'victory_engine.dart';

class ProgressionEngine {
  static const _achievementsKey = 'unlocked_achievements';
  static const _gameRecordsKey = 'game_records';

  // --- Persistence ---

  static Future<Set<String>> getUnlockedAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_achievementsKey);
    return list?.toSet() ?? {};
  }

  static Future<void> _saveAchievements(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_achievementsKey, ids.toList());
  }

  static Future<List<GameRecord>> getGameRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_gameRecordsKey);
    if (json == null) return [];
    try {
      return GameRecord.decodeList(json);
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveGameRecord(GameRecord record) async {
    final records = await getGameRecords();
    records.add(record);
    // Keep last 50 records
    if (records.length > 50) {
      records.removeRange(0, records.length - 50);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gameRecordsKey, GameRecord.encodeList(records));
  }

  // --- Game Completion ---

  /// Called when game ends (victory or defeat). Returns newly unlocked achievements.
  static Future<List<Achievement>> onGameEnd(GameManager game, bool isVictory) async {
    final score = VictoryEngine.calculateScore(game);
    final factionId = game.playerNationality?.id ?? 'unknown';

    // Save game record
    final record = GameRecord(
      date: DateTime.now(),
      factionId: factionId,
      victoryType: isVictory ? game.achievedVictoryType?.name : null,
      score: score.total,
      turns: game.currentTurn,
      battlesWon: game.battlesWon['player'] ?? 0,
      villagesControlled: game.getPlayerVillages('player').length,
      difficulty: game.difficulty?.name,
    );
    await _saveGameRecord(record);

    // Check achievements
    final unlocked = await getUnlockedAchievements();
    final newlyUnlocked = <Achievement>[];

    // Achievements that can be earned regardless of victory/defeat
    const alwaysCheckable = {
      Achievement.firstBlood,
      Achievement.blitzkrieg,
      Achievement.cavalryMaster,
      Achievement.merchantPrince,
      Achievement.empireBuilder,
      Achievement.winterWarrior,
      Achievement.earthquakeSurvivor,
    };

    final allRecords = await getGameRecords();
    for (final achievement in Achievement.values) {
      if (unlocked.contains(achievement.name)) continue;
      if (!isVictory && !alwaysCheckable.contains(achievement)) continue;
      if (_checkAchievement(achievement, game, allRecords)) {
        newlyUnlocked.add(achievement);
        unlocked.add(achievement.name);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      await _saveAchievements(unlocked);
    }

    return newlyUnlocked;
  }

  // --- Achievement Checking ---

  static bool _checkAchievement(
      Achievement achievement, GameManager game, List<GameRecord> allRecords) {
    final battlesWon = game.battlesWon['player'] ?? 0;
    final battlesLost = game.battlesLost;

    return switch (achievement) {
      Achievement.firstBlood => battlesWon >= 1,
      Achievement.undefeated => battlesWon > 0 && battlesLost == 0,
      Achievement.blitzkrieg => game.conquestsInWindow >= 3,
      Achievement.cavalryMaster => game.hadCavalryOnlyBattleWin,
      Achievement.merchantPrince => game.peakGold >= 5000,
      Achievement.empireBuilder => game.peakVillageCount >= 10,
      Achievement.speedRun => game.currentTurn <= 25,
      Achievement.marathon => game.currentTurn >= 60,
      Achievement.underdog => _isMinorFaction(game.playerNationality),
      Achievement.worldConqueror => _hasWonWithAllFactions(allRecords),
      Achievement.survivor => game.lostCapital,
      Achievement.economicVictor =>
        game.achievedVictoryType == VictoryType.economic,
      Achievement.militaryVictor =>
        game.achievedVictoryType == VictoryType.military,
      Achievement.imperialVictor =>
        game.achievedVictoryType == VictoryType.imperial,
      Achievement.winterWarrior => game.conqueredDuringWinter,
      Achievement.earthquakeSurvivor => game.eventHistory
          .any((e) => e.type == GameEventType.earthquake && e.targetPlayerId == 'player'),
    };
  }

  static bool _isMinorFaction(Nationality? nat) {
    if (nat == null) return false;
    return !nat.isMajor;
  }

  static bool _hasWonWithAllFactions(List<GameRecord> records) {
    final wonFactions = records
        .where((r) => r.isVictory)
        .map((r) => r.factionId)
        .toSet();
    final allFactions = Nationality.getAll().map((n) => n.id).toSet();
    return allFactions.difference(wonFactions).isEmpty;
  }

  // --- Stats Queries ---

  static Future<Map<String, dynamic>> getStats() async {
    final records = await getGameRecords();
    final unlocked = await getUnlockedAchievements();

    final wins = records.where((r) => r.isVictory).toList();
    final highScore = records.isEmpty ? 0 : records.map((r) => r.score).reduce((a, b) => a > b ? a : b);
    final fastestWin = wins.isEmpty ? null : wins.map((r) => r.turns).reduce((a, b) => a < b ? a : b);

    // Per-faction stats
    final factionWins = <String, int>{};
    for (final record in wins) {
      factionWins[record.factionId] = (factionWins[record.factionId] ?? 0) + 1;
    }

    return {
      'totalGames': records.length,
      'totalWins': wins.length,
      'highScore': highScore,
      'fastestWin': fastestWin,
      'achievementsUnlocked': unlocked.length,
      'totalAchievements': Achievement.values.length,
      'factionWins': factionWins,
      'records': records,
      'unlocked': unlocked,
    };
  }
}
