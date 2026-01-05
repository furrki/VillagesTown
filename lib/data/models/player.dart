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

  // Creates all 7 faction players (1 human slot + 6 AI)
  static List<Player> createPlayers() => [
        Player(
          id: 'player',
          name: 'Player',
          nationality: Nationality.byzantines, // Will be overwritten in setupGame
          isHuman: true,
        ),
        // Major factions
        Player(
          id: 'byzantines',
          name: 'Byzantines',
          nationality: Nationality.byzantines,
          isHuman: false,
          aiPersonality: AIPersonality.balanced,
        ),
        Player(
          id: 'ottomans',
          name: 'Ottomans',
          nationality: Nationality.ottomans,
          isHuman: false,
          aiPersonality: AIPersonality.aggressive,
        ),
        Player(
          id: 'crusaders',
          name: 'Crusaders',
          nationality: Nationality.crusaders,
          isHuman: false,
          aiPersonality: AIPersonality.aggressive,
        ),
        // Minor factions
        Player(
          id: 'bulgaria',
          name: 'Bulgaria',
          nationality: Nationality.bulgaria,
          isHuman: false,
          aiPersonality: AIPersonality.defensive,
        ),
        Player(
          id: 'serbia',
          name: 'Serbia',
          nationality: Nationality.serbia,
          isHuman: false,
          aiPersonality: AIPersonality.defensive,
        ),
        Player(
          id: 'armenia',
          name: 'Armenia',
          nationality: Nationality.armenia,
          isHuman: false,
          aiPersonality: AIPersonality.defensive,
        ),
        Player(
          id: 'mamluks',
          name: 'Mamluks',
          nationality: Nationality.mamluks,
          isHuman: false,
          aiPersonality: AIPersonality.balanced,
        ),
      ];
}
