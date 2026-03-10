import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/player_character.dart';
import '../../data/models/village.dart';
import '../../engines/game_manager.dart';
import '../../providers/game_provider.dart';
import '../map/map_view.dart';
import '../panels/cargo_panel.dart';
import '../panels/travel_panel.dart';
import 'city_screen.dart';
import '../panels/warband_panel.dart';
import '../components/rts_hud.dart';
import '../components/game_over_overlay.dart';
import 'battle/countryball_battle_screen.dart';

class RtsGameView extends StatefulWidget {
  const RtsGameView({super.key});

  @override
  State<RtsGameView> createState() => _RtsGameViewState();
}

class _RtsGameViewState extends State<RtsGameView> {
  String? _toastMessage;
  bool _showTravelPicker = false;
  bool _showWarband = false;
  bool _showCargo = false;
  bool _showCityPanel = true; // auto-open city panel on arrival

  @override
  void initState() {
    super.initState();
  }

  void _showToast(String message) {
    setState(() => _toastMessage = message);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  void _onVillageTapped(Village village) {
    final game = GameManager.shared;
    final pc = game.playerCharacter;
    if (pc == null) return;

    if (pc.state == PlayerState.atCity && pc.currentCityId != null) {
      if (village.id == pc.currentCityId) {
        // Tapped current city — toggle city panel
        setState(() => _showCityPanel = !_showCityPanel);
      } else if (game.areNeighbors(pc.currentCityId!, village.id)) {
        // Tapped connected city — start travel
        game.startTravel(village.id);
        setState(() {
          _showTravelPicker = false;
          _showCityPanel = false;
        });
      } else {
        _showToast('Not connected to ${game.getVillageDisplayName(village)}');
      }
    }
  }

  void _openTravelPicker() {
    setState(() {
      _showTravelPicker = !_showTravelPicker;
      if (_showTravelPicker) _showCityPanel = false;
    });
  }

  void _showMenuDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Menu', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Return to Menu', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(ctx).pop();
                final game = GameManager.shared;
                game.resetGame();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Track previous state to auto-open city panel on arrival
  PlayerState? _prevState;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final game = provider.gameManager;
        final pc = game.playerCharacter;

        if (pc == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Consume pending notifications from game engine
        if (game.pendingNotifications.isNotEmpty) {
          final notifications = List<String>.from(game.pendingNotifications);
          game.pendingNotifications.clear();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            for (final msg in notifications) {
              _showToast(msg);
            }
          });
        }

        // Auto-open city panel when arriving at a city
        if (_prevState == PlayerState.traveling && pc.state == PlayerState.atCity) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _showCityPanel = true);
          });
        }
        _prevState = pc.state;

        final isAtCity = pc.state == PlayerState.atCity && game.playerCurrentCity != null;
        final isTraveling = pc.state == PlayerState.traveling;
        final screenHeight = MediaQuery.of(context).size.height;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Map — always full screen
              Positioned.fill(
                child: _buildMap(game, pc),
              ),

              // Bottom panel: city or travel
              if (isAtCity && _showCityPanel)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: screenHeight * 0.55,
                  child: _buildCityBottomPanel(game, pc),
                ),

              if (isTraveling)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: screenHeight * 0.40),
                        child: TravelPanel(
                          player: pc,
                          encounter: game.currentEncounter,
                          onDismissEncounter: () => game.dismissEncounter(),
                          showToast: _showToast,
                        ),
                      ),
                    ],
                  ),
                ),

              // City action bar (when city panel is hidden)
              if (isAtCity && !_showCityPanel)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                  child: _buildCityActionBar(game),
                ),

              // HUD overlay — always on top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: RtsHud(
                  onWarbandTap: () => setState(() { _showWarband = !_showWarband; _showCargo = false; }),
                  onCargoTap: () => setState(() { _showCargo = !_showCargo; _showWarband = false; }),
                  onMenuTap: () => _showMenuDialog(),
                ),
              ),

              // Travel picker overlay
              if (_showTravelPicker)
                _buildCityTravelPicker(game),

              // Warband panel overlay
              if (_showWarband)
                Positioned(
                  top: 60,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: WarbandPanel(
                      onClose: () => setState(() => _showWarband = false),
                    ),
                  ),
                ),

              // Cargo panel overlay
              if (_showCargo)
                Positioned(
                  top: 60,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: CargoPanel(
                      player: pc,
                      onClose: () => setState(() => _showCargo = false),
                    ),
                  ),
                ),

              // Toast
              if (_toastMessage != null) _buildToast(),

              // Battle screen overlay
              if (game.pendingBattles.any((b) =>
                  b.attackerOwnerId == 'player' || b.defenderOwnerId == 'player'))
                CountryballBattleScreen(
                  key: ValueKey(game.pendingBattles
                      .firstWhere((b) =>
                          b.attackerOwnerId == 'player' || b.defenderOwnerId == 'player')
                      .id),
                  record: game.pendingBattles.firstWhere((b) =>
                      b.attackerOwnerId == 'player' || b.defenderOwnerId == 'player'),
                  onDismiss: () => setState(() {}),
                ),

              // Game over overlay
              if (game.isGameOver)
                const Positioned.fill(
                  child: GameOverOverlay(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap(GameManager game, PlayerCharacter pc) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2A1A), Color(0xFF0D1A0D), Color(0xFF152015)],
        ),
      ),
      child: MapView(
        selectedVillage: game.playerCurrentCity,
        onVillageSelected: _onVillageTapped,
        onArmySelected: (_) {},
      ),
    );
  }

  /// Compact bottom panel for city — shows header + tabs over the map
  Widget _buildCityBottomPanel(GameManager game, PlayerCharacter pc) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // City screen content fills the rest
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CityScreen(
                city: game.playerCurrentCity!,
                player: pc,
                onLeave: _openTravelPicker,
                showToast: _showToast,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Floating action bar when city panel is collapsed — quick access buttons
  Widget _buildCityActionBar(GameManager game) {
    final cityName = game.getVillageDisplayName(game.playerCurrentCity!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showCityPanel = true),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_city, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Text(
                  cityName,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_up, color: Colors.white38, size: 18),
              ],
            ),
          ),
          const Spacer(),
          _actionChip('Trade', Icons.store, () {
            setState(() => _showCityPanel = true);
          }),
          const SizedBox(width: 6),
          _actionChip('Leave', Icons.directions_walk, _openTravelPicker),
        ],
      ),
    );
  }

  Widget _actionChip(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCityTravelPicker(GameManager game) {
    final destinations = game.travelDestinations;
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.15,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 350),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.map, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Travel to...',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _showTravelPicker = false),
                      child: const Icon(Icons.close, color: Colors.white38, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFF333333)),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: destinations.length,
                  itemBuilder: (context, index) {
                    final dest = destinations[index];
                    final name = game.getVillageDisplayName(dest);
                    final owner = dest.owner == 'neutral'
                        ? 'Neutral'
                        : game.getNationality(dest.owner)?.name ?? dest.owner;
                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text('$owner | ${dest.trait.name}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white24),
                      onTap: () {
                        game.startTravel(dest.id);
                        setState(() {
                          _showTravelPicker = false;
                          _showCityPanel = false;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToast() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 50,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: _toastMessage != null ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _toastMessage ?? '',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
