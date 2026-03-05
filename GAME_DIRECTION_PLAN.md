# VillagesTown - Strategic Direction Plan

## Overview

Four phases were implemented to transform VillagesTown from a single-playthrough conquest game into a replayable strategy game with variety, progression, and meaningful choices.

**Replayability formula:** 7 factions x 4 victory types x 4 difficulties x 9 modifiers x random events = hundreds of unique games.

---

## Phase 1: Victory Conditions + Score System

**4 victory types** beyond simple elimination:

| Type | Condition | Score Bonus |
|------|-----------|-------------|
| Domination | Control 70% of all villages | +0 |
| Economic | 10,000 gold + 3 Trade Crossroads | +200 |
| Military | 15 battle wins + strongest army | +300 |
| Imperial | 5 villages at City level | +500 |

**Score formula:** Villages (x100) + Battles (x50) + Population (x0.1) + Gold (x0.05) + Speed Bonus + Victory Bonus, multiplied by difficulty and modifier multipliers.

Player selects a target victory type pre-game (bonus if they win by that type). Progress bars shown in-game for all 4 conditions.

**Files:** `victory_condition.dart`, `victory_engine.dart`, plus modifications to `turn_engine.dart`, `game_manager.dart`, `victory_screen.dart`, `nationality_selection_screen.dart`, `side_info_panel.dart`, `inline_village_panel.dart`

---

## Phase 2: World Event System

**11 event types** that fire randomly during gameplay:

| Category | Events |
|----------|--------|
| Natural | Drought (food -50%), Harsh Winter (movement penalty), Earthquake (destroys building), Bountiful Harvest (food x2) |
| Economic | Gold Rush (gold x3 at village), Trade Caravan (gold+food reward) |
| Military | Mercenary Company (hireable army), Rebellion (village defects to neutral) |
| Political | Royal Marriage (AI non-aggression pact), Crusade Called (Crusader buff), Civil War (leading player loses village) |

Events have turn ranges, probability rolls, duration tracking, and one-time caps. Production modifiers are queried by `BuildingProductionEngine`. AI respects non-aggression pacts and movement penalties.

**Files:** `game_event.dart`, `event_engine.dart`, plus modifications to `turn_engine.dart`, `game_manager.dart`, `building_production_engine.dart`, `ai_strategy_manager.dart`, `turn_event.dart`, `side_info_panel.dart`, `inline_village_panel.dart`

---

## Phase 3: Persistent Progression

**17 achievements** across categories: combat (firstBlood, undefeated, blitzkrieg, cavalryMaster), economic (merchantPrince), strategic (empireBuilder, speedRun, marathon, underdog, worldConqueror, survivor), victory-specific (economicVictor, militaryVictor, imperialVictor), and event-related (winterWarrior, earthquakeSurvivor).

**4 difficulty levels:**

| Level | AI Resources | Starting Gold | Score Multiplier |
|-------|-------------|---------------|-----------------|
| Easy | 0.8x | +500 | 0.5x |
| Normal | 1.0x | +0 | 1.0x |
| Hard | 1.2x | +0 | 1.5x |
| Legendary | 1.4x | -200 | 2.0x |

**Game records** persisted via SharedPreferences (last 50 games). Stats screen shows overview, achievements (locked/unlocked), faction win breakdown, and recent game history.

**Files:** `achievement.dart`, `game_record.dart`, `difficulty.dart`, `progression_engine.dart`, `stats_screen.dart`, plus modifications to `game_manager.dart`, `turn_engine.dart`, `victory_engine.dart`, `victory_condition.dart`, `building_production_engine.dart`, `victory_screen.dart`, `nationality_selection_screen.dart`

---

## Phase 4: Game Modifiers + AI Victory Pursuit

**9 pre-game modifiers** with conflict detection and score multipliers:

| Category | Modifier | Effect | Score Mult |
|----------|----------|--------|-----------|
| Resource | Scarcity | All production halved | 1.15x |
| Resource | Abundance | All production doubled | 0.8x |
| Resource | Gold Standard | Everything costs 2x gold | 1.1x |
| Military | Peasant War | Only militia and spearmen | 1.2x |
| Military | No Fortress | Fortresses disabled | 1.1x |
| Map | Fog Eternal | Vision range halved | 1.15x |
| Map | Open Book | No fog of war | 0.9x |
| Pacing | Blitz | Game ends at turn 30 | 1.2x |
| Pacing | Sudden Death | Lose 1 village = eliminated | 1.25x |

Conflicting modifiers (Scarcity/Abundance, Fog Eternal/Open Book) cannot be selected together. Modifiers are applied across BuildingProductionEngine, BuildingConstructionEngine, RecruitmentEngine, TurnEngine, and VictoryEngine.

**AI Victory Pursuit:**
- AI evaluates all 4 victory types weighted by personality and picks the closest one
- Economy manager adjusts building priorities (markets for economic, barracks for military, farms for imperial)
- Military manager adjusts recruitment thresholds (aggressive for military goal, conservative for economic)
- Strategy manager adds targeting bonuses aligned with victory goal

**AI Counter-Strategy (triggers at 70%+ player progress):**
- Player near Domination: AI prioritizes attacking player villages
- Player near Economic: AI targets trade crossroads (+40 targeting bonus)
- Player near Military: AI turtles up (-20 targeting bonus, avoids giving easy battles)
- Player near Imperial: AI targets player's cities (+40 targeting bonus)

**Files:** `game_modifier.dart`, plus modifications to `game_manager.dart`, `building_production_engine.dart`, `building_construction_engine.dart`, `recruitment_engine.dart`, `turn_engine.dart`, `victory_engine.dart`, `victory_condition.dart`, `victory_screen.dart`, `ai_strategy_manager.dart`, `ai_economy_manager.dart`, `ai_military_manager.dart`, `nationality_selection_screen.dart`
