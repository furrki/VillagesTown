import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/village.dart';
import '../../data/models/army.dart';
import '../../data/models/building.dart';
import '../../data/models/unit_type.dart';
import '../../data/models/resource.dart';
import '../../providers/game_provider.dart';
import '../components/owner_flag_view.dart';

class InlineVillagePanel extends StatelessWidget {
  final Village village;
  final void Function(Building) onBuild;
  final void Function(Building) onUpgrade;
  final void Function(UnitType) onRecruit;
  final VoidCallback onSendArmy;
  final VoidCallback onEndTurn;
  final bool isProcessingTurn;
  final void Function(String) showToast;

  const InlineVillagePanel({
    super.key,
    required this.village,
    required this.onBuild,
    required this.onUpgrade,
    required this.onRecruit,
    required this.onSendArmy,
    required this.onEndTurn,
    required this.isProcessingTurn,
    required this.showToast,
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

  String get ownerLabel {
    switch (village.owner) {
      case 'neutral':
        return 'Neutral';
      case 'ai1':
      case 'ai2':
        return 'Enemy';
      default:
        return village.owner;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final game = provider.gameManager;
        final resources = game.getGlobalResources('player');
        final armies = game.getArmiesAt(village.id);
        final playerArmy = armies.where((a) => a.owner == 'player' && !a.isMarching).isNotEmpty
            ? armies.firstWhere((a) => a.owner == 'player' && !a.isMarching)
            : null;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(playerArmy),
                const SizedBox(height: 16),
                if (isPlayerVillage) ...[
                  _buildStatsRow(),
                  const SizedBox(height: 16),
                  if (playerArmy != null) ...[
                    _buildArmySection(playerArmy),
                    const SizedBox(height: 16),
                  ],
                  if (village.buildings.length < village.maxBuildings) ...[
                    _buildQuickBuildSection(resources),
                    const SizedBox(height: 16),
                  ],
                  if (village.buildings.isNotEmpty) ...[
                    _buildExistingBuildingsSection(resources),
                    const SizedBox(height: 16),
                  ],
                  if (availableUnits.isNotEmpty)
                    _buildQuickRecruitSection(resources)
                  else
                    _buildNoMilitaryHint(),
                ] else
                  _buildEnemySection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Army? playerArmy) {
    return Row(
      children: [
        OwnerFlagView(owner: village.owner, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                village.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 3),
              Text(
                isPlayerVillage ? 'Level ${village.level.index + 1}' : ownerLabel,
                style: TextStyle(fontSize: 13, color: isPlayerVillage ? Colors.green : Colors.red),
              ),
            ],
          ),
        ),
        _buildEndTurnButton(),
      ],
    );
  }

