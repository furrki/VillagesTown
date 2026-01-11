# AI Strategy System

## Overview

The AI strategy system governs how computer-controlled nations behave each turn. Strategy is **situational** - determined by the nation's current state, not its identity. Culture only provides **bias** toward certain behaviors, not locked strategies.

---

## Core Principle: Situation Drives Strategy

```
Strategy = f(CurrentSituation) + CultureBias
```

A defensive culture (e.g., Armenia) will still go Offensive when they have 3:1 military advantage. An aggressive culture (e.g., Ottomans) will still go Defensive when surrounded and outnumbered. Culture shifts the **thresholds**, not the logic.

---

## Strategy Types

### Offensive
**Goal:** Expand territory aggressively, prioritize military over economy.

**Situational Triggers:**
- Military strength ratio vs weakest neighbor ≥ 1.5 (culture adjusts this)
- Resource surplus: gold > 3 turns of upkeep
- At least one viable target (weak garrison, isolated)
- No critical threats at home (garrison > 60% in border villages)

**Budget Allocation:**
- Military: 60%
- Economy: 25%
- Reserve: 15%

**Behavior:**
- Recruit offensive units (cavalry, knights)
- Target weakest neighbor first
- Launch attacks when ready
- Accept moderate casualties for conquest
- Build Barracks and Iron Mines

---

### Defensive
**Goal:** Protect existing territory, recover strength.

**Situational Triggers:**
- Military strength ratio vs strongest threat ≤ 0.8
- Recently lost territory (last 5 turns)
- Resources below sustainable level (gold < 2 turns upkeep)
- Multiple hostile neighbors with armies near border
- Any village under siege

**Budget Allocation:**
- Military: 35%
- Economy: 45%
- Reserve: 20%

**Behavior:**
- Recruit defensive units (spearmen, crossbowmen)
- Upgrade fortresses in border villages
- Keep armies stationed at home
- Only attack if overwhelming advantage (3:1+)
- Build Fortresses and Farms

---

### Progressive (Economic Growth)
**Goal:** Build economic foundation, opportunistic expansion.

**Situational Triggers:**
- No immediate threats (no enemy armies within 2 moves)
- Military strength roughly equal to neighbors (0.8 - 1.5 ratio)
- Economic potential exists (unupgraded buildings)
- Stable borders (no recent battles)

**Budget Allocation:**
- Military: 40%
- Economy: 50%
- Reserve: 10%

**Behavior:**
- Build economic infrastructure first
- Maintain garrison strength but don't over-recruit
- Attack only easy targets (neutrals, isolated villages)
- Invest in Markets, Farms, Lumber Mills

---

## Turn-by-Turn AI Decision Flow

```
┌─────────────────────────────────────────────────────────┐
│                    START OF TURN                         │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│  1. SITUATION ASSESSMENT                                 │
│     - Count resources (gold, food, iron, wood)          │
│     - Evaluate military strength                         │
│     - Identify neighbors and their strength             │
│     - Check for active threats (sieges, nearby armies)  │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│  2. STRATEGY SELECTION                                   │
│     - Based on situation + nation personality           │
│     - Can override personality in crisis                │
│     - Determines budget allocation                       │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│  3. BUDGET PLANNING                                      │
│     - Calculate available income this turn              │
│     - Allocate to: Military, Economy, Reserve           │
│     - Set spending caps for each category               │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│  4. NEIGHBOR ANALYSIS                                    │
│     - For each neighbor village (enemy or neutral):     │
│       • Calculate distance                               │
│       • Estimate garrison + reinforcement potential     │
│       • Assess strategic value                           │
│       • Rate as: Target, Threat, or Neutral             │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│  5. EXECUTE ACTIONS                                      │
│     - Economy: Build/upgrade within budget              │
│     - Military: Recruit within budget                   │
│     - Strategy: Move armies based on targets/threats    │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                     END OF TURN                          │
└─────────────────────────────────────────────────────────┘
```

---

