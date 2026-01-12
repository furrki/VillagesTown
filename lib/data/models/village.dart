import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import 'package:latlong2/latlong.dart';
import '../protocols/resource_holder.dart';
import '../protocols/treasury_holder.dart';
import 'building.dart';
import 'geo_coordinate.dart';
import 'nationality.dart';
import 'resource.dart';
import 'village_level.dart';

class Village with ResourceHolder, TreasuryHolder {
  // Historical city names by faction: baseName -> {nationalityId -> localizedName}
  static const Map<String, Map<String, String>> _cityNames = {
    // === MAJOR FACTION CAPITALS ===
    'Constantinople': {
      'byzantine': 'Κωνσταντινούπολις',
      'ottoman': 'İstanbul',
      'crusader': 'Constantinople',
      'bulgarian': 'Цариград',
      'serbian': 'Цариград',
      'armenian': 'Kostandnupolis',
      'mamluk': 'القسطنطينية',
    },
    'Bursa': {
      'byzantine': 'Προύσα',
      'ottoman': 'Bursa',
      'crusader': 'Prusa',
      'bulgarian': 'Бруса',
      'serbian': 'Бруса',
      'armenian': 'Prusa',
      'mamluk': 'بورصة',
    },
    'Acre': {
      'byzantine': 'Ἄκκη',
      'ottoman': 'Akka',
      'crusader': 'Acre',
      'bulgarian': 'Акра',
      'serbian': 'Акра',
      'armenian': 'Akko',
      'mamluk': 'عكا',
    },
    // === MINOR FACTION CAPITALS ===
    'Tarnovo': {
      'byzantine': 'Τύρνοβο',
      'ottoman': 'Tırnova',
      'crusader': 'Tarnovo',
      'bulgarian': 'Търново',
      'serbian': 'Трново',
      'armenian': 'Tarnovo',
      'mamluk': 'ترنوفو',
    },
    'Belgrade': {
      'byzantine': 'Βελιγράδιον',
      'ottoman': 'Belgrad',
      'crusader': 'Alba Graeca',
      'bulgarian': 'Белград',
      'serbian': 'Београд',
      'armenian': 'Belgrad',
      'mamluk': 'بلغراد',
    },
    'Ani': {
      'byzantine': 'Ἄνι',
      'ottoman': 'Ani',
      'crusader': 'Ani',
      'bulgarian': 'Ани',
      'serbian': 'Ани',
      'armenian': 'Ani',
      'mamluk': 'آني',
    },
    'Cairo': {
      'byzantine': 'Κάιρο',
      'ottoman': 'Kahire',
      'crusader': 'Cairo',
      'bulgarian': 'Кайро',
      'serbian': 'Каиро',
      'armenian': 'Kahire',
      'mamluk': 'القاهرة',
    },
    // === BYZANTINE REGION ===
    'Thessaloniki': {
      'byzantine': 'Θεσσαλονίκη',
      'ottoman': 'Selanik',
      'crusader': 'Thessalonica',
      'bulgarian': 'Солун',
      'serbian': 'Солун',
      'armenian': 'Tesaloniki',
      'mamluk': 'سالونيك',
    },
    'Athens': {
      'byzantine': 'Ἀθῆναι',
      'ottoman': 'Atina',
      'crusader': 'Athens',
      'bulgarian': 'Атина',
      'serbian': 'Атина',
      'armenian': 'Atenk',
      'mamluk': 'أثينا',
    },
    'Nicaea': {
      'byzantine': 'Νίκαια',
      'ottoman': 'İznik',
      'crusader': 'Nicaea',
      'bulgarian': 'Никея',
      'serbian': 'Никеја',
      'armenian': 'Nikia',
      'mamluk': 'نيقية',
    },
    'Trebizond': {
      'byzantine': 'Τραπεζοῦς',
      'ottoman': 'Trabzon',
      'crusader': 'Trebizond',
      'bulgarian': 'Трапезунд',
      'serbian': 'Трапезунт',
      'armenian': 'Trapizon',
      'mamluk': 'طرابزون',
    },
    'Smyrna': {
      'byzantine': 'Σμύρνη',
      'ottoman': 'İzmir',
      'crusader': 'Smyrna',
      'bulgarian': 'Смирна',
      'serbian': 'Смирна',
      'armenian': 'Zmyurnia',
      'mamluk': 'إزمير',
    },
    // === OTTOMAN/ANATOLIAN REGION ===
    'Konya': {
      'byzantine': 'Ἰκόνιον',
      'ottoman': 'Konya',
      'crusader': 'Iconium',
      'bulgarian': 'Икониум',
      'serbian': 'Иконија',
      'armenian': 'Ikonia',
      'mamluk': 'قونية',
    },
    'Ankara': {
      'byzantine': 'Ἄγκυρα',
      'ottoman': 'Ankara',
      'crusader': 'Ancyra',
      'bulgarian': 'Анкара',
      'serbian': 'Анкара',
      'armenian': 'Ankara',
      'mamluk': 'أنقرة',
    },
    'Sinope': {
      'byzantine': 'Σινώπη',
      'ottoman': 'Sinop',
      'crusader': 'Sinope',
      'bulgarian': 'Синоп',
      'serbian': 'Синоп',
      'armenian': 'Sinop',
      'mamluk': 'سينوب',
    },
    'Edirne': {
      'byzantine': 'Ἀδριανούπολις',
      'ottoman': 'Edirne',
      'crusader': 'Adrianople',
      'bulgarian': 'Одрин',
      'serbian': 'Једрене',
      'armenian': 'Adrianupolis',
      'mamluk': 'أدرنة',
    },
    // === CRUSADER/LEVANT REGION ===
    'Antioch': {
      'byzantine': 'Ἀντιόχεια',
      'ottoman': 'Antakya',
      'crusader': 'Antioch',
      'bulgarian': 'Антиохия',
      'serbian': 'Антиохија',
      'armenian': 'Antiok',
      'mamluk': 'أنطاكية',
    },
    'Jerusalem': {
      'byzantine': 'Ἱεροσόλυμα',
      'ottoman': 'Kudüs',
      'crusader': 'Jerusalem',
      'bulgarian': 'Йерусалим',
      'serbian': 'Јерусалим',
      'armenian': 'Yerusaghem',
      'mamluk': 'القدس',
    },
    'Tripoli': {
      'byzantine': 'Τρίπολις',
      'ottoman': 'Trablusşam',
      'crusader': 'Tripoli',
      'bulgarian': 'Триполи',
      'serbian': 'Триполи',
      'armenian': 'Tripoli',
      'mamluk': 'طرابلس',
    },
    // === BALKAN REGION ===
    'Sofia': {
      'byzantine': 'Σερδική',
      'ottoman': 'Sofya',
      'crusader': 'Sardica',
      'bulgarian': 'София',
      'serbian': 'Софија',
      'armenian': 'Sofia',
      'mamluk': 'صوفيا',
    },
    'Plovdiv': {
      'byzantine': 'Φιλιππούπολις',
      'ottoman': 'Filibe',
      'crusader': 'Philippopolis',
      'bulgarian': 'Пловдив',
      'serbian': 'Пловдив',
      'armenian': 'Plovdiv',
      'mamluk': 'فيليبه',
    },
    'Nis': {
      'byzantine': 'Ναϊσσός',
      'ottoman': 'Niş',
      'crusader': 'Naissus',
      'bulgarian': 'Ниш',
      'serbian': 'Ниш',
      'armenian': 'Nish',
      'mamluk': 'نيش',
    },
    'Skopje': {
      'byzantine': 'Σκόπια',
      'ottoman': 'Üsküp',
      'crusader': 'Scupi',
      'bulgarian': 'Скопие',
      'serbian': 'Скопље',
      'armenian': 'Skopye',
      'mamluk': 'سكوبيه',
    },
    // === ARMENIAN/CAUCASUS REGION ===
    'Van': {
      'byzantine': 'Οὐάν',
      'ottoman': 'Van',
      'crusader': 'Van',
      'bulgarian': 'Ван',
      'serbian': 'Ван',
      'armenian': 'Van',
      'mamluk': 'وان',
    },
    'Kars': {
      'byzantine': 'Κάρς',
      'ottoman': 'Kars',
      'crusader': 'Kars',
      'bulgarian': 'Карс',
      'serbian': 'Карс',
      'armenian': 'Kars',
      'mamluk': 'قارص',
    },
    'Erzurum': {
      'byzantine': 'Θεοδοσιούπολις',
      'ottoman': 'Erzurum',
      'crusader': 'Theodosiopolis',
      'bulgarian': 'Ерзерум',
      'serbian': 'Ерзурум',
      'armenian': 'Karin',
      'mamluk': 'أرضروم',
    },
    // === MAMLUK/EGYPT REGION ===
    'Alexandria': {
      'byzantine': 'Ἀλεξάνδρεια',
      'ottoman': 'İskenderiye',
      'crusader': 'Alexandria',
      'bulgarian': 'Александрия',
      'serbian': 'Александрија',
      'armenian': 'Aleksandria',
      'mamluk': 'الإسكندرية',
    },
    'Damascus': {
      'byzantine': 'Δαμασκός',
      'ottoman': 'Şam',
      'crusader': 'Damascus',
      'bulgarian': 'Дамаск',
      'serbian': 'Дамаск',
      'armenian': 'Damaskos',
      'mamluk': 'دمشق',
    },
    'Aleppo': {
      'byzantine': 'Βέροια',
      'ottoman': 'Halep',
      'crusader': 'Aleppo',
      'bulgarian': 'Халеп',
      'serbian': 'Алепо',
      'armenian': 'Halep',
      'mamluk': 'حلب',
    },
    'Gaza': {
      'byzantine': 'Γάζα',
      'ottoman': 'Gazze',
      'crusader': 'Gaza',
      'bulgarian': 'Газа',
      'serbian': 'Газа',
      'armenian': 'Gaza',
      'mamluk': 'غزة',
    },
    // === ISLANDS & OTHER ===
    'Rhodes': {
      'byzantine': 'Ῥόδος',
      'ottoman': 'Rodos',
      'crusader': 'Rhodes',
      'bulgarian': 'Родос',
      'serbian': 'Родос',
      'armenian': 'Rodos',
      'mamluk': 'رودس',
    },
    'Crete': {
      'byzantine': 'Κρήτη',
      'ottoman': 'Girit',
      'crusader': 'Candia',
      'bulgarian': 'Крит',
      'serbian': 'Крит',
      'armenian': 'Krit',
      'mamluk': 'كريت',
    },
    'Cyprus': {
      'byzantine': 'Κύπρος',
      'ottoman': 'Kıbrıs',
      'crusader': 'Cyprus',
      'bulgarian': 'Кипър',
      'serbian': 'Кипар',
      'armenian': 'Kipros',
      'mamluk': 'قبرص',
    },
  };

