# Crusader's Path - Game Design Document

## Identity

A real-time character-driven RPG-strategy game set on a real Crusader-era map.
You're a nobody with a sword and a dream. Trade between real historical cities,
build a warband, fight your way up, and carve your own kingdom from the chaos
of the medieval Eastern Mediterranean.

Think: Mount & Blade meets Crusader Kings, on your phone, on a real map.

---

## Core Experience

The player taps a city on the map. Their character starts moving there.
Time flows — AI factions march armies, trade caravans travel, wars break out.
Encounters interrupt the journey (bandits, merchants, patrols).
Arrive at a city: time pauses. Trade goods, recruit soldiers, accept contracts.
Tap the next destination. Time flows again.

No "End Turn" button. No turn counter visible. The world moves and you move with it.

---

## The Map

Real Eastern Mediterranean, ~31 cities:
- Capitals: Constantinople (Byzantine), Bursa (Ottoman), Acre (Crusader),
  Cairo (Mamluk), Tarnovo (Bulgarian), Belgrade (Serbian), Ani (Armenian)
- Major cities: Thessaloniki, Nicaea, Konya, Ankara, Jerusalem, Antioch, Damascus
- Trade hubs: Constantinople, Antioch, Aleppo, Bursa
- Islands: Rhodes, Crete, Cyprus (connected by sea routes)
- Neutral/contested: Smyrna, Trebizond, Edirne, Athens, Aleppo, Tripoli, Gaza

Cities connected by K=4 nearest neighbors, max 500km. Travel time = distance/80 ticks.
Sea routes marked differently from land routes (visual + slight speed penalty).

City names change with controlling faction (Constantinople -> Istanbul under Ottomans).

---

## Time System

Under the hood: tick-based simulation (~1 tick per second at 1x speed).
Player controls: Pause, 1x, 2x, 3x speed buttons.

- While traveling: time flows, world simulates, encounters can interrupt
- While in a city: time is PAUSED. Player takes all actions, then departs
- Player can pause anytime to inspect the map, check armies, plan routes
- AI factions, world events, economy all tick simultaneously

---

## Two Resources Systems

### Base Resources (City Economy)
Used for city building, upgrades, army upkeep:
- Food: population sustenance, army feeding
- Wood: building construction
- Iron: military equipment, advanced buildings
- Gold: currency, recruitment, upkeep

Cities produce these based on buildings (Farm, Lumber Mill, Iron Mine, Market).
AI factions manage their own city economies.

### Trade Goods (Player Commerce)
Carried by the player, bought/sold between cities:

| Good       | Base Price | Cheap At             | Expensive At            | Practical Use          |
|------------|-----------|----------------------|-------------------------|------------------------|
| Grain      | 8g        | Fertile cities       | Mountainous cities      | Can feed army (=food)  |
| Timber     | 10g       | Forested cities      | Coastal/island cities   | Can build (=wood)      |
| Iron Ore   | 15g       | Mountainous cities   | Coastal/fertile cities  | Can craft/build (=iron)|
| Silk       | 25g       | Trade Crossroads     | Forested/inland cities  | Pure trade commodity   |
| Spices     | 30g       | Coastal port cities  | Landlocked interior     | Pure trade commodity   |
| Weapons    | 20g       | Strategic+mountain   | Fertile/peaceful cities | Can equip army (+stats)|

Dual utility: sell for profit OR use for construction/army.
Decision: "Sell this iron for 15g or use it to build a barracks?"

### Price Formula

```
price = basePrice * traitModifier * supplyModifier * eventModifier * warModifier

traitModifier: 0.5x if city produces it, 1.5x if city needs it
supplyModifier: based on local supply level (0-200, drifts toward equilibrium)
eventModifier: drought = grain 2x, winter = timber 1.5x, etc.
warModifier: siege/adjacent war = all prices 1.2-1.5x
```

Supply changes when player buys/sells. Recovers 10% toward baseline per tick.
Production cities drift toward 130 (surplus). Non-production drift toward 80 (scarce).

---

## Player Character

Single Player object that gains capabilities over time.