## Neighbor Recognition System

### Neighbor Categories

**Immediate Neighbors (Tier 1)**
- Villages within 1 move (direct connection in neighbor graph)
- Highest priority for both defense and offense
- Always tracked in detail

**Extended Neighbors (Tier 2)**
- Villages 2 moves away
- Relevant for planning ahead
- May become threats if Tier 1 falls

**Distant (Tier 3+)**
- Beyond 2 moves
- Only considered for long-term strategy
- Usually ignored for tactical decisions

### Neighbor Threat Assessment

For each neighbor, calculate a **Threat Score**:

```
ThreatScore =
    (enemy_army_strength / our_nearest_garrison) * 50
  + (enemy_total_military / our_total_military) * 30
  + (enemy_personality_aggression) * 20
  - (distance_in_turns) * 10
```

**Threat Levels:**
- **Critical (80+):** Immediate danger, switch to Defensive
- **High (50-79):** Reinforce border, prepare defense
- **Medium (25-49):** Monitor, maintain garrison
- **Low (<25):** Safe, can ignore for now

### Neighbor Opportunity Assessment

For each neighbor, calculate an **Opportunity Score**:

```
OpportunityScore =
    (our_army_strength / enemy_garrison) * 40
  + (strategic_value) * 25
  + (enemy_low_morale_bonus) * 15
  + (we_have_surplus_military) * 10
  - (distance_in_turns) * 10
  - (enemy_reinforcement_potential) * 20
```

**Opportunity Levels:**
- **Prime (70+):** Attack immediately
- **Good (50-69):** Attack if offensive strategy
- **Possible (30-49):** Attack only with overwhelming force
- **Poor (<30):** Don't attack

---

## Budget System

### Income Calculation

Each turn, calculate expected income:

```
expected_gold = sum(village.market_output + village.tax) - army_upkeep
expected_food = sum(village.farm_output) - population_consumption
expected_iron = sum(village.mine_output)
expected_wood = sum(village.lumber_output)
```

### Budget Categories

**Military Budget**
- Spent on: Unit recruitment, army upkeep reserve
- Priority units by strategy:
  - Offensive: Knights > Light Cavalry > Swordsman
  - Defensive: Spearman > Crossbowman > Militia
  - Progressive: Balanced mix

**Economy Budget**
- Spent on: Building construction/upgrades
- Priority buildings by strategy:
  - Offensive: Iron Mine > Barracks > Market
  - Defensive: Fortress > Farm > Barracks
  - Progressive: Market > Farm > Lumber Mill

**Reserve Budget**
- Unspent gold kept for emergencies
- Used when: Under attack, opportunity arises, upkeep spike
- Minimum reserve: 2 turns of army upkeep

### Spending Rules

1. **Never go bankrupt** - Always keep 1 turn upkeep in reserve
2. **Complete projects** - Don't start buildings you can't finish
3. **Prioritize threats** - Emergency defense overrides budget
4. **Opportunistic overspend** - Can dip into reserve for high-value attacks

---

## Culture Bias System

Culture does NOT determine strategy. Culture provides **bias values** that shift thresholds and preferences. Every nation can adopt any strategy when the situation demands it.

### Culture Bias Values

| Culture | Aggression | Caution | Economic | Expansion |
|---------|------------|---------|----------|-----------|
| Byzantine | 0.5 | 0.6 | 0.7 | 0.5 |
| Turkic | 0.8 | 0.3 | 0.4 | 0.9 |
| Crusader | 0.9 | 0.2 | 0.3 | 0.8 |
| Mamluk | 0.6 | 0.5 | 0.7 | 0.6 |
| Slavic | 0.4 | 0.7 | 0.5 | 0.4 |
| Armenian | 0.3 | 0.8 | 0.6 | 0.3 |

### How Bias Affects Strategy Selection

**Aggression Bias** adjusts attack thresholds:
```
requiredRatioToAttack = baseRatio - (aggressionBias * 0.5)
// High aggression (0.9): attacks at 1.0x ratio
// Low aggression (0.3): needs 1.35x ratio to attack
```

