# Battle Mechanism

## Design Philosophy

**"Medieval Total War without micro-management"**

- Player controls: army composition + formation selection
- No micro: once battle starts, simulation runs automatically
- Outcome determined by: composition synergies + formation matchup + luck
- Blind picks: player chooses formation, then AI reveals its choice

The strategic depth comes from building the right army composition and predicting what formation the enemy will pick based on their army.

---

## Battle Initiation

1. Player sends army to hostile village via army menu
2. Travel time calculated based on distance
3. When army arrives (`turnsUntilArrival == 0`), combat triggers
4. `ResolveCombatUseCase` executes battle resolution

---

## Army Composition

### Unit Types (7 total, 3 categories)

| Category | Units | Key Traits |
|----------|-------|------------|
| **Infantry** | Militia, Spearman, Swordsman | High HP, solid defense |
| **Ranged** | Archer, Crossbowman | High accuracy, weak in melee |
| **Cavalry** | Light Cavalry, Knight | High movement, kill potential |

### Unit Stats Example (Spearman)
- Attack: 7, Defense: 8, HP: 70
- Cost: 30 Gold + 5 Iron
- Upkeep: 2 Gold + 1 Food
- BaseKillRate: 0.35

### Building Bonuses (applied at unit creation)
- **Barracks** (Infantry): +1 ATK, +2 DEF per level
- **Archery Range** (Ranged): +1 ATK, +3% accuracy per level
- **Stables** (Cavalry): +1 ATK, +0.1 kill potential per level

---

## Three-Phase Combat System

### Phase 1: Ranged Volley
- Archers fire simultaneously
- Accuracy: `min(0.90, (baseAccuracy + archeryLevelBonus) × luck × formationMod)`
- Archery level adds 3% accuracy per level (capped at 90%)
- Targets: infantry first, then ranged, cavalry last

### Phase 2: Cavalry Charge
- Cavalry units charge with kill potential
- Kill potential: `(base + stablesBonus) × luck × formationMod × counterMod`
- Light Cavalry: 1.5 base, Knight: 2.5 base
- **Spearmen counter cavalry:** 0.8× modifier (cavalry deal 20% less to spearmen)
- Targets: ranged first (soft targets), then infantry

### Phase 3: Melee Clash
- Only **Infantry** and **Cavalry** engage in melee
- Kill rate: `(base + infantryBonus) × luck × formationMod × counterMod`
- Militia: 0.25, Spearman: 0.35, Swordsman: 0.50
- **Spearmen bonus vs cavalry:** +25% damage to cavalry
- **Archers do NOT participate** - they hold position in rear

### Archer Behavior (Proposed Change)
**Current:** Archers fight in melee with 0.5× penalty
**New:** Archers never engage in melee unless directly attacked

Rules:
1. Archers only fire during Ranged Volley phase
2. During Melee Clash, archers hold position (do not deal damage)
3. Archers only take damage if:
   - All infantry/cavalry on their side are dead (enemy reaches them)
   - Enemy cavalry specifically targets them during Cavalry Charge
4. If engaged in melee, archers defend poorly (0.1 kill rate) but can still die

This requires **unit individuality** - tracking each soldier's state rather than just counts.

### Luck System
- Each phase: both sides roll d100 (1-100)
- Modifier: `0.85 + (d100/100) × 0.30` = range 0.85-1.15

---

## Battle Formations (Rock-Paper-Scissors)

| Formation | Beats | Loses To | Best For |
|-----------|-------|----------|----------|
| **Shield Wall** | Crescent (+2%) | Skirmish (-2%) | Infantry protecting archers |
| **Crescent** | Skirmish (+2%) | Shield Wall (-2%) | Cavalry-dominant armies |
| **Skirmish** | Shield Wall (+2%) | Crescent (-2%) | Archer-heavy armies |

### Formation Selection Logic

**Both sides pick blindly** - based only on their OWN army composition, not the enemy's.

**AI Selection** (based on its own ratios):
```
cavalryRatio = myCavalry / myTotal
archerRatio  = myArchers / myTotal
infantryRatio = myInfantry / myTotal

if cavalryRatio > 0.4:
    → Crescent (leverage cavalry charge)
elif archerRatio > 0.4 AND infantryRatio < 0.3:
    → Guerilla (maximize ranged phase)
elif infantryRatio > 0.3 AND archerRatio > 0.2:
    → Roman (infantry protects archers)
else:
    → Roman (safe default)
```

**Player:** Can see enemy army composition on map, but must guess their formation.

### Strategic Mind Games

Since AI picks based on its own army, you can predict:

| Enemy has... | AI will likely pick... | You should pick... |
|--------------|------------------------|-------------------|
| Many cavalry (>40%) | Crescent | Roman (counters Crescent) |
| Many archers, few infantry | Guerilla | Crescent (counters Guerilla) |
| Balanced / infantry-heavy | Roman | Guerilla (counters Roman) |

