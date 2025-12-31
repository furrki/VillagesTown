# VillagesTown → Flutter Migration Plan

## 1. Project Structure

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   │   ├── game_constants.dart          # villageStartCash, villageStartPopulation
│   │   └── layout_constants.dart        # Device detection, responsive sizing
│   ├── extensions/
│   │   └── iterable_extensions.dart
│   └── utils/
│       ├── haptic_utils.dart            # HapticFeedback wrapper (iOS only)
│       └── math_utils.dart              # Distance calculations
│
├── data/
│   ├── models/
│   │   ├── entity.dart                  # Abstract class: isMovable, coordinates, mapColor
│   │   ├── resource.dart                # Enum: food, wood, iron, gold + emoji/color
│   │   ├── terrain.dart                 # Enum: plains, forest, mountains, etc.
│   │   ├── nationality.dart             # Turkish/Greek/Bulgarian + flag emoji
│   │   ├── tile.dart                    # coordinates, terrain, strategicResource, explored, owner
│   │   ├── village.dart                 # Full Village model with computed props
│   │   ├── village_level.dart           # Enum: village → town → district → castle → city
│   │   ├── building.dart                # Building model + static definitions
│   │   ├── building_type.dart           # Enum: production, military, infrastructure, special
│   │   ├── unit.dart                    # Unit model with stats
│   │   ├── unit_type.dart               # Enum: 7 unit types + counter system
│   │   ├── army.dart                    # Army container with travel state
│   │   ├── player.dart                  # Player model with AI personality
│   │   ├── ai_personality.dart          # Enum: aggressive, economic, balanced
│   │   └── turn_event.dart              # Event enum for turn summary
│   │
│   ├── protocols/                       # Dart mixins (equivalent to Swift protocols)
│   │   ├── resource_holder.dart         # add, subtract, isSufficient, get
│   │   └── treasury_holder.dart         # add, subtract for money
│   │
│   └── map/
│       ├── game_map.dart                # Abstract Map interface
│       └── virtual_map.dart             # Implementation with tile grid
│
├── engines/
│   ├── game_manager.dart                # Singleton with ChangeNotifier
│   ├── turn_engine.dart                 # 11-phase turn processor
│   ├── combat_engine.dart               # Combat resolution
│   ├── ai_engine.dart                   # AI decision making
│   ├── building_production_engine.dart  # Resource production
│   ├── building_construction_engine.dart # Building/upgrade logic
│   ├── recruitment_engine.dart          # Unit recruitment
│   ├── movement_engine.dart             # Unit/army movement
│   ├── population_engine.dart           # Population & happiness
│   └── unit_upkeep_engine.dart          # Unit maintenance costs
│
├── ui/
│   ├── screens/
│   │   ├── nationality_selection_screen.dart
│   │   ├── game_screen.dart             # Adaptive: mobile vs desktop
│   │   ├── game_view_desktop.dart
│   │   ├── game_view_mobile.dart
│   │   └── victory_screen.dart
│   │
│   ├── map/
│   │   ├── map_view.dart                # Main map rendering
│   │   ├── map_painter.dart             # CustomPainter for tiles/connections
│   │   ├── village_marker.dart          # Village node widget
│   │   ├── draggable_village_marker.dart
│   │   ├── marching_army_marker.dart
│   │   └── map_gesture_handler.dart     # Pan, zoom, drag handling
│   │
│   ├── panels/
│   │   ├── inline_village_panel.dart    # Bottom action panel for mobile
│   │   ├── village_action_panel.dart
│   │   ├── army_action_panel.dart
│   │   ├── empty_selection_panel.dart
│   │   └── side_info_panel.dart         # Desktop side panel
│   │
│   ├── menus/
│   │   ├── build_menu.dart
│   │   ├── recruit_menu.dart
│   │   └── send_army_sheet.dart
│   │
│   ├── components/
│   │   ├── floating_hud.dart            # Turn + resources + victory progress
│   │   ├── owner_flag_view.dart
│   │   ├── resource_row.dart
│   │   ├── stat_cell.dart
│   │   ├── inline_build_button.dart
│   │   ├── inline_upgrade_button.dart
│   │   ├── inline_recruit_button.dart
│   │   ├── action_button.dart
│   │   ├── end_turn_button.dart
│   │   └── toast_overlay.dart
│   │
│   └── theme/
│       └── app_theme.dart               # Dark theme colors
│
└── providers/
    └── game_provider.dart               # ChangeNotifierProvider wrapper
```

---

## 2. Data Models

### 2.1 Resource (lib/data/models/resource.dart)
```dart
enum Resource {
  food('Food', '🌾', Colors.green),
  wood('Wood', '🪵', Colors.brown),
  iron('Iron', '⚔️', Colors.grey),
  gold('Gold', '💰', Colors.amber);

  final String name;
  final String emoji;
  final Color color;
  const Resource(this.name, this.emoji, this.color);
}
```

### 2.2 Nationality (lib/data/models/nationality.dart)
```dart
class Nationality {
  final String id;
  final String name;
  final String flag;