**Caution Bias** adjusts defense triggers:
```
threatThreshold = baseThreat * (1 + cautionBias * 0.5)
// High caution (0.8): sees threats earlier, defends sooner
// Low caution (0.2): ignores minor threats, stays aggressive
```

**Economic Bias** adjusts Progressive preference:
```
progressiveScore += economicBias * 20
// High economic (0.7): more likely to choose Progressive
// Low economic (0.3): rarely chooses Progressive unless forced
```

**Expansion Bias** adjusts target value:
```
neutralTargetValue *= (1 + expansionBias * 0.3)
// High expansion (0.9): values neutral targets highly
// Low expansion (0.3): only attacks when necessary
```

### Strategy Selection Formula

```dart
double offensiveScore = 0;
double defensiveScore = 0;
double progressiveScore = 0;

// Situation factors (primary)
offensiveScore += (strengthRatio - 1.0) * 50;  // Advantage
offensiveScore += hasViableTarget ? 20 : 0;
offensiveScore += resourceSurplus > 3 ? 15 : 0;

defensiveScore += (1.0 - strengthRatio) * 50;  // Disadvantage
defensiveScore += underThreat ? 30 : 0;
defensiveScore += recentlyLostTerritory ? 25 : 0;
defensiveScore += lowResources ? 20 : 0;

progressiveScore += noImmediateThreats ? 25 : 0;
progressiveScore += hasUnupgradedBuildings ? 20 : 0;
progressiveScore += stableBorders ? 15 : 0;

// Culture bias (secondary modifier)
offensiveScore += aggressionBias * 15;
offensiveScore -= cautionBias * 10;

defensiveScore += cautionBias * 15;
defensiveScore -= aggressionBias * 10;

progressiveScore += economicBias * 15;

// Select highest score
if (offensiveScore >= defensiveScore && offensiveScore >= progressiveScore) {
  return Strategy.offensive;
} else if (defensiveScore >= progressiveScore) {
  return Strategy.defensive;
} else {
  return Strategy.progressive;
}
```

### Example Scenarios

