import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/village.dart';
import '../../data/models/army.dart';
import '../../data/models/building.dart';
import '../../data/models/unit_type.dart';
import '../../data/models/resource.dart';
import '../../providers/game_provider.dart';
import '../components/owner_flag_view.dart';
import '../map/army_visual_marker.dart';

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

        return Column(
          children: [
            // Fixed Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: _buildHeader(playerArmy),
            ),
            const SizedBox(height: 12),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                key: PageStorageKey('inline_village_${village.id}'),
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isPlayerVillage) ...[
                      // 1. Village Architecture (Radial Control Pad + Army)
                      _buildRadialVillage(resources),
                      
                      const SizedBox(height: 12),
                      
                      // Stationed Army (if present)
                      if (playerArmy != null)
                        _buildArmySection(playerArmy),

                    ] else
                      _buildEnemySection(), 
                  ],
                ),
              ),
            ),
          ],
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
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    isPlayerVillage ? 'Level ${village.level.index + 1}' : ownerLabel,
                    style: TextStyle(fontSize: 11, color: isPlayerVillage ? Colors.green : Colors.red),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '👥 ${village.population}   🛡️ ${village.garrisonStrength}   🏠 ${village.buildings.length}/${village.maxBuildings}',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ],
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
          boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2))],
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

  Widget _buildRadialVillage(Map<Resource, int> resources) {
    // Get ALL buildings 
    final allBuildings = Building.all;

    // Fixed Compact Radial - SHRUNK to fit side-by-side on mobile
    const double containerSize = 220; // Reduced from 280
    const double center = containerSize / 2;
    const double radius = 68; // Reduced from 85
    const double tileSize = 42; // Reduced from 46
    const double tileOffset = tileSize / 2;

    // Always use Side Panel layout now that it fits (220 + 130 = 350 < 374)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         // 1. RADIAL VILLAGE VIEW
         _buildRadialContainer(containerSize, center, radius, tileSize, tileOffset, resources, allBuildings),
         
         // 2. SIDE RECRUITMENT PANEL
         _buildSideRecruitmentPanel(resources, tileSize),
      ],
    );
  }

  Widget _buildRadialContainer(
    double containerSize,
    double center,
    double radius,
    double tileSize,
    double tileOffset,
    Map<Resource, int> resources,
    List<Building> allBuildings,
  ) {
    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.5), 
        borderRadius: BorderRadius.circular(containerSize / 2),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // CENTER HUB - Slightly smaller
          Positioned(
            left: center - 30, // 60px size
            top: center - 30, 
            child: Container(
              width: 60, 
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade900,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5), width: 2),
                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance, color: Colors.white, size: 20),
                  const SizedBox(height: 2),
                  Text('${village.population}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ],
              ),
            ),
          ),

          // SATELLITES
          ...List.generate(allBuildings.length, (index) {
             final angle = (2 * math.pi * index / allBuildings.length) - (math.pi / 2);
             
             final dx = center + radius * math.cos(angle) - tileOffset;
             final dy = center + radius * math.sin(angle) - tileOffset;

             final template = allBuildings[index];
             final existing = village.buildings.cast<Building?>().firstWhere(
                    (b) => b!.name == template.name,
                    orElse: () => null,
                  );
              
              final isBuilt = existing != null;
              final level = existing?.level ?? 0;
              final isMax = level >= 5;
              
              bool canAfford = false;
               if (isBuilt) {
                if (level < 5) {
                   final multiplier = level + 1;
                   final upgradeCost = template.baseCost.map((k, v) => MapEntry(k, (v * multiplier * 0.8).round()));
                   canAfford = true;
                   for (final entry in upgradeCost.entries) {
                    if ((resources[entry.key] ?? 0) < entry.value) canAfford = false;
                  }
                }
              } else {
                canAfford = true;
                for (final entry in template.baseCost.entries) {
                  if ((resources[entry.key] ?? 0) < entry.value) canAfford = false;
                }
              }

              String icon = '🏠';
              switch (template.name) {
                case 'Farm': icon = '🌾'; break;
                case 'Lumber Mill': icon = '🪵'; break;
                case 'Iron Mine': icon = '⛏️'; break;
                case 'Market': icon = '🏪'; break;
                case 'Barracks': icon = '⚔️'; break;
                case 'Archery Range': icon = '🏹'; break;
                case 'Stables': icon = '🐴'; break;
                case 'Fortress': icon = '🏰'; break;
              }

             return Positioned(
               left: dx,
               top: dy,
               child: _GameActionTile(
                 icon: icon,
                 label: template.name,
                 badgeLabel: isBuilt ? '$level' : null,
                 badgeColor: isMax ? Colors.orange : Colors.blue,
                 isEnabled: canAfford || isBuilt,
                 isHighlight: isBuilt,
                 accentColor: Colors.blue,
                 isCircular: true, 
                 size: tileSize,
                 onTap: () {
                    if (existing == null) {
                      onBuild(template);
                    } else {
                      onUpgrade(existing);
                    }
                  },
               ),
             );
          }),
        ],
      ),
    );
  }

  Widget _buildSideRecruitmentPanel(Map<Resource, int> resources, double tileSize) {
     final availableUnits = <UnitType>{};
     for (final b in village.buildings) {
       if (b.name == 'Barracks') {
         availableUnits.add(UnitType.militia);
         availableUnits.add(UnitType.swordsman);
          availableUnits.add(UnitType.spearman);
       } else if (b.name == 'Archery Range') {
         availableUnits.add(UnitType.archer);
         availableUnits.add(UnitType.crossbowman);
       } else if (b.name == 'Stables') {
         availableUnits.add(UnitType.lightCavalry);
         availableUnits.add(UnitType.knight);
       }
     }

     if (availableUnits.isEmpty) return const SizedBox.shrink();

     // Calculate width for 2 columns: (tileSize * 2) + spacing + padding + safety
     // 42 * 2 = 84. Spacing 8. Total content 92. 
     // Padding 8*2 = 16. Total required = 108.
     // Giving extra breathing room to ensure it never wraps to 1 column.
     const double panelWidth = 124; 

     return Container(
       width: panelWidth, 
       margin: const EdgeInsets.only(left: 12),
       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
       decoration: BoxDecoration(
         color: Colors.black.withValues(alpha: 0.3),
         borderRadius: BorderRadius.circular(24),
         border: Border.all(color: Colors.white10),
       ),
       child: Column(
         mainAxisSize: MainAxisSize.min,
         children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: availableUnits.map((type) {
                 bool canAfford = true;
                 for (final entry in type.cost.entries) {
                   if ((resources[entry.key] ?? 0) < entry.value) canAfford = false;
                 }
                 
                 return _GameActionTile(
                   icon: type.emoji,
                   label: '', // No labels
                   isEnabled: canAfford,
                   accentColor: Colors.redAccent,
                   isCircular: true,
                   size: tileSize, // Matches building size
                   onTap: () => onRecruit(type),
                 );
              }).toList(),
            ),
         ],
       ),
    );
  }

  Widget _buildArmySection(Army army) {
     return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Use the refined visual marker
          ArmyVisualMarker(army: army, isSelected: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(army.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('${army.strength} Power • ${army.unitCount} Units', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          ),
          IconButton(
            onPressed: onSendArmy,
            icon: const Icon(Icons.send_rounded, color: Colors.orange),
            tooltip: 'Send Army',
          ),
        ],
      ),
    );
  }

  Widget _buildEnemySection() {
      return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
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
            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

class _GameActionTile extends StatelessWidget {
  final String icon;
  final String label;
  final String? badgeLabel;
  final Color? badgeColor;
  final bool isEnabled;
  final bool isHighlight; // e.g. Built or Affordable
  final Color accentColor;
  final VoidCallback? onTap;

  final bool isCircular;
  final double size;

  const _GameActionTile({
    required this.icon,
    required this.label,
    this.badgeLabel,
    this.badgeColor,
    this.isEnabled = true,
    this.isHighlight = false,
    required this.accentColor,
    this.onTap,
    this.isCircular = false,
    this.size = 64, // Default size
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: MouseRegion(
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isHighlight ? const Color(0xFF222222) : Colors.transparent,
            shape: isCircular ? BoxShape.circle : BoxShape.rectangle, // Circular shape support
            borderRadius: isCircular ? null : BorderRadius.circular(8),
            border: Border.all(
              color: isHighlight ? Colors.white.withValues(alpha: 0.1) : (isEnabled ? accentColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
              width: 1,
            ),
             // Subtle Highlight Gradient
            gradient: isHighlight ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2A2A2A),
                const Color(0xFF1A1A1A),
              ],
            ) : (isEnabled && !isHighlight ? LinearGradient( // Subtle tint for affordable items
               begin: Alignment.topLeft,
               end: Alignment.bottomCenter,
               colors: [accentColor.withValues(alpha: 0.1), Colors.transparent],
            ) : null),
          ),
          child: Stack(
            children: [
              // 1. Central Icon
              Center(
                 child: Opacity(
                   opacity: isEnabled || isHighlight ? 1.0 : 0.4,
                   child: Text(icon, style: TextStyle(fontSize: size * 0.4)), // Scaled font
                 ),
              ),

              // 2. Name Overlay (Bottom) - Only if square and larger? Or just minimalist label for circular
              if (!isCircular && label.isNotEmpty)
              Positioned(
                bottom: 0, 
                left: 0, 
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                      color: isHighlight ? Colors.white : Colors.white.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // 3. Badge (Level or Count)
              if (badgeLabel != null)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: badgeColor ?? Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1E1E1E), width: 1.5),
                    ),
                     child: Text(
                      badgeLabel!,
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
