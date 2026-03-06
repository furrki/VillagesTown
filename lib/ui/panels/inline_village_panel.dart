import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/village.dart';
import '../../data/models/army.dart';
import '../../data/models/building.dart';
import '../../data/models/unit_type.dart';
import '../../data/models/resource.dart';
import '../../data/models/unit.dart';
import '../../data/models/game_event.dart';
import '../../data/models/victory_condition.dart';
import '../../data/models/village_trait.dart';
import '../../providers/game_provider.dart';
import '../components/owner_flag_view.dart';
import '../components/tutorial_highlighter.dart';
import '../components/defender_strength_bar.dart';
import '../../engines/tutorial_helper.dart';
import '../../engines/game_manager.dart';
import '../../engines/victory_engine.dart';


class InlineVillagePanel extends StatelessWidget {
  final Village village;
  final void Function(Building) onBuild;
  final void Function(Building) onUpgrade;
  final void Function(UnitType) onRecruit;
  final void Function(Army) onSelectArmy;
  final VoidCallback onEndTurn;
  final bool isProcessingTurn;
  final void Function(String) showToast;

  const InlineVillagePanel({
    super.key,
    required this.village,
    required this.onBuild,
    required this.onUpgrade,
    required this.onRecruit,
    required this.onSelectArmy,
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
        // Get ALL stationed armies (Groups)
        final stationedArmies = armies.where((a) => a.owner == 'player' && !a.isMarching).toList();
        
        final tutorialAction = TutorialHelper.getNextAction(village);
        // Check "End Turn" condition: If we are broke
        final gold = resources[Resource.gold] ?? 0;
        // Simple heuristic for "out of resources": cant afford basic recruitment (approx 50 gold)
        final shouldEndTurn = tutorialAction == TutorialAction.recruit && gold < 50;
        
        // Pass primary army to header for stats if needed, or first
        final primaryArmy = stationedArmies.isNotEmpty ? stationedArmies.first : null;

        return SingleChildScrollView(
          key: PageStorageKey('inline_village_${village.id}'),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Victory Progress + Active Events
              _buildVictoryProgress(game),
              if (game.activeEvents.any((e) => e.isActive && e.duration > 0))
                _buildActiveEvents(game.activeEvents),
              const SizedBox(height: 8),

              // Header
              _buildHeader(game, primaryArmy, shouldEndTurn),
              const SizedBox(height: 12),

              // Siege Alert (if under siege)
              _buildSiegeAlert(game),

              // Content
              if (isPlayerVillage) ...[
                // 1. Village Architecture (Radial Control Pad + Army)
                _buildRadialVillage(resources, tutorialAction, shouldEndTurn),

                const SizedBox(height: 12),

                // 2. WAR ROOM (Stack Management)
                _buildWarRoom(context, stationedArmies, provider),
              ] else
                _buildEnemySection(),
            ],
          ),
        );

      },
    );
  }

  Widget _buildActiveEvents(List<GameEvent> events) {
    final active = events.where((e) => e.isActive && e.duration > 0).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: active.map((e) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${e.emoji} ${e.turnsRemaining}',
            style: const TextStyle(fontSize: 10, color: Colors.amber),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildVictoryProgress(GameManager game) {
    final progress = VictoryEngine.getAllProgress(game, 'player');
    final selected = game.selectedVictoryType;
    return Row(
      children: progress.map((vp) {
        final isSelected = vp.type == selected;
        final color = switch (vp.type) {
          VictoryType.domination => Colors.redAccent,
          VictoryType.economic => Colors.amber,
          VictoryType.military => Colors.blueAccent,
          VictoryType.imperial => Colors.purpleAccent,
        };
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                Text(vp.type.emoji, style: const TextStyle(fontSize: 10)),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: vp.progress,
                    minHeight: isSelected ? 4 : 3,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(
                      vp.achieved ? Colors.greenAccent : color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeader(GameManager game, Army? playerArmy, bool shouldEndTurn) {
    // Calculate army strength (stationed units that belong to the village owner)
    final stationedArmies = game.getArmiesAt(village.id).where((a) => a.owner == village.owner && !a.isMarching);
    final armyStrength = stationedArmies.fold(0, (sum, a) => sum + a.unitCount);

    return Row(
      children: [
        OwnerFlagView(owner: village.owner, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                game.getVillageDisplayName(village),
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
                  Flexible(
                    child: Text(
                      '👥 ${village.population}   🏠 ${village.buildings.length}/${village.maxBuildings}',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (village.trait != VillageTrait.none || village.specialization != VillageSpecialization.none)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (village.trait != VillageTrait.none)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.brown.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.brown.withValues(alpha: 0.5), width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(village.trait.emoji, style: const TextStyle(fontSize: 9)),
                              const SizedBox(width: 2),
                              Text(village.trait.displayName, style: const TextStyle(fontSize: 9, color: Colors.white70)),
                            ],
                          ),
                        ),
                      if (village.specialization != VillageSpecialization.none)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.purple.withValues(alpha: 0.5), width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(village.specialization.emoji, style: const TextStyle(fontSize: 9)),
                              const SizedBox(width: 2),
                              Text(village.specialization.displayName, style: const TextStyle(fontSize: 9, color: Colors.white70)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              DefenderStrengthBar(
                garrisonStrength: village.garrisonStrength,
                armyStrength: armyStrength,
                height: 6,
                showLegend: true,
              ),
            ],
          ),
        ),
        _buildEndTurnButton(shouldEndTurn),
      ],
    );
  }

  Widget _buildEndTurnButton(bool highlight) {
     return TutorialHighlighter(
       isActive: highlight,
       color: Colors.blueAccent,
       child: GestureDetector(
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
    ),
   );
  }

  Widget _buildSiegeAlert(GameManager game) {
    final besiegers = game.getBesiegingArmiesAt(village.id);
    if (besiegers.isEmpty) return const SizedBox.shrink();

    final totalEnemyUnits = besiegers.fold(0, (sum, a) => sum + a.unitCount);
    final turnsUntilAssault = besiegers.first.siegeTurns >= 1 ? 0 : 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Expanded(
                child: Text(
                  'UNDER SIEGE!',
                  style: const TextStyle(
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
                  final result = game.sallyOut(village.id);
                  if (result != null) {
                    showToast('Garrison sallied out!');
                  }
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

  Widget _buildRadialVillage(Map<Resource, int> resources, TutorialAction tutorialAction, bool shouldEndTurn) {
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
         _buildRadialContainer(containerSize, center, radius, tileSize, tileOffset, resources, allBuildings, tutorialAction),
         
         // 2. SIDE RECRUITMENT PANEL
         _buildSideRecruitmentPanel(resources, tileSize, tutorialAction, shouldEndTurn),
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
    TutorialAction tutorialAction,
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
             final existing = village.buildings.where((b) => b.name == template.name).firstOrNull;
              
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

             bool isTutorialTarget = false;
             if (template.name == 'Market' && tutorialAction == TutorialAction.buildMarket) isTutorialTarget = true;
             if (template.name == 'Farm' && tutorialAction == TutorialAction.buildFarm) isTutorialTarget = true;

             return Positioned(
               left: dx,
               top: dy,
               child: TutorialHighlighter(
                 isActive: isTutorialTarget,
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
                        if (isTutorialTarget) {
                           if (template.name == 'Market') GameManager.shared.completeTutorialAction(TutorialAction.buildMarket.name);
                           if (template.name == 'Farm') GameManager.shared.completeTutorialAction(TutorialAction.buildFarm.name);
                        }
                      } else {
                        onUpgrade(existing);
                      }
                    },
                 ),
               ),
             );
          }),
        ],
      ),
    );
  }

  Widget _buildSideRecruitmentPanel(Map<Resource, int> resources, double tileSize, TutorialAction tutorialAction, bool shouldEndTurn) {
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
     
     final isRecruitStep = tutorialAction == TutorialAction.recruit && !shouldEndTurn;

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
                 
                 // Highlight basic units first if we are in recruit step
                 final isHighlight = isRecruitStep && canAfford && (type == UnitType.militia || type == UnitType.spearman); // Prioritize cheap units

                 return TutorialHighlighter(
                   isActive: isHighlight,
                   color: Colors.redAccent,
                   child: _GameActionTile(
                     icon: type.emoji,
                     label: '', // No labels
                     isEnabled: canAfford,
                     accentColor: Colors.redAccent,
                     isCircular: true,
                     size: tileSize, // Matches building size
                     onTap: () {
                       onRecruit(type);
                       if (isHighlight) {
                         GameManager.shared.completeTutorialAction(TutorialAction.recruit.name);
                       }
                     },
                   ),
                 );
              }).toList(),
            ),
         ],
       ),
    );
  }

  Widget _buildWarRoom(BuildContext context, List<Army> armies, GameProvider provider) {
     return Container(
       padding: const EdgeInsets.all(10),
       decoration: BoxDecoration(
         color: const Color(0xFF1E1E1E),
         borderRadius: BorderRadius.circular(16),
         border: Border.all(color: Colors.white10),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
             children: [
               const Text('COMMAND CENTER', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
               const Spacer(),
               // Button to merge all? Maybe later.
             ],
           ),
           
           const SizedBox(height: 8),

           if (armies.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No troops stationed here.\nRecruit units from the side panel.', 
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                    textAlign: TextAlign.center,
                  )
                ),
              ),

           ...armies.map((army) => Padding(
             padding: const EdgeInsets.only(bottom: 4.0),
             child: _ArmyStackCard(
               army: army,
               onMarch: () => onSelectArmy(army),
               onMuster: () => _showMusterDialog(context, army, provider),
             ),
           )),
         ],
       ),
     );
  }

  void _showMusterDialog(BuildContext context, Army army, GameProvider provider) {
      showDialog(
        context: context, 
        builder: (ctx) => _MusterDialog(army: army, provider: provider)
      );
  }

  Widget _buildEnemySection() {
    final game = GameManager.shared;
    final stationedArmies = game.getArmiesAt(village.id).where((a) => a.owner == village.owner && !a.isMarching);
    final armyStrength = stationedArmies.fold(0, (sum, a) => sum + a.unitCount);

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
                'Defenders: ${village.garrisonStrength + armyStrength}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DefenderStrengthBar(
            garrisonStrength: village.garrisonStrength,
            armyStrength: armyStrength,
            height: 10,
            showLegend: true,
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
} // End InlineVillagePanel



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

