import 'package:flutter/material.dart';
import '../../data/models/battle_plan.dart';
import '../../data/models/player_character.dart';
import '../../data/models/encounter.dart';
import '../../data/models/village.dart';
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
        ? game.map.villages.cast<Village?>().firstWhere(
            (v) => v!.id == destId,
            orElse: () => null,
          )
        : null;
    final origin = originId != null
        ? game.map.villages.cast<Village?>().firstWhere(
            (v) => v!.id == originId,
            orElse: () => null,
          )
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

  Widget _buildEncounterView(Encounter enc) {
    final color = switch (enc.type) {
      EncounterType.bandits => Colors.red,
      EncounterType.merchant => Colors.green,
      EncounterType.woundedSoldier => Colors.orange,
      EncounterType.nothing => Colors.white54,
    };

    final icon = switch (enc.type) {
      EncounterType.bandits => Icons.warning,
      EncounterType.merchant => Icons.storefront,
      EncounterType.woundedSoldier => Icons.personal_injury,
      EncounterType.nothing => Icons.landscape,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1A0A0A),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  enc.description,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action buttons based on encounter type
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (enc.type == EncounterType.bandits) ...[
                for (final plan in BattlePlan.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _actionButton(
                      '${plan.emoji} ${plan.displayName}',
                      Colors.red,
                      () {
                        final game = GameManager.shared;
                        final won = game.resolveEncounterBattle(enc, plan);
                        if (won) {
                          final loot = enc.goldReward ?? 0;
                          showToast('Victory! +${loot}g');
                        } else {
                          showToast('Defeated! Lost soldiers and gold.');
                        }
                        onDismissEncounter();
                      },
                    ),
                  ),
                _actionButton('Flee', Colors.grey, () {
                  final game = GameManager.shared;
                  game.fleeEncounter();
                  showToast('Fled! Lost cargo and 1 soldier.');
                }),
              ] else if (enc.type == EncounterType.merchant) ...[
                _actionButton('Trade', Colors.green, () {
                  if (enc.tradeGood != null && enc.goldReward != null) {
                    final game = GameManager.shared;
                    final pc = game.playerCharacter;
                    if (pc != null && pc.gold >= enc.goldReward!) {
                      pc.gold -= enc.goldReward!;
                      pc.addCargo(enc.tradeGood!, enc.tradeGoodAmount ?? 1);
                      showToast('Bought ${enc.tradeGoodAmount ?? 1} ${enc.tradeGood!.displayName}');
                    } else {
                      showToast('Not enough gold');
                    }
                  }
                  onDismissEncounter();
                }),
                const SizedBox(width: 8),
                _actionButton('Pass', Colors.grey, onDismissEncounter),
              ] else if (enc.type == EncounterType.woundedSoldier) ...[
                _actionButton('Recruit', Colors.orange, () {
                  final game = GameManager.shared;
                  if (game.recruitWoundedSoldier(enc)) {
                    showToast('${enc.recruitableUnit?.displayName ?? "Soldier"} joined your warband!');
                  } else {
                    showToast('Warband is full');
                  }
                  onDismissEncounter();
                }),
                const SizedBox(width: 8),
                _actionButton('Ignore', Colors.grey, onDismissEncounter),
              ] else ...[
                _actionButton('Continue', Colors.blue, onDismissEncounter),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