  final String id;
  final String name; // Base name (key for lookup)
  final Nationality nationality;
  GeoCoordinate coordinates;
  String owner;
  VillageLevel level;
  List<Building> buildings;
  @override
  Map<Resource, int> resources;
  @override
  double money;
  int population;
  int happiness; // 0-100
  int garrisonStrength;
  int garrisonMaxStrength;
  bool underSiege;
  int recruitsThisTurn;
  double garrisonRegenAccumulator;
  List<LatLng>? customTerritory;

  Village({
    String? id,
    required this.name,
    required this.nationality,
    required this.coordinates,
    required this.owner,
    this.level = VillageLevel.village,
    List<Building>? buildings,
    Map<Resource, int>? resources,
    this.money = 1000.0,
    this.population = 100,
    this.happiness = 75,
    this.garrisonStrength = 15,
    this.garrisonMaxStrength = 20,
    this.underSiege = false,
    this.recruitsThisTurn = 0,
    this.garrisonRegenAccumulator = 0.0,
    this.customTerritory,
  })  : id = id ?? const Uuid().v4(),
        buildings = buildings ?? Building.starter(),
        resources = resources ??
            (owner == 'neutral'
                ? {
                    Resource.food: 20,
                    Resource.wood: 15,
                    Resource.iron: 5,
                    Resource.gold: 30,
                  }
                : {
                    Resource.food: 100,
                    Resource.wood: 100,
                    Resource.iron: 50,
                    Resource.gold: 300,
                  }) {
    // Neutral villages have different defaults
    if (owner == 'neutral') {
      garrisonStrength = 8;
      garrisonMaxStrength = 15;
      population = 50;
    }
  }

