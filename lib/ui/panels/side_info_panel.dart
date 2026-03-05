import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/army.dart';
import '../../data/models/building.dart';
import '../../data/models/village.dart';
import '../../data/models/resource.dart';
import '../../data/models/unit_type.dart';
import '../../data/models/game_event.dart';
import '../../data/models/victory_condition.dart';
import '../../data/models/village_trait.dart';
import '../../providers/game_provider.dart';
import '../components/owner_flag_view.dart';
import '../components/defender_strength_bar.dart';
import '../../engines/game_manager.dart';
import '../../engines/victory_engine.dart';

class SideInfoPanel extends StatelessWidget {
  final Village? selectedVillage;
  final Army? selectedArmy;
  final VoidCallback onEndTurn;
  final bool isProcessingTurn;
  final void Function(Building)? onBuild;
  final void Function(Building)? onUpgrade;
  final void Function(UnitType)? onRecruit;
  final void Function(Army)? onSelectArmy;

  const SideInfoPanel({
    super.key,
    this.selectedVillage,
    this.selectedArmy,
    required this.onEndTurn,
    required this.isProcessingTurn,
    this.onBuild,
    this.onUpgrade,
    this.onRecruit,
    this.onSelectArmy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0D0D),
      child: Column(
        children: [
          // Top bar with turn counter
          Consumer<GameProvider>(
            builder: (context, provider, _) {
              final game = provider.gameManager;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.black,
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${game.currentTurn}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Turn', style: TextStyle(fontSize: 12, color: Colors.white54)),
                    const Spacer(),
                    Text('${game.getPlayerVillages('player').length}/${game.map.villages.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(width: 4),
                    const Icon(Icons.emoji_events, size: 14, color: Colors.yellow),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1, color: Colors.white10),
          // Victory Progress + Active Events
          Consumer<GameProvider>(
            builder: (context, provider, _) {
              final game = provider.gameManager;
              final progress = VictoryEngine.getAllProgress(game, 'player');
              final selected = game.selectedVictoryType;
              return Column(
                children: [
                  _VictoryProgressBar(progress: progress, selectedType: selected),
                  if (game.activeEvents.isNotEmpty)
                    _ActiveEventsBar(events: game.activeEvents),
                ],
              );
            },
          ),
          const Divider(height: 1, color: Colors.white10),
          // Content
          Expanded(
            child: selectedVillage != null
                ? _VillageInfoSection(
                    village: selectedVillage!,
                    onBuild: onBuild,
                    onUpgrade: onUpgrade,
                    onRecruit: onRecruit,
                    onSelectArmy: onSelectArmy,
                  )
                : selectedArmy != null
                    ? _ArmyInfoSection(army: selectedArmy!)
                    : _EmptySection(),
          ),
          // End Turn Button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessingTurn ? null : onEndTurn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isProcessingTurn
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_forward, color: Colors.white),
                          SizedBox(width: 8),
                          Text('End Turn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VillageInfoSection extends StatelessWidget {
  final Village village;
  final void Function(Building)? onBuild;
  final void Function(Building)? onUpgrade;
  final void Function(UnitType)? onRecruit;
  final void Function(Army)? onSelectArmy;

  const _VillageInfoSection({
    required this.village,
    this.onBuild,
    this.onUpgrade,
    this.onRecruit,
    this.onSelectArmy,
  });

  bool get isPlayerVillage => village.owner == 'player';

  List<Building> get availableBuildings {
    return Building.all.where((b) => !village.buildings.any((vb) => vb.name == b.name)).toList();
  }

  List<UnitType> get availableUnits {
    List<UnitType> units = [];
    final hasBarracks = village.buildings.any((b) => b.name == 'Barracks');
    final hasArchery = village.buildings.any((b) => b.name == 'Archery Range');
    final hasStables = village.buildings.any((b) => b.name == 'Stables');
    if (hasBarracks) units.addAll([UnitType.militia, UnitType.spearman, UnitType.swordsman]);
    if (hasArchery) units.addAll([UnitType.archer, UnitType.crossbowman]);
    if (hasStables) units.addAll([UnitType.lightCavalry, UnitType.knight]);
    return units;
  }

  Widget _buildSiegeAlert(GameManager game) {
    final besiegers = game.getBesiegingArmiesAt(village.id);
    if (besiegers.isEmpty) return const SizedBox.shrink();

    final totalEnemyUnits = besiegers.fold(0, (sum, a) => sum + a.unitCount);
    final turnsUntilAssault = besiegers.first.siegeTurns >= 1 ? 0 : 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'UNDER SIEGE!',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${besiegers.first.name} with $totalEnemyUnits units',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            turnsUntilAssault == 0
                ? 'Assault imminent next turn!'
                : 'Assault in $turnsUntilAssault turn(s)',
            style: TextStyle(
              color: turnsUntilAssault == 0 ? Colors.red : Colors.white70,
              fontSize: 12,
            ),
          ),
          if (isPlayerVillage) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  game.sallyOut(village.id);
                },
                icon: const Icon(Icons.sports_kabaddi, size: 18),
                label: const Text('Sally Out (No Fortress Bonus)'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final game = provider.gameManager;
        final resources = game.getGlobalResources('player');
        final armies = game.getArmiesAt(village.id);
        final armyStrength = armies.fold(0, (sum, a) => sum + a.strength);

        return SingleChildScrollView(
          key: PageStorageKey('village_${village.id}'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  OwnerFlagView(owner: village.owner, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(game.getVillageDisplayName(village), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                            if (village.trait != VillageTrait.none)
                              Tooltip(
                                message: '${village.trait.displayName}: ${village.trait.description}',
                                child: Text(village.trait.emoji, style: const TextStyle(fontSize: 20)),
                              ),
                          ],
                        ),
                        Text(
                          isPlayerVillage ? 'Level ${village.level.index + 1}' : _ownerLabel,
                          style: TextStyle(fontSize: 14, color: isPlayerVillage ? Colors.green : Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Siege Alert
              _buildSiegeAlert(game),

              // Stats Grid
              _StatsGrid(village: village, armyStrength: armyStrength),

              if (isPlayerVillage) ...[
                // BUILD NEW Section
                if (village.buildings.length < village.maxBuildings && onBuild != null) ...[
                  const SizedBox(height: 20),
                  Text('BUILD NEW', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableBuildings.map((b) => _BuildButton(
                      building: b,
                      resources: resources,
                      onTap: () => onBuild!(b),
                    )).toList(),
                  ),
                ],

                // UPGRADE Section
                if (village.buildings.isNotEmpty && onUpgrade != null) ...[
                  const SizedBox(height: 20),
                  Text('UPGRADE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: village.buildings.map((b) => _UpgradeButton(
                      building: b,
                      resources: resources,
                      onTap: () => onUpgrade!(b),
                    )).toList(),
                  ),
                ],

                // RECRUIT Section
                if (onRecruit != null) ...[
                  const SizedBox(height: 20),
                  if (availableUnits.isNotEmpty) ...[
                    Text('RECRUIT UNITS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableUnits.map((t) => _RecruitButton(
                        type: t,
                        resources: resources,
                        onTap: () => onRecruit!(t),
                      )).toList(),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Build military buildings to recruit',
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                // Resources
                const SizedBox(height: 20),
                Text('VILLAGE RESOURCES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5))),
                const SizedBox(height: 8),
                _ResourcesRow(resources: village.resources),

                // COMMAND CENTER (Army Management)
                if (onSelectArmy != null) ...[
                  const SizedBox(height: 20),
                  Text('COMMAND CENTER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5))),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final stationedArmies = armies.where((a) => a.owner == 'player' && !a.isMarching).toList();
                      if (stationedArmies.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'No troops stationed here.\nRecruit units to build an army.',
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return Column(
                        children: stationedArmies.map((army) => _ArmyCard(
                          army: army,
                          onMarch: () => onSelectArmy!(army),
                        )).toList(),
                      );
                    },
                  ),
                ],
              ] else ...[
                // Enemy village info
                const SizedBox(height: 20),
                Builder(
                  builder: (context) {
                    final game = GameManager.shared;
                    final stationedArmies = game.getArmiesAt(village.id).where((a) => a.owner == village.owner && !a.isMarching);
                    final armyCount = stationedArmies.fold(0, (sum, a) => sum + a.unitCount);
                    final totalDefenders = village.garrisonStrength + armyCount;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shield, color: Colors.red),
                              const SizedBox(width: 8),
                              Text('Defenders: $totalDefenders', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DefenderStrengthBar(
                            garrisonStrength: village.garrisonStrength,
                            armyStrength: armyCount,
                            height: 8,
                            showLegend: true,
                          ),
                          const SizedBox(height: 8),
                          Text('Send army to conquer', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String get _ownerLabel {
    switch (village.owner) {
      case 'neutral': return 'Neutral';
      case 'ai1':
      case 'ai2': return 'Enemy Territory';
      default: return village.owner;
    }
  }
}

class _StatsGrid extends StatelessWidget {
  final Village village;
  final int armyStrength;

  const _StatsGrid({required this.village, required this.armyStrength});

  int get _armyUnitCount {
    final game = GameManager.shared;
    final stationedArmies = game.getArmiesAt(village.id).where((a) => a.owner == village.owner && !a.isMarching);
    return stationedArmies.fold(0, (sum, a) => sum + a.unitCount);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _StatTile(icon: Icons.people, value: '${village.population}', label: 'Population', color: Colors.blue)),
              Expanded(child: _StatTile(icon: Icons.apartment, value: '${village.buildings.length}/${village.maxBuildings}', label: 'Buildings', color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          DefenderStrengthBar(
            garrisonStrength: village.garrisonStrength,
            armyStrength: _armyUnitCount,
            height: 8,
            showLegend: true,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5))),
      ],
    );
  }
}

class _BuildButton extends StatelessWidget {
  final Building building;
  final Map<Resource, int> resources;
  final VoidCallback onTap;

  const _BuildButton({required this.building, required this.resources, required this.onTap});

  bool get canAfford {
    for (final entry in building.baseCost.entries) {
      if ((resources[entry.key] ?? 0) < entry.value) return false;
    }
    return true;
  }

  String get icon {
    switch (building.name) {
      case 'Farm': return '🌾';
      case 'Lumber Mill': return '🪵';
      case 'Iron Mine': return '⛏️';
      case 'Market': return '🏪';
      case 'Barracks': return '⚔️';
      case 'Archery Range': return '🏹';
      case 'Stables': return '🐴';
      case 'Fortress': return '🏰';
      case 'Granary': return '🏛️';
      // Temple and Library removed
      default: return '🏠';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canAfford ? onTap : null,
      child: Opacity(
        opacity: canAfford ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: canAfford ? Border.all(color: Colors.green.withOpacity(0.5)) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(building.name, style: const TextStyle(fontSize: 12, color: Colors.white)),
              const SizedBox(width: 6),
              Text('💰${building.baseCost[Resource.gold] ?? 0}', style: TextStyle(fontSize: 10, color: canAfford ? Colors.yellow : Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  final Building building;
  final Map<Resource, int> resources;
  final VoidCallback onTap;

  const _UpgradeButton({required this.building, required this.resources, required this.onTap});

  Map<Resource, int> get upgradeCost {
    return building.baseCost.map((k, v) => MapEntry(k, (v * (building.level + 1) * 0.8).round()));
  }

  bool get canUpgrade {
    if (building.level >= 5) return false;
    for (final entry in upgradeCost.entries) {
      if ((resources[entry.key] ?? 0) < entry.value) return false;
    }
    return true;
  }

  String get icon {
    switch (building.name) {
      case 'Farm': return '🌾';
      case 'Lumber Mill': return '🪵';
      case 'Iron Mine': return '⛏️';
      case 'Market': return '🏪';
      case 'Barracks': return '⚔️';
      case 'Archery Range': return '🏹';
      case 'Stables': return '🐴';
      case 'Fortress': return '🏰';
      case 'Granary': return '🏛️';
      // Temple and Library removed
      default: return '🏠';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canUpgrade ? onTap : null,
      child: Opacity(
        opacity: canUpgrade || building.level >= 5 ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(building.name, style: const TextStyle(fontSize: 11, color: Colors.white)),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: Colors.yellow.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                child: Text('Lv.${building.level}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.yellow)),
              ),
              if (building.level < 5) ...[
                const SizedBox(width: 4),
                Icon(Icons.arrow_upward, size: 12, color: canUpgrade ? Colors.green : Colors.grey),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecruitButton extends StatelessWidget {
  final UnitType type;
  final Map<Resource, int> resources;
  final VoidCallback onTap;

  const _RecruitButton({required this.type, required this.resources, required this.onTap});

  bool get canAfford {
    for (final entry in type.cost.entries) {
      if ((resources[entry.key] ?? 0) < entry.value) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canAfford ? onTap : null,
      child: Opacity(
        opacity: canAfford ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: canAfford ? Border.all(color: Colors.blue.withOpacity(0.5)) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(type.displayName, style: const TextStyle(fontSize: 12, color: Colors.white)),
              const SizedBox(width: 6),
              Text('💰${type.cost[Resource.gold] ?? 0}', style: TextStyle(fontSize: 10, color: canAfford ? Colors.yellow : Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourcesRow extends StatelessWidget {
  final Map<Resource, int> resources;

  const _ResourcesRow({required this.resources});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final r in [Resource.gold, Resource.food, Resource.iron, Resource.wood])
            Column(
              children: [
                Text(r.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Text('${resources[r] ?? 0}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
        ],
      ),
    );
  }
}

class _ArmyInfoSection extends StatelessWidget {
  final Army army;

  const _ArmyInfoSection({required this.army});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: PageStorageKey('army_${army.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(army.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(army.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(
                      army.isMarching ? 'Marching • ${army.turnsUntilArrival} turns' : 'Stationed',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.people, color: Colors.blue, size: 24),
                      const SizedBox(height: 8),
                      Text('${army.unitCount}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Units', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                    ],
                  ),
                ),
                Container(width: 1, height: 60, color: Colors.white.withOpacity(0.1)),
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.flash_on, color: Colors.orange, size: 24),
                      const SizedBox(height: 8),
                      Text('${army.strength}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Strength', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app, size: 48, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('Select a village or army', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.4))),
        ],
      ),
    );
  }
}

class _ArmyCard extends StatelessWidget {
  final Army army;
  final VoidCallback onMarch;

  const _ArmyCard({required this.army, required this.onMarch});

  bool get hasLightCavalry => army.units.any((u) => u.unitType == UnitType.lightCavalry);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: army.foodDeprivedTurns > 0
            ? Colors.orange.withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: army.foodDeprivedTurns > 0
              ? Colors.orange.withOpacity(0.5)
              : Colors.white10,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent),
                ),
                child: Center(child: Text(army.emoji, style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(army.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('${army.unitCount} Units • ${army.strength} Power', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                  ],
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onMarch,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[800],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('March', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
          if (army.foodDeprivedTurns > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Starving (${army.foodDeprivedTurns} turns) • -20% Strength',
                    style: const TextStyle(fontSize: 10, color: Colors.orange),
                  ),
                ],
              ),
            ),
          ],
          if (hasLightCavalry) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.visibility, size: 12, color: Colors.green),
                  const SizedBox(width: 4),
                  const Text(
                    'Scout Range: +200km',
                    style: TextStyle(fontSize: 10, color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VictoryProgressBar extends StatelessWidget {
  final List<VictoryProgress> progress;
  final VictoryType? selectedType;

  const _VictoryProgressBar({required this.progress, this.selectedType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: progress.map((vp) {
          final isSelected = vp.type == selectedType;
          final color = _victoryColor(vp.type);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(vp.type.emoji, style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: vp.progress,
                          minHeight: isSelected ? 6 : 4,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          valueColor: AlwaysStoppedAnimation(
                            vp.achieved ? Colors.greenAccent : color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${(vp.progress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected ? color : Colors.white38,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _victoryColor(VictoryType type) => switch (type) {
        VictoryType.domination => Colors.redAccent,
        VictoryType.economic => Colors.amber,
        VictoryType.military => Colors.blueAccent,
        VictoryType.imperial => Colors.purpleAccent,
      };
}

class _ActiveEventsBar extends StatelessWidget {
  final List<GameEvent> events;

  const _ActiveEventsBar({required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: events.where((e) => e.isActive && e.duration > 0).map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.emoji, style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
                Text(
                  '${e.displayName} (${e.turnsRemaining})',
                  style: const TextStyle(fontSize: 9, color: Colors.amber),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
