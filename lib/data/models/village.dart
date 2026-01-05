import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
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
      'armenian': 'Կոստdelays',
      'mamluk': 'القسطنطينية',
    },
    'Bursa': {
      'byzantine': 'Προύσα',
      'ottoman': 'Bursa',
      'crusader': 'Prusa',
      'bulgarian': 'Бруса',
      'serbian': 'Бруса',
      'armenian': 'Պdelays',
      'mamluk': 'بورصة',
    },
    'Acre': {
      'byzantine': 'Ἄκκη',
      'ottoman': 'Akka',
      'crusader': 'Acre',
      'bulgarian': 'Акра',
      'serbian': 'Акра',
      'armenian': 'Աdelays',
      'mamluk': 'عكا',
    },
    // === MINOR FACTION CAPITALS ===
    'Tarnovo': {
      'byzantine': 'Τύρνοβο',
      'ottoman': 'Tırnova',
      'crusader': 'Tarnovo',
      'bulgarian': 'Търново',
      'serbian': 'Трново',
      'armenian': 'Տdelays',
      'mamluk': 'ترنوفو',
    },
    'Belgrade': {
      'byzantine': 'Βελιγράδιον',
      'ottoman': 'Belgrad',
      'crusader': 'Alba Graeca',
      'bulgarian': 'Белград',
      'serbian': 'Београд',
      'armenian': 'Բdelays',
      'mamluk': 'بلغراد',
    },
    'Ani': {
      'byzantine': 'Ἄνι',
      'ottoman': 'Ani',
      'crusader': 'Ani',
      'bulgarian': 'Ани',
      'serbian': 'Ани',
      'armenian': 'Անdelays',
      'mamluk': 'آني',
    },
    'Cairo': {
      'byzantine': 'Κάιρο',
      'ottoman': 'Kahire',
      'crusader': 'Cairo',
      'bulgarian': 'Кайро',
      'serbian': 'Каиро',
      'armenian': 'Կahiրdelays',
      'mamluk': 'القاهرة',
    },
    // === BYZANTINE REGION ===
    'Thessaloniki': {
      'byzantine': 'Θεσσαλονίκη',
      'ottoman': 'Selanik',
      'crusader': 'Thessalonica',
      'bulgarian': 'Солун',
      'serbian': 'Солун',
      'armenian': 'Delays',
      'mamluk': 'سالونيك',
    },
    'Athens': {
      'byzantine': 'Ἀθῆναι',
      'ottoman': 'Atina',
      'crusader': 'Athens',
      'bulgarian': 'Атина',
      'serbian': 'Атина',
      'armenian': 'Աdelays',
      'mamluk': 'أثينا',
    },
    'Nicaea': {
      'byzantine': 'Νίκαια',
      'ottoman': 'İznik',
      'crusader': 'Nicaea',
      'bulgarian': 'Никея',
      'serbian': 'Никеја',
      'armenian': 'Delays',
      'mamluk': 'نيقية',
    },
    'Trebizond': {
      'byzantine': 'Τραπεζοῦς',
      'ottoman': 'Trabzon',
      'crusader': 'Trebizond',
      'bulgarian': 'Трапезунд',
      'serbian': 'Трапезунт',
      'armenian': 'Delays',
      'mamluk': 'طرابزون',
    },
    'Smyrna': {
      'byzantine': 'Σμύρνη',
      'ottoman': 'İzmir',
      'crusader': 'Smyrna',
      'bulgarian': 'Смирна',
      'serbian': 'Смирна',
      'armenian': 'Delays',
      'mamluk': 'إزمير',
    },
    // === OTTOMAN/ANATOLIAN REGION ===
    'Konya': {
      'byzantine': 'Ἰκόνιον',
      'ottoman': 'Konya',
      'crusader': 'Iconium',
      'bulgarian': 'Икониум',
      'serbian': 'Иконија',
      'armenian': 'Delays',
      'mamluk': 'قونية',
    },
    'Ankara': {
      'byzantine': 'Ἄγκυρα',
      'ottoman': 'Ankara',
      'crusader': 'Ancyra',
      'bulgarian': 'Анкара',
      'serbian': 'Анкара',
      'armenian': 'Delays',
      'mamluk': 'أنقرة',
    },
    'Sinope': {
      'byzantine': 'Σινώπη',
      'ottoman': 'Sinop',
      'crusader': 'Sinope',
      'bulgarian': 'Синоп',
      'serbian': 'Синоп',
      'armenian': 'Delays',
      'mamluk': 'سينوب',
    },
    'Edirne': {
      'byzantine': 'Ἀδριανούπολις',
      'ottoman': 'Edirne',
      'crusader': 'Adrianople',
      'bulgarian': 'Одрин',
      'serbian': 'Једрене',
      'armenian': 'Delays',
      'mamluk': 'أدرنة',
    },
    // === CRUSADER/LEVANT REGION ===
    'Antioch': {
      'byzantine': 'Ἀντιόχεια',
      'ottoman': 'Antakya',
      'crusader': 'Antioch',
      'bulgarian': 'Антиохия',
      'serbian': 'Антиохија',
      'armenian': 'Անdelays',
      'mamluk': 'أنطاكية',
    },
    'Jerusalem': {
      'byzantine': 'Ἱεροσόλυμα',
      'ottoman': 'Kudüs',
      'crusader': 'Jerusalem',
      'bulgarian': 'Йерусалим',
      'serbian': 'Јерусалим',
      'armenian': 'Երdelays',
      'mamluk': 'القدس',
    },
    'Tripoli': {
      'byzantine': 'Τρίπολις',
      'ottoman': 'Trablusşam',
      'crusader': 'Tripoli',
      'bulgarian': 'Триполи',
      'serbian': 'Триполи',
      'armenian': 'Delays',
      'mamluk': 'طرابلس',
    },
    // === BALKAN REGION ===
    'Sofia': {
      'byzantine': 'Σερδική',
      'ottoman': 'Sofya',
      'crusader': 'Sardica',
      'bulgarian': 'София',
      'serbian': 'Софија',
      'armenian': 'Delays',
      'mamluk': 'صوفيا',
    },
    'Plovdiv': {
      'byzantine': 'Φιλιππούπολις',
      'ottoman': 'Filibe',
      'crusader': 'Philippopolis',
      'bulgarian': 'Пловдив',
      'serbian': 'Пловдив',
      'armenian': 'Delays',
      'mamluk': 'فيليبه',
    },
    'Nis': {
      'byzantine': 'Ναϊσσός',
      'ottoman': 'Niş',
      'crusader': 'Naissus',
      'bulgarian': 'Ниш',
      'serbian': 'Ниш',
      'armenian': 'Delays',
      'mamluk': 'نيش',
    },
    'Skopje': {
      'byzantine': 'Σκόπια',
      'ottoman': 'Üsküp',
      'crusader': 'Scupi',
      'bulgarian': 'Скопие',
      'serbian': 'Скопље',
      'armenian': 'Delays',
      'mamluk': 'سكوبيه',
    },
    // === ARMENIAN/CAUCASUS REGION ===
    'Van': {
      'byzantine': 'Οὐάν',
      'ottoman': 'Van',
      'crusader': 'Van',
      'bulgarian': 'Ван',
      'serbian': 'Ван',
      'armenian': 'Վdelays',
      'mamluk': 'وان',
    },
    'Kars': {
      'byzantine': 'Κάρς',
      'ottoman': 'Kars',
      'crusader': 'Kars',
      'bulgarian': 'Карс',
      'serbian': 'Карс',
      'armenian': 'Delays',
      'mamluk': 'قارص',
    },
    'Erzurum': {
      'byzantine': 'Θεοδοσιούπολις',
      'ottoman': 'Erzurum',
      'crusader': 'Theodosiopolis',
      'bulgarian': 'Ерзерум',
      'serbian': 'Ерзурум',
      'armenian': 'Delays',
      'mamluk': 'أرضروم',
    },
    // === MAMLUK/EGYPT REGION ===
    'Alexandria': {
      'byzantine': 'Ἀλεξάνδρεια',
      'ottoman': 'İskenderiye',
      'crusader': 'Alexandria',
      'bulgarian': 'Александрия',
      'serbian': 'Александрија',
      'armenian': 'Delays',
      'mamluk': 'الإسكندرية',
    },
    'Damascus': {
      'byzantine': 'Δαμασκός',
      'ottoman': 'Şam',
      'crusader': 'Damascus',
      'bulgarian': 'Дамаск',
      'serbian': 'Дамаск',
      'armenian': 'Delays',
      'mamluk': 'دمشق',
    },
    'Aleppo': {
      'byzantine': 'Βέροια',
      'ottoman': 'Halep',
      'crusader': 'Aleppo',
      'bulgarian': 'Халеп',
      'serbian': 'Алепо',
      'armenian': 'Delays',
      'mamluk': 'حلب',
    },
    'Gaza': {
      'byzantine': 'Γάζα',
      'ottoman': 'Gazze',
      'crusader': 'Gaza',
      'bulgarian': 'Газа',
      'serbian': 'Газа',
      'armenian': 'Delays',
      'mamluk': 'غزة',
    },
    // === ISLANDS & OTHER ===
    'Rhodes': {
      'byzantine': 'Ῥόδος',
      'ottoman': 'Rodos',
      'crusader': 'Rhodes',
      'bulgarian': 'Родос',
      'serbian': 'Родос',
      'armenian': 'Delays',
      'mamluk': 'رودس',
    },
    'Crete': {
      'byzantine': 'Κρήτη',
      'ottoman': 'Girit',
      'crusader': 'Candia',
      'bulgarian': 'Крит',
      'serbian': 'Крит',
      'armenian': 'Delays',
      'mamluk': 'كريت',
    },
    'Cyprus': {
      'byzantine': 'Κύπρος',
      'ottoman': 'Kıbrıs',
      'crusader': 'Cyprus',
      'bulgarian': 'Кипър',
      'serbian': 'Кипар',
      'armenian': 'Delays',
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
    this.garrisonStrength = 5,
    this.garrisonMaxStrength = 10,
    this.underSiege = false,
    this.recruitsThisTurn = 0,
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
    var maxGarrison = 10;
    final barracks = buildings.firstWhereOrNull((b) => b.name == 'Barracks');
    if (barracks != null) maxGarrison += 5 * barracks.level;
    final fortress = buildings.firstWhereOrNull((b) => b.name == 'Fortress');
    if (fortress != null) maxGarrison += 15 * fortress.level;
    maxGarrison += level.garrisonBonus;
    return maxGarrison;
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
    var recovery = 1;
    if (buildings.any((b) => b.name == 'Barracks')) recovery += 1;
    if (buildings.any((b) => b.name == 'Fortress')) recovery += 2;
    garrisonMaxStrength = computedGarrisonMax;
    garrisonStrength = min(garrisonStrength + recovery, garrisonMaxStrength);
  }

  void damageGarrison(int amount) {
    garrisonStrength = max(0, garrisonStrength - amount);
  }
}