  // Get the city name based on controlling faction
  String displayName(Nationality? ownerNationality) {
    final natId = ownerNationality?.id ?? nationality.id;
    final names = _cityNames[name];
    if (names == null) return name;
    return names[natId] ?? name;
  }

  // Computed properties
  int get maxBuildings => level.maxBuildings;
  double get productionBonus => level.productionBonus;

  double get defenseBonus {
    var bonus = 0.2;
    for (final b in buildings) {
      bonus += b.defenseBonus;
    }
    bonus += level.defenseBonus;
    return bonus;
  }

  // totalHappiness getter removed (happinessBonus unused)

  int get populationCapacity {
    var cap = level.populationCap;
    // Aqueduct logic removed (dead feature)
    return cap;
  }

  bool get canBuildMore => buildings.length < maxBuildings;

  int get maxRecruitsPerTurn {
    var cap = 3;
    final barracks = buildings.firstWhereOrNull((b) => b.name == 'Barracks');
    if (barracks != null) cap += barracks.level;
    if (buildings.any((b) => b.name == 'Archery Range')) cap += 1;
    return cap;
  }

  int get computedGarrisonMax {
    var maxGarrison = 20; // Base garrison capacity
    final barracks = buildings.firstWhereOrNull((b) => b.name == 'Barracks');
    if (barracks != null) maxGarrison += 10 * barracks.level;
    maxGarrison += 20 * fortressLevel;
    maxGarrison += level.garrisonBonus;
    return maxGarrison;
  }

