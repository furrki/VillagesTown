enum VillageLevel {
  village(
    maxBuildings: 8,
    productionBonus: 0.1,
    defenseBonus: 0.0,
    populationCap: 200,
    garrisonBonus: 0,
  ),
  town(
    maxBuildings: 12,
    productionBonus: 0.2,
    defenseBonus: 0.0,
    populationCap: 500,
    garrisonBonus: 5,
  ),
  district(
    maxBuildings: 16,
    productionBonus: 0.3,
    defenseBonus: 0.0,
    populationCap: 1000,
    garrisonBonus: 10,
  ),
  castle(
    maxBuildings: 20,
    productionBonus: 0.4,
    defenseBonus: 0.25,
    populationCap: 2000,
    garrisonBonus: 20,
  ),
  city(
    maxBuildings: 30,
    productionBonus: 0.5,
    defenseBonus: 0.5,
    populationCap: 5000,
    garrisonBonus: 30,
  );

  final int maxBuildings;
  final double productionBonus;
  final double defenseBonus;
  final int populationCap;
  final int garrisonBonus;

  const VillageLevel({
    required this.maxBuildings,
    required this.productionBonus,
    required this.defenseBonus,
    required this.populationCap,
    required this.garrisonBonus,
  });
}