### State
- Position: current city, or traveling (origin, destination, progress)
- Gold: personal currency
- Cargo: Map<TradeGood, int> — what goods they're carrying
- Warband: reference to their Army (always with them)
- Reputation: int per faction (-100 to +100)
- Stage: wanderer / merchant / mercenary / vassal / lord
- Skills: combat, leadership, tactics, trade, scouting (1-10 each)
- Properties: list of owned buildings in various cities
- Contracts: active contracts with deadlines
- Faction allegiance: independent / mercenary for X / vassal of X

### Cargo Capacity
- Base: 20 units
- Pack mule: +15 (costs 40g, takes 1 army slot)
- Trade wagon: +30 (costs 100g, takes 2 army slots)
- Encumbrance: >50% full = slower travel, >80% = much slower

### Army/Cargo Tradeoff
Pack animals take army slots. A full trader (wagons + mules) has fewer soldiers.
A full army has minimal cargo space. Forces the player to choose their identity
or find a balance.

---

## Progression Stages

### Stage 1: Wanderer (start)
- Max warband: 10
- Start: 3 militia, 1 spearman, 150 gold
- Gameplay: buy/sell goods between cities, delivery contracts, fight bandits
- Limits: 5 cargo (no wagon), basic units only, 10% market tax
- Unlock next: earn 500g cumulative + complete 3 contracts + 5 soldiers

### Stage 2: Merchant
- Max warband: 20
- Unlocks: wagon purchase, workshops, trade ledger (price history)
- Market tax drops to 5%
- Gameplay: longer trade routes, escort contracts, first property purchases
- Unlock next: own 2 properties + 2000g cumulative + 5 combat contracts

### Stage 3: Mercenary
- Max warband: 35
- Unlocks: war contracts, advanced unit recruitment (cavalry, archers),
  formation choices in battle, faction military service
- Gameplay: fight in faction wars for pay, raid caravans, build reputation
- Unlock next: win 5 battles + 5000g cumulative + 15+ soldiers + reputation 50+

### Stage 4: Vassal (optional — can stay mercenary)
- Max warband: 50
- Unlocks: govern a fief (one city), 30% tax income, faction reinforcements
- Obligations: answer call to arms within reasonable time
- Can delegate: set city auto-build priority (economy/military/balanced)
- Unlock next: control 3 cities

### Stage 5: Lord
- Max warband: 70
- Unlocks: diplomacy, multiple cities, delegate armies, victory conditions
- Cities auto-govern with priorities the player sets
- Player can still travel and trade, but passive income dominates
- Victory: domination, economic, military, or imperial

### Key rules:
- Stages are permanent once reached (no demotion)
- Each stage ADDS capabilities, never removes previous ones
- Player can ignore progression and stay as a trader forever (no forced combat)
- Victory conditions only matter at Lord stage — earlier stages are the journey

---

## Combat

### Warband
- Player's army travels with them always
- Recruit at cities with appropriate buildings (Barracks, Archery Range, Stables)
- Upkeep: gold + food per tick from personal reserves. Grain trade good can feed army.
- Soldiers have names (culture-based on recruitment city), battle count, kills
- 3 tiers: Recruit (fresh) -> Veteran (3+ battles) -> Elite (7+ battles)
- Companions (max 3): named characters with backstory, don't die permanently
  (captured instead), provide skill bonuses. Distinct from rank-and-file.

### Encounter Types
- Road bandits: 3-8 militia, ~30% per trip. Easy, small loot.
- Deserter bands: 6-12 mixed, ~15% per trip. Medium, can recruit survivors.
- Faction patrols: 8-15 trained, only in hostile territory. Political consequences.
- Tournaments: at major cities every ~10 ticks. Bracket fights, prize gold + reputation.
- Mercenary contracts: fight alongside faction armies. Paid per battle.
- Sieges: defend or attack cities. Highest stakes.

### Pre-Battle (2 taps)
Screen shows: your composition + strength vs enemy (estimated). Terrain auto-assigned.

