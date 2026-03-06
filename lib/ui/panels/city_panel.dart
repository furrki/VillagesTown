import 'package:flutter/material.dart';
import '../../data/models/player_character.dart';
import '../../data/models/resource.dart';
import '../../data/models/village.dart';
import '../../engines/game_manager.dart';
import '../../engines/recruitment_engine.dart';
import '../../engines/trade_engine.dart';
import '../components/countryball_avatar.dart';

class CityPanel extends StatefulWidget {
  final Village city;
  final PlayerCharacter player;
  final VoidCallback onTravel;
  final void Function(String message) showToast;

  const CityPanel({
    super.key,
    required this.city,
    required this.player,
    required this.onTravel,
    required this.showToast,
  });

  @override
  State<CityPanel> createState() => _CityPanelState();
}

class _CityPanelState extends State<CityPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // City header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF1A1A1A),
          child: Row(
            children: [
              CountryballAvatar.player(size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cityName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${widget.city.trait.displayName} | Pop: ${widget.city.population}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: widget.onTravel,
                icon: const Icon(Icons.directions_walk, size: 16),
                label: const Text('Travel'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue.withValues(alpha: 0.3),
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        // Tabs
        TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Trade'),
            Tab(text: 'Recruit'),
          ],
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTradeTab(),
              _buildRecruitTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTradeTab() {
    final game = GameManager.shared;
    final prices = TradeEngine.getPrices(widget.city, widget.player);

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // Equipment section
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Equipment',
                style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Mules: ${widget.player.packMules} | Wagons: ${widget.player.tradeWagons}',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _tradeButton(
                    'Pack Mule 50g (+15)',
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
                  const SizedBox(width: 8),
                  _tradeButton(
                    'Trade Wagon 200g (+30)',
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
                ],
              ),
            ],
          ),
        ),
        // Trade goods
        ...prices.map((price) {
          final good = price.good;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(good.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        good.displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Own: ${price.playerOwned} | ${price.trend.name}',
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                _tradeButton(
                  'Buy ${price.buyPrice}g',
                  Colors.green,
                  () {
                    if (TradeEngine.buy(good, 1, widget.player, widget.city)) {
                      widget.showToast('Bought 1 ${good.displayName}');
                      setState(() {});
                    } else {
                      widget.showToast('Not enough gold or cargo space');
                    }
                  },
                ),
                const SizedBox(width: 6),
                _tradeButton(
                  'Sell ${price.sellPrice}g',
                  Colors.orange,
                  price.playerOwned > 0
                      ? () {
                          final earned = TradeEngine.sell(good, 1, widget.player, widget.city);
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

  Widget _tradeButton(String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: onTap != null ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: onTap != null ? color.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: onTap != null ? color : Colors.white30,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRecruitTab() {
    final game = GameManager.shared;
    final warband = game.playerWarband;
    final warbandSize = warband?.unitCount ?? 0;
    final maxSize = widget.player.maxWarbandSize;
    final recruitEngine = RecruitmentEngine();
    final available = recruitEngine.getAvailableUnits(widget.city);

    return Column(
      children: [
        // Warband summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF1A1A1A),
          child: Row(
            children: [
              const Icon(Icons.groups, color: Colors.white54, size: 16),
              const SizedBox(width: 8),
              Text(
                'Warband: $warbandSize / $maxSize',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${widget.player.gold}g available',
                style: const TextStyle(color: Colors.amber, fontSize: 11),
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
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: available.length,
                  itemBuilder: (context, index) {
                    final unitType = available[index];
                    final stats = unitType.stats;
                    final goldCost = stats.cost[Resource.gold] ?? 0;
                    final canAfford = widget.player.gold >= goldCost;
                    final canFit = warbandSize < maxSize;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(unitType.emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  unitType.displayName,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${unitType.category} | ATK ${stats.attack} DEF ${stats.defense}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          _tradeButton(
                            'Hire ${goldCost}g',
                            Colors.cyan,
                            canAfford && canFit
                                ? () {
                                    if (game.recruitToWarband(unitType, widget.city)) {
                                      widget.showToast('Hired ${unitType.displayName}');
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
}