  static final turkish = Nationality(id: 'tr', name: 'Turkish', flag: '🇹🇷');
  static final greek = Nationality(id: 'gr', name: 'Greek', flag: '🇬🇷');
  static final bulgarian = Nationality(id: 'bg', name: 'Bulgarian', flag: '🇧🇬');

  static List<Nationality> getAll() => [turkish, greek, bulgarian];
}
```

### 2.3 VillageLevel (lib/data/models/village_level.dart)
```dart
enum VillageLevel {
  village(maxBuildings: 8, productionBonus: 0.1, defenseBonus: 0.0, populationCap: 200),
  town(maxBuildings: 12, productionBonus: 0.2, defenseBonus: 0.0, populationCap: 500),
  district(maxBuildings: 16, productionBonus: 0.3, defenseBonus: 0.0, populationCap: 1000),
  castle(maxBuildings: 20, productionBonus: 0.4, defenseBonus: 0.25, populationCap: 2000),
  city(maxBuildings: 30, productionBonus: 0.5, defenseBonus: 0.5, populationCap: 5000);

  final int maxBuildings;
  final double productionBonus;
  final double defenseBonus;
  final int populationCap;
  const VillageLevel({...});
}
```

### 2.4 UnitType (lib/data/models/unit_type.dart)
```dart
enum UnitType {
  // Infantry
  militia,
  spearman,
  swordsman,
  // Ranged
  archer,
  crossbowman,
  // Cavalry
  lightCavalry,
  knight;

  String get category => switch (this) {
    militia || spearman || swordsman => 'Infantry',
    archer || crossbowman => 'Ranged',
    lightCavalry || knight => 'Cavalry',
  };

  String get emoji => switch (this) {
    militia => '🗡️',
    spearman => '🛡️',
    swordsman => '⚔️',
    archer => '🏹',
    crossbowman => '🎯',
    lightCavalry => '🐴',
    knight => '🐎',
  };

  /// Counter system damage multiplier
  double damageMultiplier(UnitType target) {
    return switch (this) {
      spearman when target.category == 'Cavalry' => 1.5,
      lightCavalry || knight when target.category == 'Ranged' => 1.5,
      lightCavalry || knight when target == spearman => 0.6,
      archer || crossbowman when target == militia => 1.3,
      archer || crossbowman when target == swordsman => 1.2,
      swordsman when target == militia => 1.2,
      _ => 1.0,
    };
  }

  UnitStats get stats => UnitStats.forType(this);
}

class UnitStats {
  final String name;
  final int attack, defense, hp, movement;
  final Map<Resource, int> cost;
  final Map<Resource, int> upkeep;

  static UnitStats forType(UnitType type) => switch (type) {
    UnitType.militia => UnitStats(
      name: 'Militia', attack: 5, defense: 3, hp: 50, movement: 2,
      cost: {Resource.gold: 20, Resource.food: 5},
      upkeep: {Resource.gold: 2, Resource.food: 1},
    ),
    UnitType.spearman => UnitStats(
      name: 'Spearman', attack: 7, defense: 8, hp: 70, movement: 2,
      cost: {Resource.gold: 30, Resource.iron: 5},
      upkeep: {Resource.gold: 2, Resource.food: 1},
    ),
    UnitType.swordsman => UnitStats(
      name: 'Swordsman', attack: 10, defense: 6, hp: 80, movement: 2,
      cost: {Resource.gold: 35, Resource.iron: 10},
      upkeep: {Resource.gold: 2, Resource.food: 1},
    ),
    UnitType.archer => UnitStats(
      name: 'Archer', attack: 9, defense: 3, hp: 50, movement: 2,
      cost: {Resource.gold: 35, Resource.wood: 10},
      upkeep: {Resource.gold: 2, Resource.food: 1},
    ),
    UnitType.crossbowman => UnitStats(
      name: 'Crossbowman', attack: 12, defense: 4, hp: 60, movement: 2,
      cost: {Resource.gold: 50, Resource.iron: 10},
      upkeep: {Resource.gold: 3, Resource.food: 1},
    ),
    UnitType.lightCavalry => UnitStats(
      name: 'Light Cavalry', attack: 9, defense: 5, hp: 70, movement: 4,
      cost: {Resource.gold: 60, Resource.food: 15},
      upkeep: {Resource.gold: 4, Resource.food: 2},
    ),
    UnitType.knight => UnitStats(
      name: 'Knight', attack: 14, defense: 8, hp: 100, movement: 3,
      cost: {Resource.gold: 100, Resource.iron: 20},
      upkeep: {Resource.gold: 6, Resource.food: 2},
    ),
  };
}
```

### 2.5 Village (lib/data/models/village.dart)
```dart
class Village with ResourceHolder, TreasuryHolder {
  final String id;
  final String name;
  final Nationality nationality;
  Offset coordinates;
  String owner;
  VillageLevel level;
  List<Building> buildings;
  Map<Resource, int> resources;
  double money;
  int population;
  int happiness; // 0-100
  int garrisonStrength;
  int garrisonMaxStrength;
  bool underSiege;
  int recruitsThisTurn;