  Widget _buildEndTurnButton() {
    return GestureDetector(
      onTap: isProcessingTurn ? null : onEndTurn,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isProcessingTurn)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            else
              const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            const Text('End Turn', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _statCell(Icons.people, '${village.population}', 'Population', Colors.blue),
          Container(width: 1, height: 44, color: Colors.white.withOpacity(0.1)),
          _statCell(Icons.shield, '${village.garrisonStrength}', 'Defense', Colors.green),
          Container(width: 1, height: 44, color: Colors.white.withOpacity(0.1)),
          _statCell(Icons.apartment, '${village.buildings.length}/${village.maxBuildings}', 'Buildings', Colors.orange),
        ],
      ),
    );
  }

  Widget _statCell(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildArmySection(Army army) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(army.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(army.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 3),
                Text(
                  '${army.unitCount} units • ${army.strength} STR',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onSendArmy,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.send, size: 14, color: Colors.white),
                  SizedBox(width: 5),
                  Text('Send', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBuildSection(Map<Resource, int> resources) {
    final buildings = availableBuildings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('BUILD NEW (${buildings.length} available)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5))),
        const SizedBox(height: 8),
        if (buildings.isEmpty)
          Text('No buildings available', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: buildings.take(8).map((b) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _InlineBuildButton(building: b, resources: resources, onBuild: () => onBuild(b)),
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildExistingBuildingsSection(Map<Resource, int> resources) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('UPGRADE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5))),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: village.buildings.map((b) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _InlineUpgradeButton(building: b, resources: resources, onUpgrade: () => onUpgrade(b)),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickRecruitSection(Map<Resource, int> resources) {
    final units = availableUnits;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECRUIT UNITS (${units.length} types)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5))),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: units.map((t) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _InlineRecruitButton(type: t, resources: resources, onRecruit: () => onRecruit(t)),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNoMilitaryHint() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, size: 18, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Build Barracks, Archery Range, or Stables to recruit units',
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnemySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield, size: 24, color: Colors.red),
              const SizedBox(width: 10),
              Text(
                'Garrison Strength: ${village.garrisonStrength}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Send an army to conquer this village',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}

class _InlineBuildButton extends StatelessWidget {
  final Building building;
  final Map<Resource, int> resources;
  final VoidCallback onBuild;

  const _InlineBuildButton({required this.building, required this.resources, required this.onBuild});

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
      case 'Temple': return '⛪';
      case 'Library': return '📚';
      default: return '🏠';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = building.name.length > 8 ? '${building.name.substring(0, 8)}..' : building.name;
    return GestureDetector(
      onTap: canAfford ? onBuild : null,
      child: Opacity(
        opacity: canAfford ? 1 : 0.5,
        child: Container(
          width: 76,
          height: 82,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(canAfford ? 0.1 : 0.04),
            borderRadius: BorderRadius.circular(12),
            border: canAfford ? Border.all(color: Colors.green.withOpacity(0.5), width: 2) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 4),
              Text(name, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8))),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💰', style: TextStyle(fontSize: 9)),
                  const SizedBox(width: 2),
                  Text(
                    '${building.baseCost[Resource.gold] ?? 0}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: canAfford ? Colors.yellow : Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineUpgradeButton extends StatelessWidget {
  final Building building;
  final Map<Resource, int> resources;
  final VoidCallback onUpgrade;

  const _InlineUpgradeButton({required this.building, required this.resources, required this.onUpgrade});

  Map<Resource, int> get upgradeCost {
    final multiplier = building.level + 1;
    return building.baseCost.map((k, v) => MapEntry(k, (v * multiplier * 0.8).round()));
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
      case 'Temple': return '⛪';
      case 'Library': return '📚';
      default: return '🏠';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = building.name.length > 8 ? '${building.name.substring(0, 8)}..' : building.name;
    return GestureDetector(
      onTap: canUpgrade ? onUpgrade : null,
      child: Opacity(
        opacity: canUpgrade || building.level >= 5 ? 1 : 0.5,
        child: Container(
          width: 76,
          height: 82,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(canUpgrade ? 0.1 : 0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 24)),
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.yellow),
                      child: Text('${building.level}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(name, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8))),
              if (building.level < 5)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_circle_up, size: 11, color: canUpgrade ? Colors.green : Colors.grey),
                    const SizedBox(width: 2),
                    Text('Lv.${building.level + 1}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: canUpgrade ? Colors.green : Colors.grey)),
                  ],
                )
              else
                const Text('MAX', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineRecruitButton extends StatelessWidget {
  final UnitType type;
  final Map<Resource, int> resources;
  final VoidCallback onRecruit;

  const _InlineRecruitButton({required this.type, required this.resources, required this.onRecruit});

  bool get canAfford {
    for (final entry in type.cost.entries) {
      if ((resources[entry.key] ?? 0) < entry.value) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final name = type.name.length > 8 ? '${type.name.substring(0, 8)}..' : type.name;
    return GestureDetector(
      onTap: canAfford ? onRecruit : null,
      child: Opacity(
        opacity: canAfford ? 1 : 0.5,
        child: Container(
          width: 76,
          height: 82,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(canAfford ? 0.1 : 0.04),
            borderRadius: BorderRadius.circular(12),
            border: canAfford ? Border.all(color: Colors.blue.withOpacity(0.5), width: 2) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 4),
              Text(name, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8))),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💰', style: TextStyle(fontSize: 9)),
                  const SizedBox(width: 2),
                  Text(
                    '${type.cost[Resource.gold] ?? 0}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: canAfford ? Colors.yellow : Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