class _ArmyStackCard extends StatelessWidget {
  final Army army;
  final VoidCallback onMarch;
  final VoidCallback onMuster;

  const _ArmyStackCard({required this.army, required this.onMarch, required this.onMuster});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Icon Stack
          Container(
             width: 32, height: 32,
             decoration: BoxDecoration(
               color: Colors.blue.withValues(alpha: 0.2),
               shape: BoxShape.circle,
               border: Border.all(color: Colors.blueAccent),
             ),
             child: Center(child: Text(army.emoji, style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 8),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(army.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${army.unitCount} Units • ${army.strength} Power', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
              ],
            ),
          ),
          // Actions
          IconButton(
            icon: const Icon(Icons.call_split_rounded, color: Colors.white70, size: 18),
            tooltip: 'Muster / Split',
            constraints: const BoxConstraints(), 
            padding: const EdgeInsets.all(4),
            onPressed: onMuster,
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onMarch,
            style: ElevatedButton.styleFrom(
               backgroundColor: Colors.blue[800],
               foregroundColor: Colors.white,
               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
               minimumSize: const Size(0, 28),
               textStyle: const TextStyle(fontSize: 11),
            ),
            child: const Text('March'),
          ),
        ],
      ),
    );
  }
}

class _MusterDialog extends StatefulWidget {
  final Army army;
  final GameProvider provider;