**Scenario 1: Ottomans (aggressive culture) surrounded**
- Situation: 0.5x strength ratio, 3 hostile neighbors
- Defensive score: 75 (situation) - 8 (culture) = 67
- Offensive score: -25 (situation) + 12 (culture) = -13
- **Result: Defensive** (culture doesn't override reality)

**Scenario 2: Armenia (cautious culture) with huge army**
- Situation: 3.0x strength ratio, weak isolated target
- Offensive score: 100 (situation) + 5 (culture) = 105
- Defensive score: -100 (situation) + 12 (culture) = -88
- **Result: Offensive** (opportunity too good to pass)

**Scenario 3: Byzantines (balanced culture) stable situation**
- Situation: 1.1x ratio, no threats, buildings to upgrade
- Progressive score: 60 (situation) + 11 (culture) = 71
- Offensive score: 5 (situation) + 8 (culture) = 13
- Defensive score: -5 (situation) + 9 (culture) = 4
- **Result: Progressive** (balanced cultures excel here)

---

## Multi-Turn Planning

### Short-Term Memory (1-3 turns)
- Remember recent battles and outcomes
- Track enemy army movements
- Note which villages were reinforced

### Medium-Term Goals (4-10 turns)
- Target villages to conquer
- Economic development targets
- Military buildup thresholds

### Long-Term Strategy (10+ turns)
- Preferred expansion direction
- Key strategic positions to control
- Rivalry tracking (who attacked us?)

### Goal Examples

**Offensive Goal:**
```
{
  type: "conquest",
  target: "Sofia",
  required_strength: 150,
  current_strength: 80,
  estimated_turns_to_ready: 4,
  priority: "high"
}
```

**Defensive Goal:**
```
{
  type: "fortify",
  target: "Constantinople",
  required_fortress_level: 3,
  current_level: 1,
  required_garrison: 30,
  current_garrison: 18,
  priority: "critical"
}
```

**Economic Goal:**
```
{
  type: "development",
  target: "Thessaloniki",
  target_buildings: ["Market L3", "Farm L2"],
  expected_income_boost: 25,
  turns_to_complete: 6,
  priority: "medium"
}
```

---

## Combat Decision Making

### When to Attack

**Minimum Requirements:**
1. Strength ratio ≥ 1.5:1 for neutral targets
2. Strength ratio ≥ 2.0:1 for defended enemy targets
3. Can sustain 2+ turns of combat (food, reinforcements)
4. No critical threats at home

**Attack Modifiers:**
- Offensive strategy: -0.3 from required ratio
- Target is isolated (no reinforcement path): -0.2
- Target has fortress L2+: +0.5 to required ratio
- We have cavalry advantage: -0.2

### When to Defend

**Garrison Thresholds:**
- Border village: 80% of max garrison
- Interior village: 50% of max garrison
- Under threat: 100% + stationed army

**Reinforcement Priority:**
1. Villages under siege
2. Villages with incoming enemy army
3. Villages below threshold adjacent to enemy
4. Villages below threshold (any)

### When to Retreat

*Currently not implemented - units fight to death*

Future consideration:
- Retreat when <30% strength remaining
- Retreat to nearest friendly village
- Preserves experienced units

---

## Implementation Notes

### Data Structures Needed

```dart
class AIStrategyState {
  StrategyType currentStrategy;
  Map<String, NeighborAssessment> neighbors;
  BudgetAllocation budget;
  List<AIGoal> activeGoals;
  int turnsInCurrentStrategy;
}

class NeighborAssessment {
  String villageId;
  String ownerId;
  int distanceInTurns;
  double threatScore;
  double opportunityScore;
  int estimatedGarrison;
  List<String> knownArmies;
  DateTime lastUpdated;
}

class BudgetAllocation {
  int militaryBudget;
  int economyBudget;
  int reserveBudget;
  int totalIncome;
  int fixedCosts; // upkeep
}

enum StrategyType {
  offensive,
  defensive,
  progressive,
}
```

### Integration Points

1. **TurnEngine.doAITurn()** - Entry point for AI decisions
2. **AIEngine.execute()** - Coordinates the 3-phase approach
3. **AIStrategyManager** - Needs major refactoring for new system
4. **AIEconomyManager** - Budget-aware building decisions
5. **AIMilitaryManager** - Budget-aware recruitment

### Migration Path

**Phase 1:** Add strategy state and neighbor tracking
**Phase 2:** Implement budget system
**Phase 3:** Refactor existing managers to use budgets
**Phase 4:** Add multi-turn goal planning
**Phase 5:** Tune and balance

---

## Open Questions for Discussion

1. **Diplomacy:** Should AI nations form alliances or non-aggression pacts?

2. **Information Asymmetry:** How much should AI "know" vs "see"?
   - Currently: AI sees everything
   - Proposed: AI uses fog of war like player

3. **Learning:** Should AI adapt to player strategy over multiple games?

4. **Difficulty Levels:** Should there be Easy/Medium/Hard AI variants?
   - Easy: More mistakes, weaker budgets, slower response
   - Hard: Optimal play, bonus resources, faster response

5. **Coordination:** Should multiple AI nations gang up on the leader?

6. **Personality Drift:** Should nation personality change based on game events?
   - Defensive nation becomes aggressive after losing territory
   - Aggressive nation becomes defensive after major defeat

---

## Summary

The AI strategy system transforms nations from reactive bots to proactive strategic actors. By:

1. **Assessing situation** each turn
2. **Selecting strategy** based on conditions + personality
3. **Allocating budget** to military/economy/reserve
4. **Tracking neighbors** as threats or opportunities
5. **Planning ahead** with multi-turn goals

The AI creates believable, challenging opponents that adapt to the game state while maintaining distinct national personalities.
