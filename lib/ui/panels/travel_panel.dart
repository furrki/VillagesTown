import 'package:flutter/material.dart';
import '../../data/models/battle_plan.dart';
import '../../data/models/mission.dart';
import '../../data/models/player_character.dart';
import '../../data/models/encounter.dart';
import '../../engines/game_manager.dart';
import '../components/countryball_avatar.dart';

class TravelPanel extends StatelessWidget {
  final PlayerCharacter player;
  final Encounter? encounter;
  final VoidCallback onDismissEncounter;
  final void Function(String message) showToast;

  const TravelPanel({
    super.key,
    required this.player,
    this.encounter,
    required this.onDismissEncounter,
    required this.showToast,
  });

  @override
  Widget build(BuildContext context) {
    final game = GameManager.shared;

    if (encounter != null) {
      return _buildEncounterView(encounter!);
    }

    return _buildTravelProgress(game);
  }

  Widget _buildTravelProgress(GameManager game) {
    final destId = player.travelDestinationId;
    final originId = player.travelOriginId;

    final dest = destId != null
        ? game.getVillageById(destId)
        : null;
    final origin = originId != null
        ? game.getVillageById(originId)
        : null;

    final destName = dest != null ? game.getVillageDisplayName(dest) : '???';
    final originName = origin != null ? game.getVillageDisplayName(origin) : '???';
    final ticksLeft = ((1.0 - player.travelProgress) * player.travelTotalTicks).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF141414),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route header
          Row(
            children: [
              CountryballAvatar.player(size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$originName  \u2192  $destName',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${ticksLeft}s left',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: player.travelProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 6,
            ),
          ),
          // Active mission tracker
          if (player.activeMissions.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildMissionTracker(player.activeMissions.first, game),
          ],
          const SizedBox(height: 10),
          // Cargo summary
          Row(
            children: [
              Text(
                '\u{1F4E6} Cargo: ${player.currentCargoCount}/${player.totalCargoCapacity}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const Spacer(),
              Text(
                '\u{1FA99} ${player.gold} gold',
                style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionTracker(Mission mission, GameManager game) {
    final nextObj = mission.objectives
        .where((o) => !o.completed)
        .firstOrNull;
    if (nextObj == null) return const SizedBox.shrink();

    String label = nextObj.description;
    if (nextObj.type == ObjectiveType.travelTo && nextObj.targetCityId != null) {
      final city = game.getVillageById(nextObj.targetCityId);
      if (city != null) label = 'Go to ${game.getVillageDisplayName(city)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_stories, color: Colors.amber, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${mission.title}: $label',
              style: const TextStyle(color: Colors.amber, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncounterView(Encounter enc) {
    final game = GameManager.shared;
    final pc = game.playerCharacter;
    final skills = <String, int>{
      'combat': pc?.combatSkill ?? 1,
      'leadership': pc?.leadershipSkill ?? 1,
      'tactics': pc?.tacticsSkill ?? 1,
      'trade': pc?.tradeSkill ?? 1,
      'scouting': pc?.scoutingSkill ?? 1,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1A0A0A),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Narrative text
            Text(
              enc.narrative,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            // Choice buttons
            if (enc.choices.isNotEmpty)
              ...enc.choices.map((choice) {
                final available = choice.isAvailable(skills);
                final isFight = choice.outcome == EncounterChoiceOutcome.fight;
                final color = switch (choice.outcome) {
                  EncounterChoiceOutcome.fight => Colors.red,
                  EncounterChoiceOutcome.flee => Colors.grey,
                  EncounterChoiceOutcome.payGold || EncounterChoiceOutcome.loseGold => Colors.amber,
                  EncounterChoiceOutcome.gainCargo || EncounterChoiceOutcome.gainGold => Colors.green,
                  EncounterChoiceOutcome.recruitUnit => Colors.cyan,
                  EncounterChoiceOutcome.loseCargo => Colors.orange,
                  _ => Colors.white70,
                };
                final skillTag = choice.skillRequired != null
                    ? ' [${choice.skillRequired} ${choice.skillLevel}+]'
                    : '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _choiceButton(
                    '${choice.label}$skillTag',
                    color,
                    available
                        ? () {
                            if (isFight) {
                              _showBattlePlanPicker(enc);
                            } else {
                              final result = game.resolveEncounterChoice(enc, choice);
                              if (result != null) {
                                showToast(result);
                              } else {
                                showToast('Cannot do that right now');
                              }
                              onDismissEncounter();
                            }
                          }
                        : null,
                  ),
                );
              })
            else ...[
              // Fallback for encounters without choices
              _choiceButton('Continue', Colors.blue, onDismissEncounter),
            ],
          ],
        ),
      ),
    );
  }

  void _showBattlePlanPicker(Encounter enc) {
    showToast('Choose your battle plan');
    // For now, use aggressive plan directly. Could be expanded to a picker.
    final game = GameManager.shared;
    final won = game.resolveEncounterBattle(enc, BattlePlan.aggressive);
    if (won) {
      final loot = enc.goldReward ?? 0;
      showToast('Victory! +${loot}g');
    } else {
      showToast('Defeated! Lost soldiers and gold.');
    }
    onDismissEncounter();
  }

  Widget _choiceButton(String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: onTap != null
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap != null
                ? color.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: onTap != null ? color : Colors.white24,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