  const _MusterDialog({required this.army, required this.provider});

  @override
  State<_MusterDialog> createState() => _MusterDialogState();
}

class _MusterDialogState extends State<_MusterDialog> {
  // Track selection: Unit -> Count
  final Map<Unit, bool> _selection = {};

  @override
  void initState() {
    super.initState();
    for (var u in widget.army.units) {
      _selection[u] = false;
    }
  }

  void _submit() {
    final selectedUnits = widget.army.units.where((u) => _selection[u] == true).toList();
    if (selectedUnits.isEmpty) return;
    
    // Logic: Remove from current army, create new army.
    final game = widget.provider.gameManager;
    final remainingUnits = widget.army.units.where((u) => _selection[u] == false).toList();
    
    if (remainingUnits.isEmpty) {
       // Moving ALL units? Just keep the army.
       Navigator.of(context).pop();
       return; 
    }

    // 1. Update current army (remove units)
    // Use removeWhere on the passed reference (assuming it's mutable in memory)
    // Ideally we should use a proper manager method, but mutation works if object is shared
    widget.army.units.removeWhere((u) => selectedUnits.contains(u));
    game.updateArmy(widget.army); // Notify changes
    
    // 2. Create new army
    game.createArmy(selectedUnits, widget.army.stationedAt!, widget.army.owner);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final units = widget.army.units;
    
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Muster Field Army', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Select units to split into a new group:', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 16),
            
            // List of units
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  children: units.map((u) {
                    final isSelected = _selection[u] ?? false;
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() => _selection[u] = val ?? false);
                      },
                      title: Text(u.unitType.displayName, style: const TextStyle(color: Colors.white)),
                      secondary: Text(u.unitType.emoji, style: const TextStyle(fontSize: 20)),
                      activeColor: Colors.blue,
                      checkColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), 
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Form Army', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