  // Computed properties
  int get maxBuildings => level.maxBuildings;
  double get productionBonus => level.productionBonus;

  double get defenseBonus {
    var bonus = 0.2;
    for (final b in buildings) bonus += b.defenseBonus;
    bonus += level.defenseBonus;
    return bonus;
  }

  int get populationCapacity {
    var cap = level.populationCap;
    if (buildings.any((b) => b.name == 'Aqueduct')) {
      cap = (cap * 1.5).toInt();
    }
    return cap;
  }

  int get maxRecruitsPerTurn {
    var cap = 3;
    final barracks = buildings.firstWhereOrNull((b) => b.name == 'Barracks');
    if (barracks != null) cap += barracks.level;
    if (buildings.any((b) => b.name == 'Archery Range')) cap += 1;
    return cap;
  }

  int get computedGarrisonMax {
    var max = 10;
    final barracks = buildings.firstWhereOrNull((b) => b.name == 'Barracks');
    if (barracks != null) max += 5 * barracks.level;
    final fortress = buildings.firstWhereOrNull((b) => b.name == 'Fortress');
    if (fortress != null) max += 15 * fortress.level;
    max += switch (level) {
      VillageLevel.town => 5,
      VillageLevel.district => 10,
      VillageLevel.castle => 20,
      VillageLevel.city => 30,
      _ => 0,
    };
    return max;
  }

  void regenerateGarrison() {
    if (underSiege) {
      underSiege = false;
      return;
    }
    var recovery = 1;
    if (buildings.any((b) => b.name == 'Barracks')) recovery += 1;
    if (buildings.any((b) => b.name == 'Fortress')) recovery += 2;
    garrisonMaxStrength = computedGarrisonMax;
    garrisonStrength = min(garrisonStrength + recovery, garrisonMaxStrength);
  }
}
```

### 2.6 Building (lib/data/models/building.dart)
```dart
enum BuildingType { production, military, infrastructure, special }

class Building {
  final String id;
  final BuildingType type;
  final String name;
  final Map<Resource, int> baseCost;
  int level;
  final Map<Resource, int> resourcesProduction;
  final Map<Resource, int> resourcesConsumption;
  final String description;
  final double productionBonus;
  final double defenseBonus;
  final int happinessBonus;
  final bool canRecruitUnits;

  // Static definitions
  static Building get farm => Building(
    type: BuildingType.production,
    name: 'Farm',
    baseCost: {Resource.gold: 50, Resource.wood: 20},
    resourcesProduction: {Resource.food: 10},
    description: 'Produces food for your population',
  );

  static Building get lumberMill => Building(
    type: BuildingType.production,
    name: 'Lumber Mill',
    baseCost: {Resource.gold: 40},
    resourcesProduction: {Resource.wood: 8},
    description: 'Produces wood for construction',
  );

  static Building get ironMine => Building(
    type: BuildingType.production,
    name: 'Iron Mine',
    baseCost: {Resource.gold: 60, Resource.wood: 10},
    resourcesProduction: {Resource.iron: 5},
    description: 'Produces iron for military units',
  );

  static Building get market => Building(
    type: BuildingType.production,
    name: 'Market',
    baseCost: {Resource.gold: 100, Resource.wood: 30},
    resourcesProduction: {Resource.gold: 15},
    description: 'Generates gold through trade',
  );

  static Building get barracks => Building(
    type: BuildingType.military,
    name: 'Barracks',
    baseCost: {Resource.gold: 150, Resource.wood: 50, Resource.iron: 20},
    description: 'Enables recruitment of infantry units',
    canRecruitUnits: true,
  );

  static Building get archeryRange => Building(
    type: BuildingType.military,
    name: 'Archery Range',
    baseCost: {Resource.gold: 140, Resource.wood: 60, Resource.iron: 15},
    description: 'Enables recruitment of ranged units',
    canRecruitUnits: true,
  );

  static Building get stables => Building(
    type: BuildingType.military,
    name: 'Stables',
    baseCost: {Resource.gold: 200, Resource.wood: 80, Resource.food: 30},
    description: 'Enables recruitment of cavalry units',
    canRecruitUnits: true,
  );

  static Building get fortress => Building(
    type: BuildingType.military,
    name: 'Fortress',
    baseCost: {Resource.gold: 300, Resource.wood: 100, Resource.iron: 50},
    description: 'Provides strong defensive bonus',
    defenseBonus: 0.5,
  );

  static Building get granary => Building(
    type: BuildingType.infrastructure,
    name: 'Granary',
    baseCost: {Resource.gold: 80, Resource.wood: 40},
    resourcesProduction: {Resource.food: 5},
    description: 'Increases food storage and production',
    productionBonus: 0.1,
  );