| Battle Plan  | Under the Hood                            | Best When             |
|-------------|-------------------------------------------|-----------------------|
| Aggressive  | Crescent + Aggressive Push + cavalry flank | Outnumber, have cavalry|
| Defensive   | Shield Wall + Hold Ground + ranged reserve | Outnumbered, infantry |
| Gambit      | Skirmish + Feigned Retreat + mixed roles   | Desperate, coin flip  |

Advanced mode (optional tap): expand to customize formation, engagement, roles.
Unlocks at Tactics skill level 3.

### Battle Resolution
Existing tick-based combat engine runs. Animated battle screen shows result.
Small encounters (bandits): resolve in <1 second.
Large battles (sieges): full animation, player watches.

### Defeat Consequences
- 60% of surviving soldiers stay. 40% scatter (recoverable if you return in 3 ticks).
- 70% chance: escape with losses + 50% gold looted
- 30% chance: captured 1-3 ticks. Pay ransom (scales with reputation).
- If 0 gold for ransom: released after max capture time (3 ticks). Harsh but not softlock.
- Cargo: 50% looted by enemy.
- Reputation: -5 to -15.

### Flee Option
Before battle: flee costs -10 reputation, lose 25% cargo, 1 soldier dies as rearguard.
Always available. Sometimes the smart play.

---

## World Simulation

Runs every tick in the background while the player travels.

### Faction Wars
- 7 factions with AI personalities (aggressive, balanced, defensive)
- War cooldown per faction: aggressive=2 ticks, balanced=3, defensive=5
- Factions grab neutral cities early, then fight each other
- ~1-2 city changes per 10 ticks early, 2-4 late game
- Defensive posture: after losing 2 cities in 5 ticks, AI turtles for 5 ticks
- The map visibly shifts — borders expand, contract, factions grow or shrink

### Faction Reputation (Player)
| Reputation   | Standing    | Effects                                              |
|-------------|-------------|------------------------------------------------------|
| -100 to -50 | Hostile     | Denied city entry. Attacked on sight. Patrols stop you.|
| -49 to -10  | Unfriendly  | 50% price markup. No recruitment.                     |
| -9 to +9    | Neutral     | Normal prices. Basic recruitment.                     |
| +10 to +49  | Friendly    | 15% discount. Faction quests. Advanced units.         |
| +50 to +100 | Allied      | 30% discount. Military access. Shared intel.          |

Reputation changes: trade (+2), complete faction quest (+10-25), defend their city (+15),
conquer their city (-30), kill their army (-15), shared enemy (+1/tick).

### Seasons (4-tick cycle)
- Spring: normal
- Summer: +25% food production, normal movement
- Autumn: trade prices -10% (harvest bounty)
- Winter: +1 travel time, food consumption +50%, happiness -5

### World Events
Existing events continue: drought, harsh winter, bountiful harvest, gold rush,
rebellion, crusade, earthquake, trade caravan, mercenary company, civil war.

New events:
- Mongol scouts (tick 30): tavern rumors warn of eastern threat
- Mongol invasion (tick 40): 3 NPC cavalry armies (15 knights each) from east edge
  Attack nearest cities. All factions gain +10 rep with player (common enemy).
  Mongols are a faction with no economy — pure conquest AI.

### Information / Fog of War
- Player sees cities they've visited (cached info, decays after 5 ticks)
- Tavern rumors: 30% chance per city visit. Partially accurate intel.
- Scouts: Light cavalry in warband extends vision. Scouting skill adds range.
- Unknown cities show "?" with last-known owner.

---

## Economy

### Trading
Buy goods where cheap (trait-based), sell where expensive.
Example: Buy 10 iron ore in Ani (mountainous, 7g each = 70g).
Travel to Acre (coastal, sells for 20g each = 200g). Profit: 130g over 3 ticks.

### Properties (owned in cities you control or are friendly with)
| Property      | Cost  | Effect                              | Stage      |
|--------------|-------|-------------------------------------|------------|
| Workshop     | 500g  | Produces 1 trade good per tick      | Merchant   |
| Market Stall | 150g  | -10% buy, +10% sell at this city    | Merchant   |
| Warehouse    | 300g  | Store 50 units of goods here        | Merchant   |
| Caravanserai | 500g  | 15g/tick passive income             | Mercenary  |

