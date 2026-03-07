import 'dart:math';
import '../data/models/village.dart';
import '../data/models/village_trait.dart';
import 'game_manager.dart';

class NarrativeEngine {
  static final _rng = Random();

  /// Generate a narrative description when the player arrives at a city.
  static String cityArrival(Village city, GameManager game) {
    final parts = <String>[];

    // Opening — based on city trait
    parts.add(_traitOpening(city));

    // Context — what's happening here right now
    final context = _cityContext(city, game);
    if (context != null) parts.add(context);

    // Atmosphere detail
    parts.add(_atmosphereDetail(city));

    return parts.join(' ');
  }

  static String _traitOpening(Village city) {
    final name = city.name;
    final openings = switch (city.trait) {
      VillageTrait.tradeCrossroads => [
        'The markets of $name sprawl before you, alive with shouting merchants and the smell of spices.',
        'You pass through the gates of $name into a river of commerce. Every voice is selling something.',
        '$name greets you with the clink of coins and the chatter of a dozen languages.',
      ],
      VillageTrait.mountainous => [
        'The mountain fortress of $name looms above, carved from the living rock.',
        'You climb the last switchback and $name opens before you, perched on the edge of the world.',
        'Wind howls through the passes as you reach the gates of $name.',
      ],
      VillageTrait.fertile => [
        'Golden fields stretch to the horizon around $name. The granaries are full.',
        'The road to $name runs through orchards heavy with fruit. A good land.',
        'You smell $name before you see it — baking bread and fresh earth.',
      ],
      VillageTrait.coastal => [
        'Salt air fills your lungs as the walls of $name rise above the harbor.',
        'Gulls wheel over $name, and the harbor bristles with masts.',
        'The sea road ends at $name. Waves crash against the ancient seawall.',
      ],
      VillageTrait.forested => [
        'The forest thins and $name appears between the ancient oaks.',
        'Timber walls surround $name, built from the very forest that hides it.',
        'Woodsmoke rises above the treeline. $name sits deep in the woods.',
      ],
      VillageTrait.strategic => [
        '$name sits at the crossroads of three kingdoms. Every faction wants it. None can hold it long.',
        'The roads converge at $name. Armies have marched through here since before anyone can remember.',
        '$name commands the pass. Whoever holds it controls the road.',
      ],
      VillageTrait.none => [
        'The gates of $name stand open. A modest settlement, but shelter is shelter.',
        'You arrive at $name. Nothing remarkable, but the walls are standing.',
      ],
    };

    return openings[_rng.nextInt(openings.length)];
  }

  static String? _cityContext(Village city, GameManager game) {
    // Under siege
    if (city.underSiege) {
      return [
        'The city is under siege. Smoke rises from beyond the walls and the garrison stands ready.',
        'Siege engines loom outside. The defenders look exhausted but determined.',
      ][_rng.nextInt(2)];
    }

    // Low garrison — vulnerable
    if (city.garrisonStrength < city.garrisonMaxStrength * 0.3) {
      return [
        'The garrison is thin. Guards patrol the walls nervously, watching the horizon.',
        'Too few soldiers man the walls. The city feels exposed.',
      ][_rng.nextInt(2)];
    }

    // War nearby
    final neighbors = game.getNeighbors(city.id);
    final enemyNeighbor = neighbors.where((n) => n.owner != city.owner).isNotEmpty;
    if (enemyNeighbor && _rng.nextDouble() < 0.5) {
      return [
        'There\'s tension in the air. Enemy banners have been spotted in neighboring lands.',
        'Soldiers drill in the courtyard. War is close.',
      ][_rng.nextInt(2)];
    }

    // Peaceful
    if (_rng.nextDouble() < 0.4) {
      return [
        'The city is at peace, for now. People go about their business.',
        'Life continues here, sheltered behind thick walls and old prayers.',
        'Children play in the streets. A rare sight in these times.',
      ][_rng.nextInt(3)];
    }

    return null;
  }

  static String _atmosphereDetail(Village city) {
    final details = [
      'A tavern sign creaks in the wind. As good a place to start as any.',
      'You find a stable for your horse and head for the tavern.',
      'The tavern door is open. The sound of voices and clinking cups drifts out.',
      'You need information, supplies, and a drink. The tavern can provide all three.',
      'Your soldiers head for the nearest inn. You follow the smell of cooking meat.',
    ];
    return details[_rng.nextInt(details.length)];
  }

  /// Generate a narrative for world events visible during travel.
  static String? worldEventNarrative(String eventDescription) {
    // Wrap raw event descriptions in atmospheric framing
    if (eventDescription.contains('captured')) {
      return 'Word reaches you on the road: $eventDescription';
    }
    if (eventDescription.contains('war') || eventDescription.contains('battle')) {
      return 'A rider gallops past, shouting news: $eventDescription';
    }
    if (eventDescription.contains('drought') || eventDescription.contains('winter')) {
      return 'Travelers on the road speak of $eventDescription';
    }
    return null;
  }
}