  static Building get temple => Building(
    type: BuildingType.special,
    name: 'Temple',
    baseCost: {Resource.gold: 200, Resource.wood: 60},
    description: 'Increases happiness and culture',
    happinessBonus: 15,
  );

  static Building get library => Building(
    type: BuildingType.special,
    name: 'Library',
    baseCost: {Resource.gold: 150, Resource.wood: 50},
    description: 'Generates science points for research',
  );

  static List<Building> get allEconomic => [farm, lumberMill, ironMine, market];
  static List<Building> get allMilitary => [barracks, archeryRange, stables, fortress];
  static List<Building> get allInfrastructure => [granary];
  static List<Building> get allSpecial => [temple, library];
  static List<Building> get all => [...allEconomic, ...allMilitary, ...allInfrastructure, ...allSpecial];
  static List<Building> starter() => [farm, lumberMill, ironMine];
}
```

### 2.7 Unit (lib/data/models/unit.dart)
```dart
class Unit {
  final String id;
  final String name;
  final UnitType unitType;
  int attack, defense, maxHP, currentHP, movement, movementRemaining;
  int level;
  int experience;
  int morale; // 0-100
  String owner;
  Offset coordinates;

  bool get isAlive => currentHP > 0;
  bool get isMovable => true;

  factory Unit.create(UnitType type, String owner, Offset coordinates) {
    final stats = type.stats;
    return Unit(
      id: uuid.v4(),
      name: stats.name,
      unitType: type,
      attack: stats.attack,
      defense: stats.defense,
      maxHP: stats.hp,
      currentHP: stats.hp,
      movement: stats.movement,
      movementRemaining: stats.movement,
      owner: owner,
      coordinates: coordinates,
    );
  }

  void takeDamage(int amount) => currentHP = max(0, currentHP - amount);
  void heal(int amount) => currentHP = min(maxHP, currentHP + amount);

  void gainExperience(int amount) {
    experience += amount;
    if (experience >= level * 100) levelUp();
  }

  void levelUp() {
    level++;
    attack = (attack * 1.1).toInt();
    defense = (defense * 1.1).toInt();
    maxHP = (maxHP * 1.1).toInt();
    currentHP = maxHP;
  }
}
```

### 2.8 Army (lib/data/models/army.dart)
```dart
class Army {
  final String id;
  String name;
  List<Unit> units;
  String owner;
  String? stationedAt;  // Village ID
  String? destination;
  int turnsUntilArrival;
  String? origin;

  bool get isMarching => destination != null && turnsUntilArrival > 0;
  int get totalAttack => units.fold(0, (sum, u) => sum + u.attack);
  int get totalDefense => units.fold(0, (sum, u) => sum + u.defense);
  int get totalHP => units.fold(0, (sum, u) => sum + u.currentHP);
  int get strength => totalAttack + totalDefense + (totalHP ~/ 10);
  int get unitCount => units.length;

  UnitType? get primaryUnitType {
    if (units.isEmpty) return null;
    final counts = <UnitType, int>{};
    for (final u in units) counts[u.unitType] = (counts[u.unitType] ?? 0) + 1;
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String get emoji => primaryUnitType?.emoji ?? '⚔️';

  void marchTo(String villageId, int turns, String? fromId) {
    origin = fromId ?? stationedAt;
    stationedAt = null;
    destination = villageId;
    turnsUntilArrival = turns;
  }

  void advanceMarch() {
    if (turnsUntilArrival > 0) turnsUntilArrival--;
    if (turnsUntilArrival == 0 && destination != null) {
      stationedAt = destination;
      destination = null;
      origin = null;
    }
  }

  static int calculateTravelTime(Offset from, Offset to) {
    final dx = (to.dx - from.dx).abs();
    final dy = (to.dy - from.dy).abs();
    final distance = sqrt(dx * dx + dy * dy);
    return max(1, (distance / 8.0).ceil());
  }

  static String generateName(List<Unit> units, String owner) {
    final prefix = owner == 'player' ? '' : 'Enemy ';
    return switch (units.length) {
      <= 3 => '${prefix}Squad',
      <= 10 => '${prefix}Warband',
      <= 25 => '${prefix}Company',
      _ => '${prefix}Legion',
    };
  }
}
```

### 2.9 Player (lib/data/models/player.dart)
```dart
enum AIPersonality {
  aggressive(description: 'Aggressive'),
  economic(description: 'Economic'),
  balanced(description: 'Balanced');

  final String description;
  const AIPersonality({required this.description});
}

class Player {
  final String id;
  final String name;
  Nationality nationality;
  bool isHuman;
  List<String> villages;
  bool isEliminated;
  AIPersonality? aiPersonality;

