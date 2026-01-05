import '../data/models/village.dart';
import 'game_manager.dart';

enum TutorialAction {
  none,
  buildMarket,
  buildFarm,
  recruit,
  endTurn,
}

class TutorialHelper {
  static TutorialAction getNextAction(Village village) {
    final game = GameManager.shared;
    final completed = game.completedTutorialActions;

    // 1. Build Market (Priority 1)
    if (!village.buildings.any((b) => b.name == 'Market')) {
      if (!completed.contains(TutorialAction.buildMarket.name)) {
        return TutorialAction.buildMarket;
      }
    }

    // 2. Build Farm (Priority 2, need food to sustain army)
    if (!village.buildings.any((b) => b.name == 'Farm')) {
       if (!completed.contains(TutorialAction.buildFarm.name)) {
        return TutorialAction.buildFarm;
      }
    }

    // 3. Recruit Units
    // Ideally we want the user to recruit at least once.
    if (!completed.contains(TutorialAction.recruit.name)) {
       // Only suggest if we have buildings to recruit from
       if (village.buildings.any((b) => ['Barracks', 'Archery Range', 'Stables'].contains(b.name))) {
         return TutorialAction.recruit;
       }
    }
    
    // 4. End Turn
    // If we have done actions this turn or just generally, and haven't learned to End Turn?
    // Actually, End Turn is something you do every turn. Maybe we only highlight it the VERY FIRST time?
    if (!completed.contains(TutorialAction.endTurn.name)) {
      return TutorialAction.endTurn;
    }
    
    return TutorialAction.none;
  }
  
  static bool shouldHighlightEndTurn(Village village, bool outOfResources) {
     final action = getNextAction(village);
     return action == TutorialAction.endTurn || (outOfResources && !GameManager.shared.completedTutorialActions.contains(TutorialAction.endTurn.name));
  }
}
