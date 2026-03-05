# VillagesTown - Strategic Direction Plan

## The Problem

The game has deep mechanics (combat, economy, fog of war, tactics) but no reason to play more than once. Once you beat the AI, there's nothing pulling you back. Every game plays the same way, ends the same way, and rewards you the same way (a trophy screen).

## The Solution: Three Pillars

### Pillar 1: Dynamic World Events (make every game different)
### Pillar 2: Multiple Victory Paths (give players choices that matter)
### Pillar 3: Persistent Progression (make winning mean something)

---

# PILLAR 1: DYNAMIC WORLD EVENTS

## Concept

A mid-game event system that injects chaos, opportunity, and narrative into each playthrough. Events fire randomly (weighted by game state) and force players to adapt their strategy.

## Event Categories

### 1.1 Natural Disasters (Threats)

**Drought**
- Trigger: Random, turns 8-40, once per game
- Effect: All farms produce 50% food for 3 turns
- Scope: Affects ALL players equally
- Counter: Stockpile food, coastal villages unaffected (trait: coastal gets +25% food still)
- Event text: "A great drought spreads across the land. Crops wither in the fields."

**Plague**
- Trigger: Random, turns 15-50, weighted toward high-population villages
- Effect: Target village loses 30% population over 2 turns, spreads to connected villages at 15% rate
- Scope: Starts at one village, can spread along city connections
- Counter: Isolate armies (don't station at infected villages), accept population loss
- Event text: "The Black Death has arrived at [Village]. The people are dying."

**Harsh Winter**
- Trigger: Random, turns 10-45
- Effect: All army movement takes +1 turn for 3 turns, march fatigue doubled
- Scope: Global
- Counter: Don't march during winter, defend in place
- Event text: "Winter descends. Snow blankets the roads. Armies slow to a crawl."

**Earthquake**
- Trigger: Random, rare (5% per turn after turn 10)
- Effect: One random village loses 1 building (random selection), fortress downgraded 1 level
- Scope: Single village (any player)
- Counter: Rebuild. That's it. Sometimes bad things happen.
- Event text: "The earth trembles beneath [Village]. Walls crack and buildings crumble."

### 1.2 Economic Events (Opportunities)

**Trade Caravan**
- Trigger: Random, turns 5-30, repeatable
- Effect: A neutral trade caravan appears. First player to have an army at the target village within 3 turns gets +500 gold, +200 food
- Scope: Single village on the map (neutral or owned)
- Counter: Fast cavalry can intercept before opponents
- Event text: "A wealthy merchant caravan seeks safe passage through [Village]."

**Gold Rush**
- Trigger: Random, turns 10-35
- Effect: One village's market produces 3x gold for 5 turns
- Scope: Random village (any player's)
- Decision: If it's an enemy village, do you attack to steal it?
- Event text: "Rich gold deposits discovered near [Village]! Traders flock to the region."

**Famine**
- Trigger: When any player's total food drops below 0 for 2+ consecutive turns
- Effect: That player's villages lose 5 population/turn until food stabilizes
- Scope: Single player
- Counter: Build more farms, conquer fertile villages, trade
- Event text: "Famine grips [Player]'s lands. The people cry out for bread."

**Bountiful Harvest**
- Trigger: Random, turns 5-25, weighted toward players with many farms
- Effect: All farms produce 2x food for 2 turns
- Scope: Global
- Event text: "The harvest is abundant this year. Granaries overflow."

### 1.3 Military Events (Game-changers)

**Mercenary Company**
- Trigger: Random, turns 12-40, repeatable
- Effect: A mercenary army (3 swordsmen + 2 archers + 1 knight) appears at a random neutral village. First player to send 300 gold gets them.
- Scope: Available to all, first-come-first-served
- Decision: Spend 300 gold for instant army, or save for buildings?
- Event text: "The Free Company of [Name] offers their swords to the highest bidder at [Village]."

**Rebellion**
- Trigger: When a village's happiness drops below 20
- Effect: Village switches to neutral. Garrison resets to 5. Owner must reconquer.
- Scope: Single village
- Counter: Keep happiness above 20 (don't over-tax, don't lose battles nearby)
- Event text: "The people of [Village] have risen in revolt! They reject [Player]'s rule."

**Mongol Invasion** (Late-game crisis)
- Trigger: Turn 40+, guaranteed once per game if game reaches turn 40
- Effect: A powerful Mongol army (10 knights, 5 horse archers, 10 light cavalry) spawns at the eastern edge of the map and attacks the nearest village every 3 turns
- Scope: Global threat, moves westward
- Decision: Do rivals unite against the Mongols, or let them weaken each other?
- AI behavior: AI should temporarily deprioritize player attacks to defend against Mongols
- Event text: "Riders from the East! The Mongol horde descends upon the land!"

**Desertion**
- Trigger: Army with foodDeprivedTurns >= 4
- Effect: 20% of army units defect to nearest AI player's village as garrison
- Scope: Single army
- Counter: Feed your armies
- Event text: "Starving soldiers from [Army] have deserted to [Village]."

### 1.4 Political Events (Diplomacy seeds)

**Royal Marriage** (future diplomacy hook)
- Trigger: Random, turns 15-35
- Effect: Two AI players form a non-aggression pact for 10 turns (won't attack each other)
- Scope: Two AI nations
- Impact: Changes threat landscape, forces player to recalculate
- Event text: "A royal marriage unites [Nation A] and [Nation B]. They pledge 10 turns of peace."

**Crusade Called**
- Trigger: If Crusader faction is losing (owns < 2 villages), turn 20+
- Effect: Crusader faction gets +50% recruitment speed for 5 turns, all Crusader units get +10% attack
- Scope: Crusader faction only
- Event text: "The Pope calls a new Crusade! Crusader armies swell with zealous reinforcements."

**Civil War**
- Trigger: Random, turns 25-50, targets the leading player (most villages)
- Effect: Leading player's weakest village defects to the second-place player
- Scope: Two players
- Counter: Keep all villages well-garrisoned and happy
- Event text: "A succession crisis erupts in [Nation]! [Village] declares for [Rival Nation]."

## Event System Architecture

### Data Model

```dart
// New file: lib/data/models/game_event.dart

enum GameEventType {
  drought, plague, harshWinter, earthquake,
  tradeCaravan, goldRush, famine, bountifulHarvest,
  mercenaryCompany, rebellion, mongolInvasion, desertion,
  royalMarriage, crusadeCalled, civilWar
}

enum EventScope { global, singlePlayer, singleVillage, twoPlayers }

class GameEvent {
  final String id;
  final GameEventType type;
  final int triggerTurn;         // when it fires
  final int duration;            // turns it lasts (0 = instant)
  final int turnsRemaining;      // countdown
  final String? targetVillageId;
  final String? targetPlayerId;
  final String? secondaryPlayerId;
  final bool isActive;
  final Map<String, dynamic> data; // flexible payload
}
```

### Integration Points

**Where it hooks into existing code:**

1. `turn_engine.dart` - New phase after Economy, before Combat:
   ```
   // Existing order:
   1. Cleanup
   2. Economy (building production, tax, resource sync)
   3. >>> NEW: Event Processing Phase <<<
   4. Population (army upkeep, population growth)
   5. Garrison
   6. Combat
   7. AI
   8. Intelligence
   9. Victory
   ```

2. `game_manager.dart` - New state fields:
   ```dart
   List<GameEvent> activeEvents = [];
   List<GameEvent> eventHistory = [];
   Set<GameEventType> usedOneTimeEvents = {};
   ```

3. `turn_event.dart` - New sealed class variants:
   ```dart
   GameWorldEvent extends TurnEvent  // for display in event log
   ```

4. AI managers - Event awareness:
   - `ai_strategy_manager.dart`: Deprioritize attacks during Mongol invasion, respect royal marriages
   - `ai_economy_manager.dart`: Build farms during drought, stockpile during bountiful harvest
   - `ai_military_manager.dart`: Recruit heavily when mercenaries available

### Event Engine (new file)

```
// lib/engines/event_engine.dart

class EventEngine {
  // Called each turn from turn_engine
  void processEvents(GameManager game) {
    _tickActiveEvents(game);      // countdown durations, remove expired
    _rollForNewEvents(game);       // check triggers, spawn new events
    _applyEventEffects(game);      // modify resources, armies, villages
  }

  void _rollForNewEvents(GameManager game) {
    // For each event type:
    // 1. Check turn range (e.g., drought only turns 8-40)
    // 2. Check preconditions (e.g., rebellion needs happiness < 20)
    // 3. Check one-time flag (e.g., Mongol invasion only once)
    // 4. Roll probability (e.g., 8% per turn)
    // 5. If triggered, create GameEvent and add to activeEvents
  }
}
```

### Event Probabilities (per turn, within valid turn range)

| Event | Probability | One-time? | Turn Range |
|-------|------------|-----------|------------|
| Drought | 6% | Yes | 8-40 |
| Plague | 4% | Yes | 15-50 |
| Harsh Winter | 8% | No (max 2) | 10-45 |
| Earthquake | 5% | No | 10+ |
| Trade Caravan | 10% | No | 5-30 |
| Gold Rush | 6% | No (max 2) | 10-35 |
| Bountiful Harvest | 8% | No | 5-25 |
| Mercenary Company | 7% | No (max 3) | 12-40 |
| Rebellion | Conditional | No | Any |
| Mongol Invasion | 100% at turn 40 | Yes | 40+ |
| Desertion | Conditional | No | Any |
| Royal Marriage | 5% | No (max 2) | 15-35 |
| Crusade Called | Conditional | Yes | 20+ |
| Civil War | 4% | Yes | 25-50 |

### UI Integration

- Event notification popup (modal or banner) when major event fires
- Active events shown in side info panel with turn countdown
- Event history in a collapsible log
- Map markers for event targets (trade caravan location, plague village, Mongol army position)

---

# PILLAR 2: MULTIPLE VICTORY CONDITIONS

## Current State
One victory condition: eliminate all opponents (domination). This makes late-game a tedious mop-up.

## New Victory Conditions

### 2.1 Domination Victory (existing, refined)
- **Condition**: Control 70% of all villages (not 100%)
- **Why 70%**: Avoids the boring "hunt down last village" endgame
- **Alternative**: Eliminate 5 of 6 AI opponents (last one surrenders)
- **Thematic**: "Your empire spans the known world. The remaining kingdoms bend the knee."

### 2.2 Economic Victory (new)
- **Condition**: Accumulate 10,000 gold in treasury AND control at least 3 Trade Crossroads villages
- **Playstyle**: Market-heavy, trade-focused, defensive posture
- **Counter**: Other players (AI should recognize this) can attack your trade cities
- **AI awareness**: When a player holds 2+ trade crossroads and 5000+ gold, AI should prioritize attacking their markets
- **Thematic**: "Your merchants control every trade route. Gold flows through your coffers like water. The other kingdoms are economically dependent on your generosity."

### 2.3 Military Victory (new)
- **Condition**: Win 15 battles AND have the strongest single army on the map (by total strength)
- **Playstyle**: Aggressive, combat-focused, quality over quantity
- **Tracking**: New field `battlesWon: int` per player
- **Thematic**: "Your armies are legendary. No force can stand against you. Enemy soldiers flee at the sight of your banner."

### 2.4 Imperial Victory (new)
- **Condition**: Upgrade 5 villages to City level (level 5)
- **Playstyle**: Tall empire (few but powerful cities), long-term investment
- **Cost**: Massive resource investment per city upgrade
- **Counter**: AI should target high-level villages for conquest
- **Thematic**: "Five great cities stand as monuments to your civilization. Your empire will endure for a thousand years."

### Victory System Architecture

```dart
// New file: lib/data/models/victory_condition.dart

enum VictoryType {
  domination,   // Control 70% of villages
  economic,     // 10000 gold + 3 trade crossroads
  military,     // 15 battles won + strongest army
  imperial,     // 5 cities at level 5
}

class VictoryProgress {
  final VictoryType type;
  final double progress;    // 0.0 to 1.0
  final String description; // "3/5 cities upgraded"
  final bool achieved;
}
```

**Integration:**
- `game_manager.dart`: Add `battlesWon: Map<String, int>` tracking per player
- `turn_engine.dart`: Check ALL victory conditions each turn (not just elimination)
- `finalizeBattle()`: Increment `battlesWon` for winner
- UI: Victory progress panel showing all 4 conditions with progress bars
- Pre-game: Player selects which victory they're pursuing (affects AI behavior toward them)

### AI Victory Awareness

AI should:
1. Track its own closest victory condition and pursue it
2. Recognize when human player is close to winning and counter:
   - Economic: Attack trade cities
   - Military: Avoid giving easy battles, turtle up
   - Imperial: Target high-level villages
   - Domination: Form temporary alliances against leader

---

# PILLAR 3: PERSISTENT PROGRESSION

## Concept

Unlockables, achievements, and meta-progression that carry across games. Stored locally via `shared_preferences` (already a dependency).

### 3.1 Achievement System

**Combat Achievements:**
- "First Blood" - Win your first battle
- "Undefeated" - Win a game without losing a single battle
- "David vs Goliath" - Win a battle outnumbered 2:1
- "Blitzkrieg" - Conquer 3 villages in 5 turns
- "Last Stand" - Win a battle with fewer than 5 units remaining
- "Cavalry Master" - Win a battle using only cavalry units
- "Arrow Storm" - Kill 20+ units with ranged in a single battle

**Economic Achievements:**
- "Merchant Prince" - Accumulate 5000 gold in a single game
- "Breadbasket" - Produce 500 food in a single turn
- "Iron Throne" - Control 5 iron mines simultaneously
- "Master Builder" - Build 30 buildings in a single game

**Strategic Achievements:**
- "Empire Builder" - Control 10+ villages simultaneously
- "Speed Run" - Win a game in under 25 turns
- "Marathon" - Win a game lasting 100+ turns
- "Underdog" - Win as a minor faction (Bulgaria, Serbia, Armenia, Mamluk)
- "World Conqueror" - Win with every faction at least once
- "Survivor" - Win after losing your capital city
- "Fog Master" - Discover all villages before turn 20

**Event Achievements** (once events are added):
- "Mongol Slayer" - Defeat the Mongol invasion army
- "Plague Doctor" - Win a game where plague hit your territory
- "Winter Warrior" - Conquer 2 villages during Harsh Winter

### 3.2 Faction Mastery

Track per-faction stats:
```dart
class FactionStats {
  final Nationality faction;
  int gamesPlayed;
  int gamesWon;
  int totalBattlesWon;
  int totalVillagesConquered;
  int fastestVictoryTurn;
  Map<VictoryType, int> victoriesByType;
}
```

Rewards for faction mastery:
- 1 win: Unlock faction lore card (historical info about that civilization)
- 3 wins: Unlock faction-specific starting bonus for future games (e.g., Ottomans start with extra cavalry)
- 5 wins: Unlock faction-specific event (e.g., "Janissary Corps" event only triggers for Ottoman players with 5+ wins)

### 3.3 Difficulty Levels

| Level | AI Bonus | Event Frequency | Player Handicap |
|-------|----------|-----------------|-----------------|
| Easy | -20% AI resources | Low (fewer negative events) | +500 starting gold |
| Normal | Standard | Standard | Standard |
| Hard | +20% AI resources | High | Standard |
| Legendary | +40% AI resources, AI coordinates attacks | Very High, more negative events | -200 starting gold |

Tracked separately: "Win on Legendary" achievement, per-difficulty win counts.

### 3.4 Game Modifiers (Scenario System)

Selectable before game start. Mix and match for custom challenge:

**Resource Modifiers:**
- "Scarcity" - All production halved
- "Abundance" - All production doubled
- "Iron Age" - Only iron mines produce (no farms, lumber mills, markets produce normally but at 50%)
- "Gold Standard" - Everything costs 2x gold

**Military Modifiers:**
- "Peasant War" - Only militia and spearmen available
- "Knights Only" - Only cavalry units available
- "No Fortress" - Fortresses disabled (pure offense meta)

**Map Modifiers:**
- "Fog Eternal" - Vision range halved permanently
- "Open Book" - No fog of war at all
- "Contested Center" - Neutral super-village in map center with 50 garrison

**Pacing Modifiers:**
- "Blitz" - Game ends at turn 30, highest score wins
- "Marathon" - All costs and production halved (longer game)
- "Sudden Death" - Lose 1 village = eliminated

### 3.5 Score System

End-of-game score for leaderboard/tracking:

```
Score = (Villages Controlled * 100)
      + (Battles Won * 50)
      + (Total Population * 0.1)
      + (Gold Accumulated * 0.05)
      + (Difficulty Multiplier: Easy 0.5x, Normal 1x, Hard 1.5x, Legendary 2x)
      + (Speed Bonus: max(0, (60 - turnCount) * 10))
      + (Modifier Bonuses: each active challenge modifier +10%)
      + (Victory Type Bonus: Domination 0, Economic +200, Military +300, Imperial +500)
```

Stored per game:
```dart
class GameRecord {
  final DateTime date;
  final Nationality faction;
  final VictoryType? victoryType; // null if lost
  final int score;
  final int turns;
  final int battlesWon;
  final int villagesConquered;
  final String difficulty;
  final List<String> activeModifiers;
}
```

---

# IMPLEMENTATION ROADMAP

## Phase 1: Victory Conditions + Score (Foundation)
**Estimated scope: ~8 new/modified files**

What to build:
1. `VictoryCondition` model + `VictoryType` enum
2. Victory checking logic in `turn_engine.dart` (replace single elimination check)
3. `battlesWon` tracking in `game_manager.dart`
4. Victory progress UI in side panel (progress bars for each condition)
5. Updated victory screen showing victory type, score breakdown
6. Score calculation engine
7. Pre-game victory selection (add to nationality selection screen)

Why first: Gives immediate replayability. "Can I win economically?" is a new game right there.

Key files to modify:
- `lib/engines/turn_engine.dart` - victory check expansion
- `lib/engines/game_manager.dart` - new state fields (battlesWon, selectedVictory)
- `lib/ui/screens/victory_screen.dart` - score display, victory type
- `lib/ui/screens/nationality_selection_screen.dart` - victory type picker
- `lib/ui/panels/side_info_panel.dart` - victory progress
- `lib/ui/panels/inline_village_panel.dart` - victory progress (mobile)

New files:
- `lib/data/models/victory_condition.dart`
- `lib/engines/victory_engine.dart`

## Phase 2: Event System (Variety)
**Estimated scope: ~6 new/modified files**

What to build:
1. `GameEvent` model
2. `EventEngine` with trigger/probability/effect system
3. Event processing phase in turn engine
4. Event notification UI (popup + active events panel)
5. AI event awareness (modify all 3 AI managers)
6. Mongol invasion as special army entity

Why second: Maximum gameplay variety per line of code. Events make every game feel different.

Key files to modify:
- `lib/engines/turn_engine.dart` - new event phase
- `lib/engines/game_manager.dart` - activeEvents state
- `lib/engines/ai_strategy_manager.dart` - event-aware targeting
- `lib/engines/ai_economy_manager.dart` - event-reactive building
- `lib/data/models/turn_event.dart` - new event display types
- `lib/ui/panels/side_info_panel.dart` - active events display

New files:
- `lib/data/models/game_event.dart`
- `lib/engines/event_engine.dart`

## Phase 3: Persistent Progression (Retention)
**Estimated scope: ~5 new/modified files**

What to build:
1. `Achievement` model + definitions
2. `GameRecord` model for game history
3. `FactionStats` tracking
4. Local persistence via shared_preferences
5. Achievement notification UI
6. Stats/history screen accessible from main menu
7. Difficulty selection

Why third: Needs victory conditions and events to exist first (many achievements reference them).

New files:
- `lib/data/models/achievement.dart`
- `lib/data/models/game_record.dart`
- `lib/engines/progression_engine.dart`
- `lib/ui/screens/stats_screen.dart`

Key files to modify:
- `lib/ui/screens/nationality_selection_screen.dart` - difficulty picker, modifier toggles
- `lib/engines/game_manager.dart` - difficulty modifiers
- `lib/ui/screens/victory_screen.dart` - achievement popups, save game record

## Phase 4: Game Modifiers + AI Victory Pursuit (Polish)
**Estimated scope: ~4 modified files**

What to build:
1. Modifier system (pre-game toggles)
2. AI victory condition pursuit (AI picks and chases a victory type)
3. AI counter-strategy (recognize player's victory path, counter it)
4. Difficulty-based AI bonuses

Key files to modify:
- `lib/engines/ai_strategy_manager.dart` - victory pursuit + counter-strategy
- `lib/engines/ai_economy_manager.dart` - difficulty bonuses
- `lib/engines/ai_military_manager.dart` - difficulty bonuses
- `lib/ui/screens/nationality_selection_screen.dart` - modifier UI

---

# WHAT THIS GIVES YOU

## Before (current state):
- Player picks faction -> builds economy -> builds army -> conquers everything -> trophy screen -> done
- Every game identical. No reason to replay.

## After:
- Player picks faction + victory type + difficulty + modifiers
- Turn 8: Drought hits, scramble to feed armies
- Turn 15: Trade caravan opportunity, race cavalry to intercept
- Turn 22: Royal Marriage between Ottomans and Mamluks, forced to change attack plans
- Turn 30: Close to economic victory, AI recognizes threat and attacks trade cities
- Turn 40: Mongol invasion, everyone pivots to defense
- Turn 45: Win economic victory on Hard difficulty
- Unlock "Merchant Prince" + "Fog Master" achievements
- Score: 4,850 (personal best for Byzantines)
- See progress: 2/5 wins needed for Byzantine faction mastery
- Next game: "Let me try Military Victory as Ottomans on Legendary with Fog Eternal modifier"

That's 4+ distinct game experiences from the same codebase. The replayability comes from the combinatorial explosion of:
- 7 factions x 4 victory types x 4 difficulties x N modifier combos x random events = hundreds of unique game experiences

---

# PRIORITY CALLS

If you can only do ONE thing: **Multiple Victory Conditions**. It's the lowest-effort, highest-impact change. 4 new win conditions immediately triple replayability.

If you can do TWO things: Add **Event System**. Random events + victory conditions together create emergent storytelling.

If you can do THREE things: Add **Achievements + Score**. Now players have long-term goals across games.

The modifier system and AI victory pursuit are polish - nice to have, but the first three pillars carry the weight.