  static List<Player> createPlayers() => [
    Player(id: 'player', name: 'Player', isHuman: true),
    Player(id: 'ai1', name: 'AI Player 1', isHuman: false, aiPersonality: AIPersonality.aggressive),
    Player(id: 'ai2', name: 'AI Player 2', isHuman: false, aiPersonality: AIPersonality.balanced),
  ];
}
```

### 2.10 TurnEvent (lib/data/models/turn_event.dart)
```dart
sealed class TurnEvent {
  String get emoji;
  String get message;
  bool get isImportant;
}

class ResourceGainEvent extends TurnEvent {
  final Resource resource;
  final int amount;
  @override String get emoji => '📦';
  @override String get message => '+$amount ${resource.emoji} ${resource.name}';
  @override bool get isImportant => false;
}

class ArmySentEvent extends TurnEvent {
  final String armyName;
  final String destination;
  final int turns;
  @override String get emoji => '🚶';
  @override String get message => '$armyName marching to $destination ($turns turns)';
  @override bool get isImportant => false;
}

class ArmyArrivedEvent extends TurnEvent {
  final String armyName;
  final String destination;
  @override String get emoji => '🏁';
  @override String get message => '$armyName arrived at $destination';
  @override bool get isImportant => false;
}

class BattleWonEvent extends TurnEvent {
  final String location;
  final int casualties;
  @override String get emoji => '⚔️';
  @override String get message => 'Victory at $location! Lost $casualties units';
  @override bool get isImportant => false;
}

class BattleLostEvent extends TurnEvent {
  final String location;
  final int casualties;
  @override String get emoji => '💀';
  @override String get message => 'Defeat at $location. Lost $casualties units';
  @override bool get isImportant => false;
}

class VillageConqueredEvent extends TurnEvent {
  final String villageName;
  @override String get emoji => '🎉';
  @override String get message => '$villageName conquered!';
  @override bool get isImportant => true;
}

class VillageLostEvent extends TurnEvent {
  final String villageName;
  @override String get emoji => '😢';
  @override String get message => '$villageName was lost!';
  @override bool get isImportant => true;
}

class EnemyApproachingEvent extends TurnEvent {
  final String enemyName;
  final String target;
  final int turns;
  @override String get emoji => '⚠️';
  @override String get message => '⚠️ $enemyName approaching $target! $turns turns away';
  @override bool get isImportant => true;
}

class GeneralEvent extends TurnEvent {
  final String text;
  @override String get emoji => 'ℹ️';
  @override String get message => text;
  @override bool get isImportant => true;
}
```

---

## 3. Protocols/Mixins

### 3.1 ResourceHolder (lib/data/protocols/resource_holder.dart)
```dart
mixin ResourceHolder {
  Map<Resource, int> get resources;
  set resources(Map<Resource, int> value);

  void addResource(Resource resource, int amount) {
    resources = Map.from(resources)..[resource] = (resources[resource] ?? 0) + amount;
  }

  void subtractResource(Resource resource, int amount) {
    resources = Map.from(resources)..[resource] = max(0, (resources[resource] ?? 0) - amount);
  }

  bool isSufficient(Resource resource, int amount) => (resources[resource] ?? 0) >= amount;

  int getResource(Resource resource) => resources[resource] ?? 0;
}
```

### 3.2 TreasuryHolder (lib/data/protocols/treasury_holder.dart)
```dart
mixin TreasuryHolder {
  double get money;
  set money(double value);

  void addMoney(double amount) => money += amount;
  void subtractMoney(double amount) => money = max(0, money - amount);
  bool isSufficientMoney(double amount) => money >= amount;
}
```

---

## 4. Game Engines

### 4.1 GameManager (lib/engines/game_manager.dart)
```dart
class GameManager extends ChangeNotifier {
  static final GameManager _instance = GameManager._internal();
  static GameManager get shared => _instance;
  factory GameManager() => _instance;
  GameManager._internal();

  // State
  late GameMap map;
  List<Player> players = Player.createPlayers();
  int currentTurn = 0;
  String currentPlayer = 'player';
  bool gameStarted = false;
  Nationality? playerNationality;
  Nationality? ai1Nationality;
  Nationality? ai2Nationality;

  final TurnEngine turnEngine = TurnEngine();

  Map<String, Map<Resource, int>> globalResources = {};
  List<Army> armies = [];
  List<TurnEvent> turnEvents = [];
  Set<String> discoveredVillageIDs = {};
  double visionRange = 8.0;

  bool tutorialEnabled = true;
  int tutorialStep = 0;

  void setupGame(Nationality nationality) { /* ... */ }
  void initializeGame() { /* ... */ }
  void resetGame() { /* ... */ }
  void syncGlobalResources() { /* ... */ }
  Map<Resource, int> getGlobalResources(String playerId) { /* ... */ }
  void modifyGlobalResource(String playerId, Resource resource, int amount) { /* ... */ }
  bool canAfford(String playerId, Map<Resource, int> cost) { /* ... */ }
  bool spendResources(String playerId, Map<Resource, int> cost) { /* ... */ }
  List<Village> getPlayerVillages(String playerId) { /* ... */ }
  Village? getVillage(String name) { /* ... */ }
  void updateVillage(Village village) { /* ... */ }

