import 'dart:convert';

class GameRecord {
  final DateTime date;
  final String factionId;
  final String? victoryType;
  final int score;
  final int turns;
  final int battlesWon;
  final int villagesControlled;
  final String? difficulty;

  const GameRecord({
    required this.date,
    required this.factionId,
    this.victoryType,
    required this.score,
    required this.turns,
    required this.battlesWon,
    required this.villagesControlled,
    this.difficulty,
  });

  bool get isVictory => victoryType != null;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'factionId': factionId,
        'victoryType': victoryType,
        'score': score,
        'turns': turns,
        'battlesWon': battlesWon,
        'villagesControlled': villagesControlled,
        'difficulty': difficulty,
      };

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
        date: DateTime.parse(json['date'] as String),
        factionId: json['factionId'] as String,
        victoryType: json['victoryType'] as String?,
        score: json['score'] as int,
        turns: json['turns'] as int,
        battlesWon: json['battlesWon'] as int,
        villagesControlled: json['villagesControlled'] as int,
        difficulty: json['difficulty'] as String?,
      );

  static String encodeList(List<GameRecord> records) =>
      jsonEncode(records.map((r) => r.toJson()).toList());

  static List<GameRecord> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    return list.map((j) => GameRecord.fromJson(j as Map<String, dynamic>)).toList();
  }
}
