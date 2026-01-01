import 'ai_personality.dart';
import 'nationality.dart';

class Player {
  final String id;
  final String name;
  Nationality nationality;
  final bool isHuman;
  List<String> villages;
  bool isEliminated;
  final AIPersonality? aiPersonality;

  Player({
    required this.id,
    required this.name,
    required this.nationality,
    required this.isHuman,
    List<String>? villages,
    this.isEliminated = false,
    this.aiPersonality,
  }) : villages = villages ?? [];

  Player copyWith({
    String? id,
    String? name,
    Nationality? nationality,
    bool? isHuman,
    List<String>? villages,
    bool? isEliminated,
    AIPersonality? aiPersonality,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      nationality: nationality ?? this.nationality,
      isHuman: isHuman ?? this.isHuman,
      villages: villages ?? List.from(this.villages),
      isEliminated: isEliminated ?? this.isEliminated,
      aiPersonality: aiPersonality ?? this.aiPersonality,
    );
  }

  static List<Player> createPlayers() => [
        Player(
          id: 'player',
          name: 'Player',
          nationality: Nationality.turkish,
          isHuman: true,
        ),
        Player(
          id: 'ai1',
          name: 'AI Player 1',
          nationality: Nationality.greek,
          isHuman: false,
          aiPersonality: AIPersonality.aggressive,
        ),
        Player(
          id: 'ai2',
          name: 'AI Player 2',
          nationality: Nationality.bulgarian,
          isHuman: false,
          aiPersonality: AIPersonality.balanced,
        ),
      ];
}
