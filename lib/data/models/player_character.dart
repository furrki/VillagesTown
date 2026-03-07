import 'dart:math';
import 'character_origin.dart';
import 'mission.dart';
import 'trade_good.dart';

enum PlayerState { atCity, traveling }

enum ProgressionStage { wanderer, merchant, mercenary, vassal, lord }

enum PlayerAllegiance { independent, mercenary, vassal }

class PlayerCharacter {
  String name;
  CharacterOrigin? origin;

  PlayerState state;
  String? currentCityId;
  String? travelOriginId;
  String? travelDestinationId;
  double travelProgress;
  int travelTotalTicks;

  int gold;
  Map<TradeGood, int> cargo;
  int cargoCapacity;
  int packMules;
  int tradeWagons;

  ProgressionStage stage;
  PlayerAllegiance allegiance;
  String? factionId;

  Map<String, int> reputation;

  int combatSkill;
  int leadershipSkill;
  int tacticsSkill;
  int tradeSkill;
  int scoutingSkill;

  int totalGoldEarned;
  int contractsCompleted;
  int battlesWon;

  List<Mission> activeMissions;
  List<Mission> completedMissions;

  PlayerCharacter({
    this.name = '',
    this.origin,
    this.state = PlayerState.atCity,
    this.currentCityId,
    this.travelOriginId,
    this.travelDestinationId,
    this.travelProgress = 0.0,
    this.travelTotalTicks = 0,
    this.gold = 150,
    Map<TradeGood, int>? cargo,
    this.cargoCapacity = 20,
    this.packMules = 0,
    this.tradeWagons = 0,
    this.stage = ProgressionStage.wanderer,
    this.allegiance = PlayerAllegiance.independent,
    this.factionId,
    Map<String, int>? reputation,
    this.combatSkill = 1,
    this.leadershipSkill = 1,
    this.tacticsSkill = 1,
    this.tradeSkill = 1,
    this.scoutingSkill = 1,
    this.totalGoldEarned = 0,
    this.contractsCompleted = 0,
    this.battlesWon = 0,
    List<Mission>? activeMissions,
    List<Mission>? completedMissions,
  })  : cargo = cargo ?? {},
        reputation = reputation ?? {},
        activeMissions = activeMissions ?? [],
        completedMissions = completedMissions ?? [];

  int get maxWarbandSize => switch (stage) {
        ProgressionStage.wanderer => 10,
        ProgressionStage.merchant => 20,
        ProgressionStage.mercenary => 35,
        ProgressionStage.vassal => 50,
        ProgressionStage.lord => 70,
      };

  int get totalCargoCapacity => 20 + (packMules * 15) + (tradeWagons * 30);

  int get currentCargoCount =>
      cargo.values.fold(0, (sum, count) => sum + count);

  bool get isOverEncumbered => currentCargoCount > totalCargoCapacity * 0.8;

  double get travelSpeedModifier {
    final ratio = currentCargoCount / max(1, totalCargoCapacity);
    if (ratio > 0.8) return 0.5;
    if (ratio > 0.5) return 0.75;
    return 1.0;
  }

  int get marketTaxPercent => switch (stage) {
        ProgressionStage.wanderer => 10,
        ProgressionStage.merchant => 5,
        _ => 0,
      };

  void addReputation(String factionId, int amount) {
    final current = reputation[factionId] ?? 0;
    reputation[factionId] = (current + amount).clamp(-100, 100);
  }

  String get stageTitle => switch (stage) {
        ProgressionStage.wanderer => 'Wanderer',
        ProgressionStage.merchant => 'Merchant',
        ProgressionStage.mercenary => 'Mercenary',
        ProgressionStage.vassal => 'Vassal',
        ProgressionStage.lord => 'Lord',
      };

  int cargoOf(TradeGood good) => cargo[good] ?? 0;

  void addCargo(TradeGood good, int quantity) {
    cargo[good] = (cargo[good] ?? 0) + quantity;
  }

  void removeCargo(TradeGood good, int quantity) {
    final current = cargo[good] ?? 0;
    if (quantity >= current) {
      cargo.remove(good);
    } else {
      cargo[good] = current - quantity;
    }
  }