Properties lost if city is conquered by enemy. Invest in stable cities.

### Contracts
Generated at city taverns. 2-3 available per city, refresh every 3 ticks.

| Type          | Example                              | Reward       | Risk   |
|--------------|--------------------------------------|-------------|--------|
| Delivery     | "Bring 10 grain to Damascus"         | 80-150g     | Low    |
| Bulk Order   | "Deliver 25 iron to Constantinople"  | 250-400g    | Medium |
| Escort       | "Protect caravan to Aleppo"          | 100-200g    | Medium |
| Bounty       | "Clear bandits near Damascus road"   | 150-400g    | High   |
| Urgent Supply| "Weapons to besieged Jerusalem"      | 200-300g    | High   |

### Income Progression
| Stage     | Primary Income          | Gold/tick | Key Activity              |
|-----------|------------------------|-----------|---------------------------|
| Wanderer  | Manual trading          | 20-50     | Learn routes, small trades |
| Merchant  | Trading + workshops     | 50-150    | Own properties, run routes |
| Mercenary | War contracts + trade   | 100-300   | Fight for factions         |
| Vassal    | City taxes + trade      | 200-500   | Govern + trade empire      |
| Lord      | Multiple cities + all   | 500+      | Passive empire             |

---

## Mobile UX

### Screen Layout (always)
- Top: HUD bar (gold, cargo count, warband size, speed controls, pause)
- Middle: Map (always visible, 50-70% of screen)
- Bottom: Context panel (30-50%, changes based on state)

### Player Moving (time flowing)
Map shows character moving along road. Nearby cities visible.
Bottom panel (compact): destination, ETA, warband health, speed controls.
Encounters pause time and show modal card.

### Player in City (time paused)
Map zoomed to city + neighbors (40%).
Bottom panel (60%): 3 tabs max.

| Tab       | Content                                              |
|-----------|------------------------------------------------------|
| Trade     | Buy/sell goods, price arrows, cargo, use goods to build|
| Recruit   | Available units, hire soldiers, warband overview       |
| Tavern    | Contracts, rumors, properties, rest                   |

3 tabs, not 5. Property and News folded into Tavern.
Everything reachable in 1-2 taps.

### Trade UI
Single list. Each row: good emoji, name, buy price, sell price, profit arrow.
Green arrows = buy signal. Red arrows = sell signal.
Tap [+] to buy 1, long-press for bulk. Tap [-] to sell 1.
"Use" button on Grain/Timber/Iron Ore to convert to base resource.

Below the list: "Your Cargo: 18/30" with item summary.
Trade Ledger (swipe left): prices at previously visited cities, sorted by profit.

### Pre-Battle
Full-screen overlay. Enemy comp vs yours. Terrain shown.
3 battle plan buttons. Fight / Flee buttons.
2 taps to start a battle.

### Notifications
- Map badges: red (attack), gold (trade opportunity), blue (contract)
- Encounter cards: modal, pause time, require player decision
- World events: banner notification at top, auto-dismiss after 3 seconds
- No turn summary cards. Events happen in real-time and are visible on the map.

### Gestures
| Gesture      | Area    | Action                               |
|-------------|---------|--------------------------------------|
| Tap         | City    | Enter city (pause time) / view info  |
| Tap         | Road    | Set destination (start moving)       |
| Tap         | Pause   | Pause/resume time                    |
| Pan         | Map     | Pan map                              |
| Pinch       | Map     | Zoom                                 |
| Swipe L/R   | Panel   | Switch tabs                          |
| Long-press  | City    | Quick info tooltip                   |
| Long-press  | [+]/[-] | Bulk buy/sell                        |

---

## Technical Architecture