The skill: scout enemy composition → predict their formation → pick the counter.

---

## Casualty Priority

| Phase | Order |
|-------|-------|
| Ranged | Infantry → Ranged → Cavalry |
| Cavalry | Ranged → Infantry → Cavalry |
| Melee | Infantry → Ranged → Cavalry |

---

## Battle Resolution

### Winner Determination
```
attackerWon = defenderUnits.isEmpty ||
              (attackerUnits.isNotEmpty && attackerUnits.length > defenderUnits.length)
```

### If Attacker Wins
1. Remove attacker casualties
2. Destroy defender armies
3. Transfer village ownership
4. Destroy garrison
5. Check defender elimination

### If Defender Wins
1. Destroy attacking army
2. Apply defender casualties
3. Apply garrison casualties
4. Check attacker elimination

### Elimination
Player eliminated if: zero villages AND zero armies

---

## Defensive Bonuses

- **Garrison:** pooled with defender armies
- **Fortress:** grants defender bonus (+1 to legacy dice rolls)

---

## Retreat Rules

**No automatic routing.** Battles fight to the finish.

A battle ends ONLY when:
1. One side has zero units remaining, OR
2. Player manually retreats (future feature)

### Current Behavior (to remove)
- Morale-based routing at <20% morale
- Units flee mid-battle

### New Behavior
- No morale routing - units fight until dead
- Morale is visual-only (affects animations, not outcome)
- Manual retreat option (player only, AI never retreats)

---

## Unit Individuality (Proposed)

Currently armies track unit **counts** (e.g., 10 archers, 5 spearmen). To implement proper archer behavior, we need individual unit tracking.

### Individual Soldier Entity
```dart
class Soldier {
  final String id;
  final UnitType type;
  int currentHp;
  SoldierState state; // fighting, holding, routing, dead
  Position? position; // for visual simulation
}

enum SoldierState {
  fighting,   // actively engaging
  holding,    // archers waiting in rear
  routing,    // fleeing (morale broken)
  dead
}
```

### Army Refactor
```dart
// Current
class Army {
  Map<UnitType, int> units; // type → count
}

// Proposed
class Army {
  List<Soldier> soldiers;

  int countByType(UnitType type) => soldiers.where((s) => s.type == type && s.state != SoldierState.dead).length;
}
```

### Combat Engine Changes
1. **Ranged Phase:** Archers fire, state remains `holding`
2. **Cavalry Phase:** Cavalry targets soldiers by priority, updates individual HP
3. **Melee Phase:**
   - Infantry/Cavalry with `fighting` state engage
   - Archers remain `holding` unless no friendlies left → forced to `fighting`
4. **Death:** When `currentHp <= 0`, state → `dead`

### Migration Path
- Keep `Map<UnitType, int>` for army display/management
- Generate `List<Soldier>` at battle start
- Convert back to counts after battle for survivors

---

## Key Files

| File | Purpose |
|------|---------|
| `lib/engines/combat_engine.dart` | Core 3-phase combat |
| `lib/domain/services/combat_service.dart` | Legacy dice combat |
| `lib/application/use_cases/combat/resolve_combat.dart` | Battle state changes |
| `lib/data/models/combat_log.dart` | Battle records |
| `lib/data/models/unit_type.dart` | Unit stats & abilities |
| `lib/domain/entities/army.dart` | Army composition |
| `lib/ui/screens/battle/battle_simulation.dart` | Visual battle |

========================================================================
So far, was a draft documentation
Now we are in iteration 2. Everything in this doc, overrides the previous parts of this document. 

We are heading towards a Total War battle simulation.

Decisions of the soldiers must happen real time. For every one of them. 

### Infantry

**Militia** -> Cheap cannon fodder. Quick to recruit, first to die. Useful for padding numbers and absorbing arrows.

Missile: 0
Attack: 3 (+levels)
Defense: 3 (+levels)
HP: 50
Speed: 1 (+levels)

**Spearman** -> Anti-cavalry specialists. Form defensive lines, protect archers. Excel at holding ground.

Missile: 0
Attack: 4 (+levels)
Defense: 7 (+levels)
HP: 70
Speed: 1 (+levels)
Anti-Cavalry: 1.25x damage vs cavalry

**Swordsman** -> Elite infantry. High damage output, decent survivability. Best for aggressive pushes.

Missile: 0
Attack: 6 (+levels)
Defense: 5 (+levels)
HP: 80
Speed: 1 (+levels)

### Ranged

**Archer** -> Light skirmishers. Fast rate of fire, lower damage per shot. Flexible positioning.

