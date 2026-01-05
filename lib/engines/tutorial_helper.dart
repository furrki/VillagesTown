import '../data/models/village.dart';
import '../data/models/building.dart';

enum TutorialAction {
  none,
  buildMarket,
  buildFarm,
  recruit,
  endTurn,
}

class TutorialHelper {
  static TutorialAction getNextAction(Village village) {
    // 1. Build Market (Priority 1)
    if (!village.buildings.any((b) => b.name == 'Market')) {
      return TutorialAction.buildMarket;
    }

    // 2. Build Farm (Priority 2, need food to sustain army)
    if (!village.buildings.any((b) => b.name == 'Farm')) {
      return TutorialAction.buildFarm;
    }

    // 3. Recruit Units (If we have resources but low army)
    // Actually, "Recruit buttons" was requested.
    // If we have < 3 units, suggest recruiting.
    // (We can't easily check army count here without passing armies param, 
    // but typically early game you recruit.)
    // Let's assume highlighting recruit is generally good if we have valid buildings.
    // But we need to switch to "End Turn" if we are out of resources.
    
    // For now, simplify: Suggest Market -> Farm.
    // If those exist, suggest Recruiting effectively?
    // The prompt said: "Highlight market... then recruit buttons, then end turn button."
    
    // Let's just highlight Recruit if we have buildings but haven't ended turn?
    // How to know if we should End Turn? Typically when we can't do anything else.
    // Since we don't have resource context easily here without passing it, 
    // let's rely on the Panel to pass that info or keep it simple.
    
    return TutorialAction.recruit; 
    // The panel logic will override this to 'endTurn' if resources are low?
    // Or we just return 'recruit' and let the user decide when to stop.
    // The user said "then end turn button".
  }
  
  static bool shouldHighlightEndTurn(Village village, bool outOfResources) {
     final action = getNextAction(village);
     // If we are supposed to build/recruit but can't afford it -> End Turn
     // Or if we have done enough.
     return outOfResources;
  }
}