### Player Model (one object)
```
PlayerCharacter:
  - position: GeoCoordinate (on map)
  - state: AtCity(villageId) | Traveling(from, to, progress)
  - gold: int
  - cargo: Map<TradeGood, int>
  - warband: Army (reference, always co-located)
  - reputation: Map<String, int> (per faction)
  - stage: ProgressionStage enum
  - skills: Map<Skill, int>
  - properties: List<Property>
  - activeContracts: List<Contract>
  - allegiance: Allegiance (independent / mercenary / vassal)
  - factionId: String? (if vassal/mercenary)
```

### Game Loop (RTS-style)
```
GameLoop (runs on timer, ~1 tick per second at 1x):
  1. If player is traveling: advance player position
  2. Check for encounters (if player is on road)
  3. If encounter: PAUSE, show encounter card, wait for player decision
  4. AI faction turns (economy, military, strategy)
  5. World events roll
  6. Economy tick (production, supply drift, price recalculation)
  7. Army movement (all AI armies)
  8. Combat resolution (siege, field battles)
  9. Season check
  10. Victory check (only if player is Lord stage)
```

Player actions (trade, recruit, depart) happen OUTSIDE the game loop,
during pause (in city) or when encounters interrupt.

### Save/Load (from day 1)
Every model class gets toJson/fromJson.
Save: serialize entire GameManager state to JSON, write to SharedPreferences or file.
Load: deserialize, reconstruct GameManager state.
Auto-save every 10 ticks.

### What to Reuse
- Map + 31 cities + connection graph
- Combat engine (tick-based, formations, terrain, roles)
- Unit types (7 types, rock-paper-scissors)
- Building system (8 buildings)
- AI engines (economy, military, strategy managers)
- World events (11 event types)
- Fog of war + vision
- Village model (cities still exist, AI manages them)
- Army model (player warband = Army with cargo extension)
- Nationality system (factions, AI personalities)

### What to Build New
- PlayerCharacter model + serialization
- TradeGood enum + price engine
- RTS game loop (timer-based tick instead of player-triggered)
- Travel system (pathfinding on connection graph, position interpolation)
- Encounter system (road events, probability tables)
- Contract system (generation, tracking, deadlines)
- Property system (ownership, income, loss on conquest)
- Reputation system (per-faction tracking)
- Progression stage tracker
- City visit UI (3-tab panel: Trade, Recruit, Tavern)
- Travel UI (compact status panel)
- Trade UI (buy/sell list with profit indicators)
- Trade Ledger (price history for visited cities)
- Speed controls + pause
- Save/Load infrastructure
- Mongol invasion (new faction type, no-economy AI)

### What to Delete/Replace
- inline_village_panel.dart (village management -> city visit panel)
- floating_hud.dart (faction resources -> character stats)
- Victory conditions as-is (redesign for character progression)
- Turn-triggered game loop (replace with timer-based)
- "End Turn" button and turn display
- Nationality selection as game start (replace with character creation)

---

## MVP (Phase 1)

The minimum to make the new game playable:

1. Player character on map with RTS movement (tap to move, time flows)
2. Pause/play/speed controls
3. 3 trade goods (Grain, Iron Ore, Silk) with static trait-based prices
4. City panel with 2 tabs (Trade + Recruit)
5. Personal warband (recruit at cities, upkeep from personal gold)
6. Road encounters (bandit fights only)
7. 3 battle plans mapping to existing combat engine
8. Save/load (basic JSON serialization)
9. AI factions still run (economy + military + wars in background)

NOT in MVP: properties, contracts, reputation, vassal/lord stages,
named soldiers, seasons, Mongol invasion, trade ledger, supply/demand.

## Phase 2: Economic Depth
- Full 6 trade goods with supply/demand
- Properties (workshops, stalls, warehouses)
- Contracts (delivery, escort, bounty)
- Trade Ledger UI
- Merchant stage unlock

## Phase 3: Political Layer
- Faction reputation system
- Mercenary service + war contracts
- Seasons
- Tavern rumors / intelligence
- Mercenary stage unlock

## Phase 4: Power & Endgame
- Vassal + Lord stages
- City governance (auto-govern with priorities)
- Victory conditions redesigned
- Mongol invasion
- Named soldiers + companions
- Diplomacy