  // Army management
  List<Army> getArmiesAt(String villageId) { /* ... */ }
  List<Army> getArmiesFor(String playerId) { /* ... */ }
  List<Army> getMarchingArmiesFor(String playerId) { /* ... */ }
  List<Army> getStationedArmiesFor(String playerId) { /* ... */ }
  Army createArmy(List<Unit> units, String villageId, String owner) { /* ... */ }
  void updateArmy(Army army) { /* ... */ }
  void removeArmy(String armyId) { /* ... */ }
  void mergeArmiesAt(String villageId, String owner) { /* ... */ }
  bool sendArmy(String armyId, String destinationVillageId) { /* ... */ }

  // Fog of war
  bool isVillageVisible(Village village, String playerId) { /* ... */ }
  bool isArmyVisible(Army army, String playerId) { /* ... */ }
  List<Village> getVisibleVillages(String playerId) { /* ... */ }
  List<Army> getVisibleArmies(String playerId) { /* ... */ }

  void addTurnEvent(TurnEvent event) { /* ... */ }
  void clearTurnEvents() { /* ... */ }
}
```

### 4.2 TurnEngine (lib/engines/turn_engine.dart)
```dart
class TurnEngine {
  final PopulationEngine _populationEngine = PopulationEngine();
  final UnitUpkeepEngine _unitUpkeepEngine = UnitUpkeepEngine();
  final MovementEngine _movementEngine = MovementEngine();
  final AIEngine _aiEngine = AIEngine();

  void doTurn() {
    final game = GameManager.shared;
    game.currentTurn++;
    game.clearTurnEvents();

    // 0. Reset mobilization counters
    for (var i = 0; i < game.map.villages.length; i++) {
      game.map.villages[i].recruitsThisTurn = 0;
    }

    // 1. Building Production
    _doBuildingProduction();

    // 2. Tax Collection
    _collectTaxes();

    // 3. Army Upkeep
    _processArmyUpkeep();

    // 4. Population & Happiness
    _processPopulation();
    _processHappiness();

    // 6. Garrison Regeneration
    _processGarrisonRegeneration();

    // 7. Mid-route Army Interception
    _processArmyInterception();

    // 8. Army Movement & Combat
    _processArmyMovement();

    // 9. AI Turns
    _processAITurns();

    // 10. Intelligence
    _detectIncomingEnemies();

    // 11. Victory Check
    _checkVictory();

    game.notifyListeners();
  }
}
```

### 4.3 CombatEngine (lib/engines/combat_engine.dart)
```dart
class CombatResult {
  final bool attackerWon;
  final int attackerCasualties;
  final int defenderCasualties;
  final int damage;
  final int experienceGained;
}

class CombatEngine {
  bool canAttack(Army attacker, Village target) { /* ... */ }

  CombatResult resolveCombat({
    required List<Unit> attackers,
    required List<Unit> defenders,
    required Offset location,
    required GameMap map,
    Village? defendingVillage,
  }) {
    // Calculate army strengths with counter bonuses
    // Add garrison strength (population/10 × level × building bonuses)
    // Resolve damage and casualties
    // Apply experience gains
    return CombatResult(/* ... */);
  }
}
```

### 4.4 AIEngine (lib/engines/ai_engine.dart)
```dart
class AIEngine {
  final BuildingConstructionEngine _buildingEngine = BuildingConstructionEngine();
  final RecruitmentEngine _recruitmentEngine = RecruitmentEngine();

  void executeAITurn(Player player, GameMap map) {
    if (player.isHuman) return;

    var villages = map.villages.where((v) => v.owner == player.id).toList();
    if (villages.isEmpty) return;

    // 1. Economic Phase - Build buildings
    for (var village in villages) {
      _makeEconomicDecisions(player, village);
    }

    // 2. Military Phase - Recruit units
    for (var village in villages) {
      _makeMilitaryDecisions(player, village, map);
    }

    // 3. Combat Phase - Move and attack
    _executeCombatStrategy(player, map);
  }
}
```

### 4.5 Other Engines
- **BuildingProductionEngine**: `consumeAndProduceAll(Village village)`
- **BuildingConstructionEngine**: `canBuild()`, `buildBuilding()`, `canUpgradeBuilding()`, `upgradeBuilding()`, `getUpgradeCost()`
- **RecruitmentEngine**: `canRecruit()`, `recruitUnits()`, `getRequiredBuilding()`, `getAvailableUnits()`
- **PopulationEngine**: `processPopulationGrowth()`, `collectTaxes()`, `processHappiness()`
- **UnitUpkeepEngine**: `processUpkeep()`
- **MovementEngine**: `canMoveTo()`, `moveUnit()`

---

## 5. State Management

Use **Provider** with `ChangeNotifier`:

```dart
// lib/providers/game_provider.dart
class GameProvider extends ChangeNotifier {
  final GameManager _gameManager = GameManager.shared;

  GameManager get gameManager => _gameManager;

  void forwardNotifications() {
    _gameManager.addListener(notifyListeners);
  }
}

// main.dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameProvider()..forwardNotifications(),
      child: const VillagesTownApp(),
    ),
  );
}
```

---

## 6. UI Implementation

### 6.1 App Entry (lib/main.dart)
```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameProvider()..forwardNotifications(),
      child: const VillagesTownApp(),
    ),
  );
}

class VillagesTownApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Villages Town',
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const ContentView(),
    );
  }
}
```

### 6.2 ContentView (lib/ui/screens/content_view.dart)
```dart
class ContentView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        if (!provider.gameManager.gameStarted) {
          return NationalitySelectionScreen(
            onSelect: (nationality) {
              provider.gameManager.setupGame(nationality);
              provider.gameManager.initializeGame();
            },
          );
        }
        return const AdaptiveGameView();
      },
    );
  }
}
```

### 6.3 NationalitySelectionScreen
- Gradient background with pattern overlay
- 3 nation cards: Turkish, Greek, Bulgarian
- Each card shows: flag emoji, capital name, selection button
- Responsive: vertical stack on mobile, horizontal on desktop
- Animations: scale, offset, opacity on selection

### 6.4 AdaptiveGameView
```dart
class AdaptiveGameView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 600;
    return isCompact ? const MobileGameLayout() : const DesktopGameView();
  }
}
```

### 6.5 MobileGameLayout

**Structure:**
```
Column
├── MapSection (50% height)
│   ├── CompactHUD (floating top)
│   ├── MapView (with gestures)
│   └── DraggedArmyOverlay (during drag)
└── ActionPanel (50% height)
    ├── InlineVillagePanel (if village selected)
    ├── ArmyActionPanel (if army selected)
    └── EmptySelectionPanel (if nothing selected)
```

**Key features:**
- Pinch-to-zoom and pan gestures on map
- Long-press + drag on village with player army to send army
- Drag line visualization during army drag
- Valid destination highlighting (glow effect)
- Toast notifications for actions

### 6.6 DesktopGameView
```dart
Row
├── MapView (flex: 3)
└── SideInfoPanel (width: 320)
    ├── ResourcesDisplay
    ├── VillageDetails (if selected)
    ├── ArmyDetails (if selected)
    └── EndTurnButton
```

**Keyboard shortcuts (desktop only):**
- Space/Enter → End turn
- Escape → Deselect
- 1-4 → Select player villages

---

## 7. Responsive Design

### 7.1 LayoutConstants (lib/core/constants/layout_constants.dart)
```dart
class LayoutConstants {
  static bool isPhone(BuildContext context) =>
    MediaQuery.of(context).size.width < 600;

  static bool isPad(BuildContext context) =>
    MediaQuery.of(context).size.width >= 600 &&
    MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= 1024;

  static double villageNodeSize(BuildContext context) =>
    isPhone(context) ? 44 : 60;

  static double panelWidth(BuildContext context) =>
    isPhone(context) ? double.infinity : 320;

  static EdgeInsets padding(BuildContext context) =>
    EdgeInsets.all(isPhone(context) ? 12 : 20);

  static void impactFeedback({HapticStyle style = HapticStyle.light}) {
    if (Platform.isIOS) {
      switch (style) {
        case HapticStyle.light: HapticFeedback.lightImpact();
        case HapticStyle.medium: HapticFeedback.mediumImpact();
        case HapticStyle.heavy: HapticFeedback.heavyImpact();
      }
    }
  }

