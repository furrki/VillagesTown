import 'package:flutter/material.dart';
import '../../data/models/mission.dart';
import '../../data/models/player_character.dart';
import '../../data/models/resource.dart';
import '../../data/models/village.dart';
import '../../engines/game_manager.dart';
import '../../engines/narrative_engine.dart';
import '../../engines/recruitment_engine.dart';
import '../../engines/trade_engine.dart';
import '../components/countryball_avatar.dart';

class CityScreen extends StatefulWidget {
  final Village city;
  final PlayerCharacter player;
  final VoidCallback onLeave;
  final void Function(String message) showToast;

  const CityScreen({
    super.key,
    required this.city,
    required this.player,
    required this.onLeave,
    required this.showToast,
  });

  @override
  State<CityScreen> createState() => _CityScreenState();
}

class _CityScreenState extends State<CityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _arrivalNarrative;

  static const _cardColor = Color(0xFF1A1A1A);
  static const _cardAltColor = Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();
    _arrivalNarrative = NarrativeEngine.cityArrival(
      widget.city,
      GameManager.shared,
    );
    // Start on Tavern tab if player has active missions (e.g., first visit)
    final hasActiveMission = widget.player.activeMissions.isNotEmpty;
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: hasActiveMission ? 2 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = GameManager.shared;
    final cityName = game.getVillageDisplayName(widget.city);
    final ownerNat = game.getNationality(widget.city.owner);

    return Column(
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: _cardColor,
              child: Row(
                children: [
                  CountryballAvatar(
                    size: 36,
                    owner: widget.city.owner,
                    nationality: ownerNat,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cityName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.city.trait.emoji} ${widget.city.trait.displayName}'
                          '  |  Pop: ${widget.city.population}'
                          '  |  Garrison: ${widget.city.garrisonStrength}/${widget.city.garrisonMaxStrength}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: widget.onLeave,
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Leave City'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.25),
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            // Arrival narrative
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF111118),
              child: Text(
                _arrivalNarrative,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
            // Tabs
            Container(
              color: _cardColor,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.amber,
                labelColor: Colors.amber,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Trade'),
                  Tab(text: 'Recruit'),
                  Tab(text: 'Tavern'),
                  Tab(text: 'Warband'),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTradeTab(),
                  _buildRecruitTab(),
                  _buildTavernTab(),
                  _buildWarbandTab(),
                ],
              ),
            ),
          ],
    );
  }

  // ---------------------------------------------------------------------------
  // TRADE TAB
  // ---------------------------------------------------------------------------
  Widget _buildTradeTab() {
    final game = GameManager.shared;
    final prices = TradeEngine.getPrices(widget.city, widget.player);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Gold & cargo bar
        _infoBar([
          _infoPill(Icons.monetization_on, '${widget.player.gold}g',
              Colors.amber),
          _infoPill(
              Icons.inventory_2,
              '${widget.player.currentCargoCount}/${widget.player.totalCargoCapacity}',
              Colors.blue),
        ]),
        const SizedBox(height: 10),
        // Equipment section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Equipment',
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Pack Mules: ${widget.player.packMules}  |  Trade Wagons: ${widget.player.tradeWagons}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      'Pack Mule  50g  (+15)',
                      Colors.blue,
                      widget.player.gold >= 50
                          ? () {
                              if (game.buyPackMule()) {
                                widget.showToast('Bought a pack mule!');
                                setState(() {});
                              }
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _actionButton(
                      'Trade Wagon  200g  (+30)',
                      Colors.blue,
                      widget.player.gold >= 200
                          ? () {
                              if (game.buyTradeWagon()) {
                                widget.showToast('Bought a trade wagon!');
                                setState(() {});
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Trade Goods',
          style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        // Trade goods
        ...prices.map((price) {
          final good = price.good;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _cardAltColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(good.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        good.displayName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Owned: ${price.playerOwned}  |  ${_trendLabel(price.trend)}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                _actionButton(
                  'Buy ${price.buyPrice}g',
                  Colors.green,
                  () {
                    if (TradeEngine.buy(
                        good, 1, widget.player, widget.city)) {
                      widget.showToast('Bought 1 ${good.displayName}');
                      setState(() {});
                    } else {
                      widget.showToast('Not enough gold or cargo space');
                    }
                  },
                ),
                const SizedBox(width: 6),
                _actionButton(
                  'Sell ${price.sellPrice}g',
                  Colors.orange,
                  price.playerOwned > 0
                      ? () {
                          final earned = TradeEngine.sell(
                              good, 1, widget.player, widget.city);
                          if (earned > 0) {
                            widget.showToast('Sold for ${earned}g');
                            setState(() {});
                          }
                        }
                      : null,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _trendLabel(PriceTrend trend) {
    return switch (trend) {
      PriceTrend.veryCheap => 'Very Cheap',
      PriceTrend.cheap => 'Cheap',
      PriceTrend.normal => 'Normal',
      PriceTrend.expensive => 'Expensive',
      PriceTrend.veryExpensive => 'Very Expensive',
    };
  }

  // ---------------------------------------------------------------------------
  // RECRUIT TAB
  // ---------------------------------------------------------------------------
  Widget _buildRecruitTab() {
    final game = GameManager.shared;
    final warband = game.playerWarband;
    final warbandSize = warband?.unitCount ?? 0;
    final maxSize = widget.player.maxWarbandSize;
    final recruitEngine = RecruitmentEngine();
    final available = recruitEngine.getAvailableUnits(widget.city);

    return Column(
      children: [
        // Summary bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: _cardColor,
          child: Row(
            children: [
              const Icon(Icons.groups, color: Colors.white54, size: 18),
              const SizedBox(width: 8),
              Text(
                'Warband: $warbandSize / $maxSize',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${widget.player.gold}g available',
                style: const TextStyle(color: Colors.amber, fontSize: 12),
              ),
            ],
          ),
        ),
        // Unit list
        Expanded(
          child: available.isEmpty
              ? const Center(
                  child: Text(
                    'No military buildings in this city',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: available.length,
                  itemBuilder: (context, index) {
                    final unitType = available[index];
                    final stats = unitType.stats;
                    final goldCost = stats.cost[Resource.gold] ?? 0;
                    final canAfford = widget.player.gold >= goldCost;
                    final canFit = warbandSize < maxSize;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _cardAltColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(unitType.emoji,
                              style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  unitType.displayName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${unitType.category}  |  ATK ${stats.attack}  DEF ${stats.defense}  HP ${stats.hp}',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          _actionButton(
                            'Hire ${goldCost}g',
                            Colors.cyan,
                            canAfford && canFit
                                ? () {
                                    if (game.recruitToWarband(
                                        unitType, widget.city)) {
                                      widget.showToast(
                                          'Hired ${unitType.displayName}');
                                      setState(() {});
                                    } else {
                                      widget.showToast('Cannot recruit');
                                    }
                                  }
                                : null,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAVERN TAB
  // ---------------------------------------------------------------------------
  Widget _buildTavernTab() {
    final game = GameManager.shared;
    final warband = game.playerWarband;
    final units = warband?.units ?? [];
    final woundedCount =
        units.where((u) => u.currentHP < u.maxHP).length;
    final healCost = woundedCount * 5;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Active missions
        if (widget.player.activeMissions.isNotEmpty) ...[
          ...widget.player.activeMissions.map(_buildMissionCard),
          const SizedBox(height: 12),
        ],
        // Rest section
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2A1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_hospital, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Rest & Heal',
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (woundedCount == 0)
                const Text(
                  'All soldiers are at full health.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                )
              else ...[
                Text(
                  '$woundedCount wounded soldier${woundedCount == 1 ? '' : 's'}  —  Cost: ${healCost}g (5g per unit)',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                _actionButton(
                  'Heal All  ${healCost}g',
                  Colors.green,
                  widget.player.gold >= healCost
                      ? () {
                          for (final unit in units) {
                            if (unit.currentHP < unit.maxHP) {
                              unit.currentHP = unit.maxHP;
                            }
                          }
                          widget.player.gold -= healCost;
                          widget.showToast(
                              'Healed $woundedCount soldier${woundedCount == 1 ? '' : 's'}');
                          setState(() {});
                        }
                      : null,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Rumors section
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: Colors.purple.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.hearing, color: Colors.purple, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Rumors',
                    style: TextStyle(
                        color: Colors.purple,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Nearby cities and trade routes:',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 8),
              ...game.travelDestinations.map((dest) {
                final destName = game.getVillageDisplayName(dest);
                final destOwner = game.getNationality(dest.owner);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      CountryballAvatar(
                        size: 22,
                        owner: dest.owner,
                        nationality: destOwner,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${dest.trait.emoji} ${dest.trait.displayName}'
                              '  |  Owner: ${destOwner?.name ?? 'Neutral'}'
                              '  |  Pop: ${dest.population}',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (game.travelDestinations.isEmpty)
                const Text(
                  'No connected cities found.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Player stats
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _cardAltColor,
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: Colors.amber.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Your Profile',
                    style: TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _statRow('Stage', widget.player.stageTitle),
              _statRow('Combat', '${widget.player.combatSkill}'),
              _statRow('Trade', '${widget.player.tradeSkill}'),
              _statRow('Scouting', '${widget.player.scoutingSkill}'),
              _statRow('Leadership', '${widget.player.leadershipSkill}'),
              _statRow('Tactics', '${widget.player.tacticsSkill}'),
              const Divider(color: Color(0xFF333333), height: 16),
              _statRow('Total Gold Earned',
                  '${widget.player.totalGoldEarned}g'),
              _statRow(
                  'Battles Won', '${widget.player.battlesWon}'),
              _statRow('Contracts Done',
                  '${widget.player.contractsCompleted}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMissionCard(Mission mission) {
    final game = GameManager.shared;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                mission.type == MissionType.story
                    ? Icons.auto_stories
                    : Icons.assignment,
                color: Colors.amber,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mission.title,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (mission.goldReward > 0)
                Text(
                  '${mission.goldReward}g',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mission.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          ...mission.objectives.map((obj) {
            String label = obj.description;
            if (obj.type == ObjectiveType.travelTo && obj.targetCityId != null) {
              final city = game.getVillageById(obj.targetCityId);
              if (city != null) {
                label = 'Travel to ${game.getVillageDisplayName(city)}';
              }
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    obj.completed
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: obj.completed ? Colors.green : Colors.white38,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: obj.completed ? Colors.green : Colors.white70,
                        fontSize: 12,
                        decoration: obj.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WARBAND TAB
  // ---------------------------------------------------------------------------
  Widget _buildWarbandTab() {
    final game = GameManager.shared;
    final warband = game.playerWarband;
    final units = warband?.units ?? [];

    return Column(
      children: [
        // Summary bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: _cardColor,
          child: Row(
            children: [
              CountryballAvatar.player(size: 22),
              const SizedBox(width: 8),
              Text(
                'Warband  (${units.length}/${widget.player.maxWarbandSize})',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (warband != null)
                Text(
                  'STR ${warband.strength}',
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
        // Unit list
        Expanded(
          child: units.isEmpty
              ? const Center(
                  child: Text(
                    'No soldiers in your warband',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: units.length,
                  itemBuilder: (context, index) {
                    final unit = units[index];
                    final hpRatio = unit.currentHP / unit.maxHP;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _cardAltColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(unit.unitType.emoji,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${unit.name}  Lv.${unit.level}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: hpRatio,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.1),
                                    valueColor:
                                        AlwaysStoppedAnimation(
                                      hpRatio > 0.5
                                          ? Colors.green
                                          : hpRatio > 0.25
                                              ? Colors.orange
                                              : Colors.red,
                                    ),
                                    minHeight: 5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'HP ${unit.currentHP}/${unit.maxHP}',
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'ATK ${unit.attack}',
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'DEF ${unit.defense}',
                                style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED WIDGETS
  // ---------------------------------------------------------------------------

  Widget _actionButton(String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: onTap != null
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap != null
                ? color.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: onTap != null ? color : Colors.white30,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _infoBar(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: children,
      ),
    );
  }

  Widget _infoPill(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