  /// Get fortress level (0 if no fortress).
  int get fortressLevel {
    final fortress = buildings.firstWhereOrNull((b) => b.name == 'Fortress');
    return fortress?.level ?? 0;
  }

  Village copyWith({
    String? id,
    String? name,
    Nationality? nationality,
    GeoCoordinate? coordinates,
    String? owner,
    VillageLevel? level,
    List<Building>? buildings,
    Map<Resource, int>? resources,
    double? money,
    int? population,
    int? happiness,
    int? garrisonStrength,
    int? garrisonMaxStrength,
    bool? underSiege,
    int? recruitsThisTurn,
    double? garrisonRegenAccumulator,
    List<LatLng>? customTerritory,
  }) {
    return Village(
      id: id ?? this.id,
      name: name ?? this.name,
      nationality: nationality ?? this.nationality,
      coordinates: coordinates ?? this.coordinates,
      owner: owner ?? this.owner,
      level: level ?? this.level,
      buildings: buildings ?? List.from(this.buildings),
      resources: resources ?? Map.from(this.resources),
      money: money ?? this.money,
      population: population ?? this.population,
      happiness: happiness ?? this.happiness,
      garrisonStrength: garrisonStrength ?? this.garrisonStrength,
      garrisonMaxStrength: garrisonMaxStrength ?? this.garrisonMaxStrength,
      underSiege: underSiege ?? this.underSiege,
      recruitsThisTurn: recruitsThisTurn ?? this.recruitsThisTurn,
      garrisonRegenAccumulator:
          garrisonRegenAccumulator ?? this.garrisonRegenAccumulator,
      customTerritory: customTerritory ?? this.customTerritory,
    );
  }

  void addBuilding(Building building) {
    if (canBuildMore) {
      buildings.add(building);
    }
  }

  void modifyPopulation(int amount) {
    population = max(0, min(population + amount, populationCapacity));
  }

  void modifyHappiness(int amount) {
    happiness = max(0, min(happiness + amount, 100));
  }

  void regenerateGarrison() {
    if (underSiege) {
      underSiege = false;
      return;
    }
    // Base regen + building bonuses
    var recovery = 1.0; // Base recovery
    final barracks = buildings.firstWhereOrNull((b) => b.name == 'Barracks');
    if (barracks != null) recovery += 0.5 * barracks.level;
    final fortress = buildings.firstWhereOrNull((b) => b.name == 'Fortress');
    if (fortress != null) recovery += 1.0 * fortress.level;

    garrisonRegenAccumulator += recovery;
    final wholeUnits = garrisonRegenAccumulator.floor();
    garrisonRegenAccumulator -= wholeUnits;

    garrisonMaxStrength = computedGarrisonMax;
    garrisonStrength = min(garrisonStrength + wholeUnits, garrisonMaxStrength);
  }

  void damageGarrison(int amount) {
    garrisonStrength = max(0, garrisonStrength - amount);
  }
}