  static void selectionFeedback() {
    if (Platform.isIOS) HapticFeedback.selectionClick();
  }
}
```

---

## 8. Platform Considerations

### 8.1 iOS/Android (Mobile)
- Use `GestureDetector` with long-press for army drag
- Haptic feedback via `HapticFeedback` class
- Bottom sheets for modals (`showModalBottomSheet`)
- Touch targets minimum 44pt
- Safe area handling via `SafeArea` widget

### 8.2 Desktop (macOS/Windows/Linux)
- Keyboard shortcuts via `RawKeyboardListener` or `Shortcuts` widget
- Mouse hover effects (`MouseRegion`)
- Right-click context menus
- Resizable windows
- Side panel layout instead of bottom sheets

### 8.3 Web
- Same as desktop layout
- Disable haptic feedback
- Handle browser back button

---

## 9. Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  uuid: ^4.0.0
  collection: ^1.17.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

---

## 10. Migration Checklist

### Phase 1: Core Data Layer
- [ ] Resource enum
- [ ] Nationality model
- [ ] VillageLevel enum
- [ ] UnitType enum + UnitStats
- [ ] Terrain enum
- [ ] Tile model
- [ ] Building model + static definitions
- [ ] Unit model
- [ ] Army model
- [ ] Village model + ResourceHolder + TreasuryHolder mixins
- [ ] Player model + AIPersonality
- [ ] TurnEvent sealed class
- [ ] GameMap abstract + VirtualMap

### Phase 2: Game Engines
- [ ] GameManager singleton with ChangeNotifier
- [ ] BuildingProductionEngine
- [ ] PopulationEngine
- [ ] UnitUpkeepEngine
- [ ] BuildingConstructionEngine
- [ ] RecruitmentEngine
- [ ] MovementEngine
- [ ] CombatEngine
- [ ] AIEngine
- [ ] TurnEngine (orchestrates all phases)

### Phase 3: UI - Screens
- [ ] App entry + Provider setup
- [ ] ContentView (routing)
- [ ] NationalitySelectionScreen
- [ ] AdaptiveGameView
- [ ] MobileGameLayout
- [ ] DesktopGameView
- [ ] VictoryScreen

### Phase 4: UI - Map
- [ ] MapView with InteractiveViewer
- [ ] MapPainter (CustomPainter for connections)
- [ ] VillageMarker
- [ ] DraggableVillageMarker (with long-press drag)
- [ ] MarchingArmyMarker
- [ ] Fog of war visualization

### Phase 5: UI - Panels
- [ ] InlineVillagePanel (mobile)
- [ ] VillageActionPanel (desktop)
- [ ] ArmyActionPanel
- [ ] EmptySelectionPanel
- [ ] SideInfoPanel (desktop)

### Phase 6: UI - Components
- [ ] FloatingHUD
- [ ] OwnerFlagView
- [ ] InlineBuildButton
- [ ] InlineUpgradeButton
- [ ] InlineRecruitButton
- [ ] EndTurnButton
- [ ] ToastOverlay
- [ ] ResourceRow
- [ ] StatCell

### Phase 7: Polish
- [ ] Haptic feedback (iOS)
- [ ] Keyboard shortcuts (desktop)
- [ ] Animations (selection, toast, victory)
- [ ] Sound effects (optional)
- [ ] Dark theme refinement
- [ ] Error handling
- [ ] Loading states

### Phase 8: Testing
- [ ] Unit tests for engines
- [ ] Unit tests for models
- [ ] Widget tests for key components
- [ ] Integration tests for game flow

---

## 11. Key Behavioral Details to Preserve

### 11.1 Turn Phases (exact order)
1. Reset mobilization counters
2. Building production (consume → produce)
3. Tax collection (1 gold/pop + Market bonus)
4. Army upkeep payment
5. Population growth
6. Happiness processing
7. Garrison regeneration (blocked if under siege)
8. Army interception (opposite-direction armies on same route)
9. Army movement + combat at destinations
10. AI turns
11. Intelligence (detect incoming enemies)
12. Victory check

### 11.2 Combat Resolution
- Attacker strength = sum of unit attacks × counter multipliers
- Defender strength = unit defense + garrison × 3 × level bonus × building bonuses
- Garrison minimum = 10 for empty villages
- Conquest requires: attacker wins AND no surviving defender units
- Population loss on conquest: 20%
- Happiness penalty: -20

### 11.3 AI Behavior
- Grace period: Aggressive=5, Economic=10, Balanced=7 turns
- Attack threshold: Aggressive=0.8×, Economic=1.5×, Balanced=1.0× defender strength
- Target selection: Weighted by (strength advantage - distance×5 + neutral bonus)
- Building priority varies by personality
- Recruitment aggressiveness varies by personality

### 11.4 Fog of War
- Vision range: 8 tiles from owned villages and armies
- Once discovered, villages stay visible
- Enemy armies only visible if within range

### 11.5 Travel Time
- Formula: `max(1, ceil(distance / 8))`
- Distance = Euclidean distance between village coordinates

### 11.6 Mobilization Cap
- Base: 3 per turn
- +1 per Barracks level
- +1 if Archery Range exists

---

## 12. Neutral Village Data

```dart
final neutralVillages = [
  // Northern region
  Village(name: 'Thessaloniki', coordinates: Offset(10, 2), owner: 'neutral'),
  Village(name: 'Alexandroupoli', coordinates: Offset(14, 4), owner: 'neutral'),
  // Western region
  Village(name: 'Kavala', coordinates: Offset(2, 10), owner: 'neutral'),
  Village(name: 'Ioannina', coordinates: Offset(5, 7), owner: 'neutral'),
  // Central region
  Village(name: 'Edirne', coordinates: Offset(8, 8), owner: 'neutral'),
  Village(name: 'Bursa', coordinates: Offset(12, 10), owner: 'neutral'),
  Village(name: 'Plovdiv', coordinates: Offset(10, 13), owner: 'neutral'),
  // Eastern region
  Village(name: 'Varna', coordinates: Offset(18, 8), owner: 'neutral'),
  Village(name: 'Constanta', coordinates: Offset(16, 14), owner: 'neutral'),
  // Southern region
  Village(name: 'Izmir', coordinates: Offset(6, 15), owner: 'neutral'),
  Village(name: 'Antalya', coordinates: Offset(14, 18), owner: 'neutral'),
  Village(name: 'Patras', coordinates: Offset(2, 17), owner: 'neutral'),
];

// Starting positions
// Player: (3, 3)
// AI1: (17, 3)
// AI2: (10, 17)
```

---

This plan covers the complete port. Run order: `flutter pub get` → implement Phase 1 → Phase 2 → ... → tests.