Missile: 6 (+levels)
Attack: 1 (+levels)
Defense: 2 (+levels)
HP: 50
Speed: 1 (+levels)
Range: 8
Ammo: 24
Accuracy: 65%
Fire Rate: 1.5 seconds

**Crossbowman** -> Heavy ranged. Slower fire rate, devastating damage. Better armor penetration.

Missile: 8 (+levels)
Attack: 2 (+levels)
Defense: 3 (+levels)
HP: 60
Speed: 1 (+levels)
Range: 7
Ammo: 16
Accuracy: 75%
Fire Rate: 3.0 seconds

### Cavalry

**Light Cavalry** -> Fast raiders. Flanking, archer hunting, chasing routers. Fragile in prolonged melee.

Missile: 0
Attack: 7 (+levels)
Defense: 3 (+levels)
HP: 70
Speed: 4 (+levels)
Charge: 4 (decays in prolonged melee)

**Knight** -> Heavy shock cavalry. Devastating charge, can brawl in melee. Expensive but decisive.

Missile: 0
Attack: 9 (+levels)
Defense: 5 (+levels)
HP: 100
Speed: 3 (+levels)
Charge: 7 (decays in prolonged melee)

---

## Formations

Three formations, each with distinct positioning that creates real tactical advantages/disadvantages.

### Shield Wall
Infantry forms a tight defensive line in front, ranged behind, cavalry on flanks.

**Positioning:**
```
        [Ranged]
   [Infantry Infantry Infantry]
[Cavalry]                    [Cavalry]
```

**Mechanics:**
- Infantry gets +3% Defense (tight formation)
- Ranged gets +1 Range (elevated firing position)
- Own Cavalry Charge reduced by 5%
- Movement speed -3%

**Strong vs:** Crescent - cavalry charge gets negated by the wall
**Weak vs:** Skirmish - spread-out enemies minimize effectiveness

---

### Crescent
Cavalry-forward formation. Wings wrap around to encircle.

**Positioning:**
```
[Light Cav]           [Light Cav]
      [Knights]  [Knights]
         [Infantry]
           [Ranged]
```

**Mechanics:**
- Cavalry gets +5% Charge bonus
- Infantry and Ranged get -2% Defense (slightly exposed)
- If cavalry dies early, remaining units are vulnerable

**Strong vs:** Skirmish - cavalry catches spread-out skirmishers
**Weak vs:** Shield Wall - charge is less effective against the wall

---

### Skirmish
Loose, spread formation. Mobile harassment, avoid direct engagement.

**Positioning:**
```
[Archer]     [Archer]     [Archer]
   [Infantry]   [Infantry]
      [Cavalry]   [Cavalry]
```

**Mechanics:**
- All units get +3% Speed (loose formation)
- Ranged gets +1 Range
- -3% damage taken from enemy ranged (spread targets)
- Melee units get -2% Attack (isolated fights)
- Enemy Charge reduced by 3%

**Strong vs:** Shield Wall - more mobile, can outmaneuver
**Weak vs:** Crescent - cavalry catches isolated units

---

## Formation Counter Summary

| Formation | Beats | Loses To | Ideal Army |
|-----------|-------|----------|------------|
| **Shield Wall** | Crescent (+2%) | Skirmish (-2%) | Infantry-heavy with ranged support |
| **Crescent** | Skirmish (+2%) | Shield Wall (-2%) | Cavalry-dominant |
| **Skirmish** | Shield Wall (+2%) | Crescent (-2%) | Ranged-heavy, mobile |

The +2%/-2% represents overall combat effectiveness modifier applied to damage calculations.

### Formation Modifiers (Detailed)

**Shield Wall:**
- Infantry gets +3% Defense
- Ranged gets +1 Range
- Own Cavalry Charge reduced by 5%
- Movement speed -3%

**Crescent:**
- Cavalry gets +5% Charge bonus
- Infantry and Ranged get -2% Defense

**Skirmish:**
- All units get +3% Speed
- Ranged gets +1 Range
- -3% damage taken from enemy ranged
- Melee units get -2% Attack
- Enemy Charge reduced by 3%

---

## Defender Bonuses

Defending armies fight on home turf with significant advantages.

### Base Defender Bonus
- All defending units: +10% Defense (familiar terrain, prepared positions)

### Fortress Bonus (per level)
| Fortress Level | Defense Bonus | Ranged Bonus | Cavalry Penalty | Notes |
|----------------|---------------|--------------|-----------------|-------|
| 0 (none) | +0% | +0 Range | 0% | No fortifications |
| 1 (Palisade) | +5% Defense | +1 Range | -5% | Wooden walls |
| 2 (Stone Walls) | +10% Defense | +1 Range | -10% | Solid fortifications |
| 3 (Castle) | +15% Defense | +1 Range | -15% | Major stronghold |