  void checkProgression() {
    if (stage == ProgressionStage.wanderer && totalGoldEarned >= 500) {
      stage = ProgressionStage.merchant;
    } else if (stage == ProgressionStage.merchant && battlesWon >= 5) {
      stage = ProgressionStage.mercenary;
    } else if (stage == ProgressionStage.mercenary && battlesWon >= 15 && totalGoldEarned >= 2000) {
      stage = ProgressionStage.vassal;
    } else if (stage == ProgressionStage.vassal && totalGoldEarned >= 5000 && battlesWon >= 30) {
      stage = ProgressionStage.lord;
    }
  }

  void earnGold(int amount) {
    gold += amount;
    totalGoldEarned += amount;
  }

  double get tradeDiscount => tradeSkill * 0.02;
  double get combatBonus => combatSkill * 0.03;
  double get scoutingRange => 1.0 + scoutingSkill * 0.1;

  Map<String, dynamic> toJson() => {
    'name': name,
    'origin': origin?.toJson(),
    'state': state.name,
    'currentCityId': currentCityId,
    'travelOriginId': travelOriginId,
    'travelDestinationId': travelDestinationId,
    'travelProgress': travelProgress,
    'travelTotalTicks': travelTotalTicks,
    'gold': gold,
    'cargo': cargo.map((k, v) => MapEntry(k.name, v)),
    'cargoCapacity': cargoCapacity,
    'packMules': packMules,
    'tradeWagons': tradeWagons,
    'stage': stage.name,
    'allegiance': allegiance.name,
    'factionId': factionId,
    'reputation': reputation,
    'combatSkill': combatSkill,
    'leadershipSkill': leadershipSkill,
    'tacticsSkill': tacticsSkill,
    'tradeSkill': tradeSkill,
    'scoutingSkill': scoutingSkill,
    'totalGoldEarned': totalGoldEarned,
    'contractsCompleted': contractsCompleted,
    'battlesWon': battlesWon,
    'activeMissions': activeMissions.map((m) => m.toJson()).toList(),
    'completedMissions': completedMissions.map((m) => m.toJson()).toList(),
  };

  factory PlayerCharacter.fromJson(Map<String, dynamic> json) {
    return PlayerCharacter(
      name: json['name'] as String? ?? '',
      origin: json['origin'] != null
          ? CharacterOrigin.fromJson(json['origin'] as Map<String, dynamic>)
          : null,
      state: PlayerState.values.firstWhere((e) => e.name == json['state'], orElse: () => PlayerState.atCity),
      currentCityId: json['currentCityId'] as String?,
      travelOriginId: json['travelOriginId'] as String?,
      travelDestinationId: json['travelDestinationId'] as String?,
      travelProgress: (json['travelProgress'] as num?)?.toDouble() ?? 0.0,
      travelTotalTicks: json['travelTotalTicks'] as int? ?? 0,
      gold: json['gold'] as int? ?? 150,
      cargo: (json['cargo'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(
          TradeGood.values.firstWhere((e) => e.name == k, orElse: () => TradeGood.grain),
          v as int,
        ),
      ),
      cargoCapacity: json['cargoCapacity'] as int? ?? 20,
      packMules: json['packMules'] as int? ?? 0,
      tradeWagons: json['tradeWagons'] as int? ?? 0,
      stage: ProgressionStage.values.firstWhere((e) => e.name == json['stage'], orElse: () => ProgressionStage.wanderer),
      allegiance: PlayerAllegiance.values.firstWhere((e) => e.name == json['allegiance'], orElse: () => PlayerAllegiance.independent),
      factionId: json['factionId'] as String?,
      reputation: (json['reputation'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as int)),
      combatSkill: json['combatSkill'] as int? ?? 1,
      leadershipSkill: json['leadershipSkill'] as int? ?? 1,
      tacticsSkill: json['tacticsSkill'] as int? ?? 1,
      tradeSkill: json['tradeSkill'] as int? ?? 1,
      scoutingSkill: json['scoutingSkill'] as int? ?? 1,
      totalGoldEarned: json['totalGoldEarned'] as int? ?? 0,
      contractsCompleted: json['contractsCompleted'] as int? ?? 0,
      battlesWon: json['battlesWon'] as int? ?? 0,
      activeMissions: (json['activeMissions'] as List<dynamic>?)
          ?.map((m) => Mission.fromJson(m as Map<String, dynamic>))
          .toList(),
      completedMissions: (json['completedMissions'] as List<dynamic>?)
          ?.map((m) => Mission.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