### Fortress Effects
- **Defense bonus:** Applies to all defending units (walls provide cover)
- **Range bonus:** Ranged units shoot from elevated positions
- **Cavalry penalty:** Attacking cavalry Charge reduced (no room to charge)

### Combined Example
Defender at Level 2 Fortress:
- Fortress: +10% Defense
- Ranged: +1 Range
- Enemy cavalry: -10% Charge bonus

---

## Combat Mechanics

### Damage Formula
```
baseDamage = Attack * (100 / (100 + Defense))
finalDamage = baseDamage * typeMultiplier * formationMod * randomVariance
```

- **typeMultiplier:** Unit counter bonuses (e.g., Spearman 1.25x vs Cavalry)
- **formationMod:** Formation advantage/disadvantage (0.98 to 1.02)
- **randomVariance:** 0.9 to 1.1 (±10% per hit)

### Melee Combat
- Units within **melee range (1 unit)** attack each other
- Attack interval: **1 second** per swing
- Both units in melee deal damage simultaneously

### Ranged Combat
- Archers fire at targets within Range
- **Archer fire rate:** 1 shot per 1.5 seconds (fast)
- **Crossbowman fire rate:** 1 shot per 3 seconds (slow, heavy)
- Damage on hit: `Missile * (100 / (100 + targetDefense)) * accuracy roll`
- When out of ammo, ranged units use melee Attack stat

### Charge Mechanics
- Cavalry gains **Charge bonus** when first contacting an enemy
- Charge damage: `(Attack + Charge) * damageFormula`
- **Decay:** Charge bonus reduces by 1 per second while in melee
- Once Charge reaches 0, cavalry fights with base Attack only
- Charge resets if cavalry disengages for 3+ seconds

### Engagement Rules
| Unit Type | Engagement Distance | Behavior |
|-----------|---------------------|----------|
| Infantry | 1 (melee only) | Move toward nearest enemy, engage |
| Ranged | Range stat | Fire at priority target, flee if enemy within 2 |
| Cavalry | 1 (melee) | Charge nearest priority target |

### Target Priority (AI)
| Unit Type | Priority Order |
|-----------|----------------|
| Infantry | Enemy Infantry > Archers > Cavalry |
| Archers | Enemy Infantry > Cavalry > Archers |
| Cavalry | Enemy Archers > Cavalry > Infantry |

Units attack the highest priority target within range. If none available, move toward nearest enemy.

### Archer Melee Behavior
- If enemy is within **2 units**, archer attempts to retreat
- If enemy is within **1 unit** (melee range), archer is forced to fight
- Archers use Attack stat in melee (very weak)

---

## Victory Conditions

**No morale. No routing. Fight to the death.**

### Battle End
Battle ends when one side has **zero living units**.

### Winner Determination
```
if (defenderUnits == 0 && attackerUnits > 0) → Attacker wins
if (attackerUnits == 0 && defenderUnits > 0) → Defender wins
if (both == 0) → Mutual destruction (defender keeps village)
```

### Post-Battle
- **Attacker wins:** Conquers village, surviving units occupy
- **Defender wins:** Attacker army destroyed, survivors heal over time
- **Mutual destruction:** Village stays with defender (no garrison)

---

## Battlefield

### Dimensions
- **Size:** 100 x 60 units (width x depth)
- **Spawn zones:** Each side spawns in their half (0-30 for attackers, 70-100 for defenders)

### Movement
- Speed stat = units moved per second
- Speed 1 = 1 unit/sec, Speed 4 = 4 units/sec
- Diagonal movement: same speed (no penalty)

### Collision
- Units cannot overlap
- Melee units form a "battle line" when engaging
- Max 3 units can attack a single target simultaneously

---

## Simulation Timing

### Tick Rate
- **Logic tick:** 10 times per second (100ms intervals)
- **Visual update:** 60 FPS (interpolated positions)

### Battle Duration
- Typical battle: 30-90 seconds real-time
- Large battles (50+ units per side): up to 2 minutes

### Speed Controls
- **1x:** Real-time
- **2x:** Fast forward
- **Skip:** Instant resolve (no animation, just result)

---

## Unit Behavior Summary

| Unit | Move Toward | Attack Priority | Special |
|------|-------------|-----------------|---------|
| Militia | Nearest enemy | Infantry > Archers > Cav | Cheap, weak |
| Spearman | Nearest enemy | Cavalry > Infantry > Archers | 1.25x vs Cavalry |
| Swordsman | Nearest enemy | Infantry > Archers > Cav | High damage |
| Archer | Stay at range | Infantry > Cav > Archers | Retreat if approached |
| Crossbowman | Stay at range | Infantry > Cav > Archers | Slow, high damage |
| Light Cavalry | Archers first | Archers > Cav > Infantry | Fast, fragile |
| Knight | Archers first | Archers > Infantry > Cav | Heavy charge |

